/* M207: one complete index validation, stratified sample plans. */
/* Read only validated PIDX1, never open STGIN or seek stage bytes. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <limits.h>

#define MAXOBJ 100000UL
#define MAXSIZE (16UL*1024UL*1024UL)
#define MAXREC 2147483647UL

struct item {
 unsigned char oid[20];
 unsigned long size,rec,bodylines;
 long offset;
 int type,used;
};

static struct item *bynum;
static unsigned long total,unique;

static int nib(int c) {
 if(c>='0'&&c<='9') return c-'0';
 if(c>='A'&&c<='F') return c-'A'+10;
 if(c>='a'&&c<='f') return c-'a'+10;
 return -1;
}

static int oidparse(const char *s,unsigned char out[20]) {
 int i,h,l;
 if(strlen(s)!=40) return 0;
 for(i=0;i<20;i++) {
  h=nib((unsigned char)s[i*2]);
  l=nib((unsigned char)s[i*2+1]);
  if(h<0||l<0) return 0;
  out[i]=(unsigned char)((h<<4)|l);
 }
 return 1;
}

static void oidprint(const unsigned char p[20]) {
 static const char digits[]="0123456789ABCDEF";
 int i;
 for(i=0;i<20;i++) {
  putchar(digits[p[i]>>4]);
  putchar(digits[p[i]&15]);
 }
}

static int numeric(const char *p,unsigned long *v) {
 char *end;
 if(!p||!*p||*p<'0'||*p>'9') return 0;
 errno=0;
 *v=strtoul(p,&end,10);
 return !errno&&!*end;
}

static int linein(FILE *f,char buf[128]) {
 int n;
 if(!fgets(buf,128,f)) return 0;
 n=(int)strlen(buf);
 if(n==127&&buf[n-1]!='\n') return 0;
 while(n&&(buf[n-1]=='\n'||buf[n-1]=='\r'||
           buf[n-1]==' ')) buf[--n]=0;
 return n<=80;
}

static int indexread(void) {
 FILE *f;
 char line[128],txt[41],extra;
 unsigned char oid[20],previous[20];
 unsigned long n,i,size,et,eu;
 int type,fields,ok=0;
 long offset;
 f=fopen("dd:IDXIN","r");
 if(!f) return 0;
 if(!linein(f,line)) goto done;
 fields=sscanf(line,"PIDX1 %lu %lu %c",&total,&unique,&extra);
 if(fields!=2||total==0||total>MAXOBJ||
    unique!=total) goto done;
 bynum=(struct item *)calloc((size_t)(total+1),
                              sizeof *bynum);
 if(!bynum) goto done;
 for(i=0;i<unique;i++) {
  if(!linein(f,line)) goto done;
  fields=sscanf(line,"OID %40s %lu %d %lu %ld %c",
                txt,&n,&type,&size,&offset,&extra);
  if(fields!=5||n==0||n>total||type<1||type>4||
     size>MAXSIZE||offset<0||!oidparse(txt,oid))
   goto done;
  if(i&&memcmp(previous,oid,20)>=0) goto done;
  memcpy(previous,oid,20);
  if(bynum[n].used) goto done;
  bynum[n].used=1;
  bynum[n].type=type;
  bynum[n].size=size;
  bynum[n].offset=offset;
  memcpy(bynum[n].oid,oid,20);
 }
 if(!linein(f,line)) goto done;
 fields=sscanf(line,"PEND1 %lu %lu %c",&et,&eu,&extra);
 if(fields!=2||et!=total||eu!=unique) goto done;
 if(linein(f,line)||!feof(f)||ferror(f)) goto done;
 ok=1;
done:
 if(fclose(f)!=0) ok=0;
 if(!ok) puts("M207 INDEX INVALID");
 return ok;
}

/* Select one bounded nonempty object from each disjoint ordinal band.
 * All bands and entire record geometry are checked before any P201 output.
 */
static int sample(unsigned long expected,unsigned long limit,
                  int count) {
 unsigned long n,rec=1,body,start,end,picked[128];
 long prior=-1;
 struct item *e;
 int k;
 for(n=1;n<=total;n++) {
  e=bynum+n;
  if(!e->used||e->offset<=prior) {
   puts("M207 INDEX NUMBER OR OFFSET INVALID");
   return 0;
  }
  prior=e->offset;
  body=e->size?(e->size+31UL)/32UL:1UL;
  if(body>MAXREC-1UL||rec>MAXREC-1UL-body) {
   puts("M207 EXTENDED RECORD LIMIT");
   return 0;
  }
  e->rec=rec;
  e->bodylines=body;
  rec+=1UL+body;
 }
 if(rec-1UL!=expected) {
  puts("M207 STAGE RECORD COUNT MISMATCH");
  return 0;
 }
 for(k=0;k<count;k++) {
  start=((unsigned long)k*total)/(unsigned long)count+1UL;
  end=((unsigned long)(k+1)*total)/(unsigned long)count;
  picked[k]=0;
  for(n=start;n<=end;n++) {
   e=bynum+n;
   if(e->size==0UL||e->size>2048UL||
      e->bodylines==0UL||e->bodylines>limit) continue;
   picked[k]=n;
   break;
  }
  if(!picked[k]) {
   puts("M207 NO ELIGIBLE OBJECT IN BAND");
   return 0;
  }
 }
 for(k=0;k<count;k++) {
  n=picked[k];
  e=bynum+n;
  printf("P201 %lu %lu %lu %d %lu ",
         n,e->rec,e->bodylines,e->type,e->size);
  oidprint(e->oid);
  putchar('\n');
 }
 return 1;
}

int main(int argc,char **argv) {
 unsigned long expected,limit,num;
 int rc=8;
 if(argc!=5||strcmp(argv[1],"SAMPLE")!=0||
    !numeric(argv[2],&expected)||
    !numeric(argv[3],&limit)||
    !numeric(argv[4],&num)||
    expected==0||expected>MAXREC||
    limit==0||limit>64UL||
    num<2UL||num>128UL) {
  puts("Usage: GITP27M SAMPLE records max-body 2..128");
  return 4;
 }
 if(!indexread()) goto done;
 if(sample(expected,limit,(int)num)) rc=0;
done:
 free(bynum);
 return rc;
}
