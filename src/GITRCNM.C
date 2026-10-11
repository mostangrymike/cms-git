/* M192: calculate CMS stage physical record numbers from read-only IDX. */
/* No STGIN open, fseek, stage scan, write or native assembler adapter. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>
#include <errno.h>

#define OBJMAX 100000UL
#define OBJMAXSZ (16UL*1024UL*1024UL)

struct ent {
 unsigned long size,record;
 long offset;
 int used;
};
static struct ent *bynum;
static unsigned long total,unique;

static int nib(int c) {
 if(c>='0'&&c<='9') return c-'0';
 if(c>='A'&&c<='F') return c-'A'+10;
 if(c>='a'&&c<='f') return c-'a'+10;
 return -1;
}

static int decode(const char *s,unsigned char out[20]) {
 int i,a,b;
 if(strlen(s)!=40) return 0;
 for(i=0;i<20;i++) {
  a=nib((unsigned char)s[2*i]);
  b=nib((unsigned char)s[2*i+1]);
  if(a<0||b<0) return 0;
  out[i]=(unsigned char)((a<<4)|b);
 }
 return 1;
}

static int linein(FILE *f,char buf[128]) {
 int n;
 if(!fgets(buf,128,f)) return 0;
 n=(int)strlen(buf);
 if(n==127&&buf[n-1]!='\n') return 0;
 while(n&& (buf[n-1]=='\n'||buf[n-1]=='\r'||
            buf[n-1]==' ')) buf[--n]=0;
 return n<=80;
}

static int indexread(void) {
 FILE *f=0;
 char line[128],oidtext[41],extra;
 unsigned char oid[20],prior[20];
 unsigned long i,num,size,lasttotal,lastunique;
 long offset;
 int type,fields,ok=0;
 f=fopen("dd:IDXIN","r");
 if(!f) return 0;
 if(!linein(f,line)) goto done;
 fields=sscanf(line,"PIDX1 %lu %lu %c",
               &total,&unique,&extra);
 if(fields!=2||total<1||total>OBJMAX||
    unique!=total) goto done;
 bynum=(struct ent *)calloc((size_t)(total+1),
                             sizeof *bynum);
 if(!bynum) goto done;
 for(i=0;i<unique;i++) {
  if(!linein(f,line)) goto done;
  fields=sscanf(line,"OID %40s %lu %d %lu %ld %c",
                oidtext,&num,&type,&size,&offset,&extra);
  if(fields!=5||num<1||num>total||
     type<1||type>4||size>OBJMAXSZ||
     offset<0||!decode(oidtext,oid)) goto done;
  if(i&&memcmp(prior,oid,20)>=0) goto done;
  memcpy(prior,oid,20);
  if(bynum[num].used) goto done;
  bynum[num].used=1;
  bynum[num].size=size;
  bynum[num].offset=offset;
 }
 if(!linein(f,line)) goto done;
 fields=sscanf(line,"PEND1 %lu %lu %c",
               &lasttotal,&lastunique,&extra);
 if(fields!=2||lasttotal!=total||
    lastunique!=unique) goto done;
 if(linein(f,line)||!feof(f)||ferror(f)) goto done;
 ok=1;
done:
 if(fclose(f)!=0) ok=0;
 if(!ok) puts("M192 INDEX INVALID");
 return ok;
}

static int model(unsigned long expected) {
 unsigned long n,rec=1,bodylines,mid=(total+1)/2;
 for(n=1;n<=total;n++) {
  if(!bynum[n].used) return 0;
  bynum[n].record=rec;
  bodylines=bynum[n].size?
       (bynum[n].size+31UL)/32UL:1UL;
  if(rec>ULONG_MAX-1UL-bodylines) return 0;
  rec+=1+bodylines;
 }
 printf("M192 INDEX TOTAL %lu UNIQUE %lu\n",total,unique);
 printf("M192 RECORD 1 RECNO %lu OFFSET %ld\n",
        bynum[1].record,bynum[1].offset);
 printf("M192 RECORD %lu RECNO %lu OFFSET %ld\n",
        mid,bynum[mid].record,bynum[mid].offset);
 printf("M192 RECORD %lu RECNO %lu OFFSET %ld\n",
        total,bynum[total].record,bynum[total].offset);
 printf("M192 STAGE MODEL RECORDS %lu EXPECTED %lu\n",
        rec-1UL,expected);
 if(rec-1UL!=expected) {
  puts("M192 RECORD MODEL MISMATCH");
  return 0;
 }
 puts("M192 READ ONLY RECORD PLAN PASS");
 return 1;
}

int main(int argc,char **argv) {
 char *end;
 unsigned long wanted;
 int rc=8;
 if(argc!=3||strcmp(argv[1],"PLAN")!=0) {
  puts("Usage: GITRCNM PLAN expected-stage-records");
  return 4;
 }
 errno=0;
 wanted=strtoul(argv[2],&end,10);
 if(errno||*end||wanted==0) return 4;
 if(!indexread()) goto done;
 if(model(wanted)) rc=0;
done:
 free(bynum);
 return rc;
}
