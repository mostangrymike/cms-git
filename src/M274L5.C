/* M268: materialize one verified staged Git object as a CMS loose object. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

/* GCCCMS/PDPCLIB returns errno 1 for an absent CMS file ID. */
#ifndef ENOENT
#define ENOENT 1
#endif

/* Match the current REXX loose-object and workfile import bound. */
#define OBJMAXSZ 1048576UL
#define OBJMAX 100000UL
#define W32 0xffffffffUL
#define CMSREC 80
#define CMSMAXREC 32776

extern int gitpfs(unsigned long *);

static unsigned char batch_body[OBJMAXSZ];
static unsigned char cms_records[CMSMAXREC][CMSREC];
static unsigned char cms_fileid[24];
static unsigned long cms_api[4];
static unsigned long sh[5];

#ifndef GITPLOAD_HOST
static void cms_id(const char *oid,char fm) {
 memset(cms_fileid,' ',sizeof cms_fileid);
 memcpy(cms_fileid,oid,8);
 memcpy(cms_fileid+8,"GITOBJ",6);
 cms_fileid[16]=(unsigned char)fm;
 cms_fileid[17]='1';
}

static unsigned long cms_state(const char *oid,char fm) {
 cms_id(oid,fm);
 cms_api[0]=0;
 cms_api[1]=(unsigned long)cms_fileid;
 cms_api[2]=0;
 cms_api[3]=0;
 return (unsigned long)gitpfs(cms_api);
}

static unsigned int decimal(unsigned long n,unsigned char *out) {
 unsigned char rev[16];
 unsigned int i=0,j;
 do { rev[i++]=(unsigned char)('0'+n%10);n/=10; } while(n);
 for(j=0;j<i;j++) out[j]=rev[i-j-1];
 return i;
}

static unsigned long cms_make_records(const char *oid,int type,
                                      unsigned long size,
                                      const unsigned char *body) {
 static const unsigned char hex[]="0123456789ABCDEF";
 const char *typename=type==1?"COMMIT":type==2?"TREE":
                      type==3?"BLOB":"TAG";
 unsigned long k,nrec=3,at;
 unsigned int n,m;
 memset(cms_records,' ',sizeof cms_records);
 memcpy(cms_records[0],"OID ",4);
 memcpy(cms_records[0]+4,oid,40);
 memcpy(cms_records[1],"TYPE ",5);
 memcpy(cms_records[1]+5,typename,strlen(typename));
 memcpy(cms_records[2],"SIZE ",5);
 n=decimal(size,cms_records[2]+5);
 for(k=0;k<size;k+=32) {
  nrec++;
  at=k;
  n=(unsigned int)(size-k);
  if(n>32) n=32;
  memcpy(cms_records[nrec-1],"DATA ",5);
  for(m=0;m<n;m++) {
   cms_records[nrec-1][5+m*2]=hex[body[at+m]>>4];
   cms_records[nrec-1][6+m*2]=hex[body[at+m]&15];
  }
 }
 return nrec;
}

static int cms_write(const char *oid,char fm,int type,unsigned long size,
                     const unsigned char *body) {
 unsigned long nrec=cms_make_records(oid,type,size,body);
 cms_id(oid,fm);
 cms_api[0]=1;
 cms_api[1]=(unsigned long)cms_fileid;
 cms_api[2]=(unsigned long)cms_records;
 cms_api[3]=nrec;
 return gitpfs(cms_api);
}
#endif

static int nib(int c) {
 if(c>='0'&&c<='9') return c-'0';
 if(c>='A'&&c<='F') return c-'A'+10;
 if(c>='a'&&c<='f') return c-'a'+10;
 return -1;
}

static int linein(FILE *f,char *line,int cap) {
 int n;
 if(!fgets(line,cap,f)) return 0;
 n=(int)strlen(line);
 if(n==cap-1&&line[n-1]!='\n') return 0;
 while(n>0&&(line[n-1]=='\n'||line[n-1]=='\r'||
             line[n-1]==' ')) line[--n]=0;
 return 1;
}

static int hexoid(const char *s,unsigned char oid[20]) {
 int i,hi,lo;
 if(strlen(s)!=40) return 0;
 for(i=0;i<20;i++) {
  hi=nib((unsigned char)s[i*2]);
  lo=nib((unsigned char)s[i*2+1]);
  if(hi<0||lo<0) return 0;
  oid[i]=(unsigned char)((hi<<4)|lo);
 }
 return 1;
}

static unsigned long rol(unsigned long x,unsigned int n) {
 x&=W32;
 return ((x<<n)|(x>>(32-n)))&W32;
}

static unsigned long sxor(unsigned long a,unsigned long b) {
 return ((a|b)&(~(a&b)))&W32;
}

static void block(const unsigned char *p) {
 unsigned long w[80],a,b,c,d,e,t,fun,k;
 unsigned int i;
 for(i=0;i<16;i++)
  w[i]=((unsigned long)p[i*4]<<24)|
       ((unsigned long)p[i*4+1]<<16)|
       ((unsigned long)p[i*4+2]<<8)|(unsigned long)p[i*4+3];
 for(i=16;i<80;i++)
  w[i]=rol(sxor(sxor(w[i-3],w[i-8]),sxor(w[i-14],w[i-16])),1);
 a=sh[0];b=sh[1];c=sh[2];d=sh[3];e=sh[4];
 for(i=0;i<80;i++) {
  if(i<20) { fun=(b&c)|((~b)&d);k=0x5a827999UL; }
  else if(i<40) { fun=sxor(sxor(b,c),d);k=0x6ed9eba1UL; }
  else if(i<60) { fun=(b&c)|(b&d)|(c&d);k=0x8f1bbcdcUL; }
  else { fun=sxor(sxor(b,c),d);k=0xca62c1d6UL; }
  t=(rol(a,5)+fun+e+k+w[i])&W32;
  e=d;d=c;c=rol(b,30);b=a;a=t;
 }
 sh[0]=(sh[0]+a)&W32;sh[1]=(sh[1]+b)&W32;
 sh[2]=(sh[2]+c)&W32;sh[3]=(sh[3]+d)&W32;
 sh[4]=(sh[4]+e)&W32;
}

static void parts(const unsigned char *head,unsigned long hlen,
                  const unsigned char *body,unsigned long blen,
                  unsigned char digest[20]) {
 unsigned char b[64],tail[128];
 unsigned long total=hlen+blen,done=0,at,rem,bits;
 unsigned int i,j;
 sh[0]=0x67452301UL;sh[1]=0xefcdab89UL;
 sh[2]=0x98badcfeUL;sh[3]=0x10325476UL;
 sh[4]=0xc3d2e1f0UL;
 while(total-done>=64) {
  for(i=0;i<64;i++) {
   at=done+(unsigned long)i;
   b[i]=at<hlen?head[at]:body[at-hlen];
  }
  block(b);done+=64;
 }
 rem=total-done;memset(tail,0,sizeof tail);
 for(i=0;i<rem;i++) {
  at=done+(unsigned long)i;
  tail[i]=at<hlen?head[at]:body[at-hlen];
 }
 tail[rem]=0x80;bits=total*8;
 for(i=0;i<8;i++)
  tail[(rem<56?56:120)+i]=
   (unsigned char)(i<4?0:(bits>>(8*(7-i))));
 block(tail);if(rem>=56) block(tail+64);
 for(i=0;i<5;i++) for(j=0;j<4;j++)
  digest[i*4+j]=(unsigned char)(sh[i]>>(24-j*8));
}

static const unsigned char types[5][7]={
 {0},{0x63,0x6f,0x6d,0x6d,0x69,0x74,0},
 {0x74,0x72,0x65,0x65,0,0,0},{0x62,0x6c,0x6f,0x62,0,0,0},
 {0x74,0x61,0x67,0,0,0,0}
};

static int object_oid(int type,const unsigned char *body,
                      unsigned long n,unsigned char oid[20]) {
 unsigned char head[32],digits[16];
 unsigned long rem=n;
 int i=0,j=0;
 if(type<1||type>4||n>OBJMAXSZ) return 0;
 while(types[type][i]) { head[i]=types[type][i];i++; }
 head[i++]=0x20;
 do { digits[j++]=(unsigned char)(0x30+rem%10);rem/=10; } while(rem);
 while(j) head[i++]=digits[--j];
 head[i++]=0;parts(head,(unsigned long)i,body,n,oid);return 1;
}

static int parse_header(const char *line,unsigned long *num,
                        int *type,unsigned long *size,
                        unsigned char oid[20]) {
 char text[41],extra;
 int fields=sscanf(line,"OBJ %lu %d %lu %40s %c",
                   num,type,size,text,&extra);
 return fields==4&&*num>=1&&*type>=1&&*type<=4&&
        *size<=OBJMAXSZ&&hexoid(text,oid);
}

static int readbody_into(FILE *f,unsigned long n,unsigned char *p) {
 static char line[8192];
 unsigned long k,m,take;
 int hi,lo;
 if(n>OBJMAXSZ) return 0;
 if(n==0) {
  if(!linein(f,line,sizeof line)||line[0]) return 0;
 }
 for(k=0;k<n;k+=take) {
  take=n-k;if(take>2000) take=2000;
  if(!linein(f,line,sizeof line)||strlen(line)!=take*2) return 0;
  for(m=0;m<take;m++) {
   hi=nib((unsigned char)line[m*2]);
   lo=nib((unsigned char)line[m*2+1]);
   if(hi<0||lo<0) return 0;
   p[k+m]=(unsigned char)((hi<<4)|lo);
  }
 }
 return 1;
}

static int readbody(FILE *f,unsigned long n,unsigned char **body) {
 unsigned char *p;
 p=(unsigned char *)malloc((size_t)(n?n:1));
 if(!p) return 0;
 if(!readbody_into(f,n,p)) { free(p);return 0; }
 *body=p;return 1;
}

static int texttype(const char *text) {
 if(strcmp(text,"COMMIT")==0) return 1;
 if(strcmp(text,"TREE")==0) return 2;
 if(strcmp(text,"BLOB")==0) return 3;
 if(strcmp(text,"TAG")==0) return 4;
 return 0;
}

static int read_loose_into(FILE *f,const char *want,int wanttype,
                           unsigned long wantsize,unsigned char *body) {
 unsigned char expected[20],got[20];
 char line[128],oid[41],typeword[8],extra;
 unsigned long size=0,k=0,m,take;
 int fields,type,hi,lo,ok=0;
 if(!linein(f,line,sizeof line)) goto done;
 fields=sscanf(line,"OID %40s %c",oid,&extra);
 if(fields!=1||strcmp(oid,want)!=0||
    !hexoid(oid,expected)) goto done;
 if(!linein(f,line,sizeof line)) goto done;
 fields=sscanf(line,"TYPE %7s %c",typeword,&extra);
 type=fields==1?texttype(typeword):0;
 if(type!=wanttype) goto done;
 if(!linein(f,line,sizeof line)) goto done;
 fields=sscanf(line,"SIZE %lu %c",&size,&extra);
 if(fields!=1||size!=wantsize||size>OBJMAXSZ) goto done;
 for(k=0;k<size;k+=take) {
  take=size-k;
  if(take>32) take=32;
  if(!linein(f,line,sizeof line)||strncmp(line,"DATA ",5)!=0||
     strlen(line)!=5+take*2) goto done;
  for(m=0;m<take;m++) {
   hi=nib((unsigned char)line[5+m*2]);
   lo=nib((unsigned char)line[6+m*2]);
   if(hi<0||lo<0) goto done;
   body[k+m]=(unsigned char)((hi<<4)|lo);
  }
 }
 if(fgetc(f)!=EOF||ferror(f)||
    !object_oid(type,body,size,got)||memcmp(expected,got,20)!=0)
  goto done;
 ok=1;
done:
 return ok;
}

static int read_loose(FILE *f,const char *want,int wanttype,
                      unsigned long wantsize) {
 unsigned char *body;
 int ok;
 body=(unsigned char *)malloc((size_t)(wantsize?wantsize:1));
 if(!body) return 0;
 ok=read_loose_into(f,want,wanttype,wantsize,body);
 free(body);
 return ok;
}

static int object_path(char *path,size_t cap,const char *oid,char fm) {
#ifdef GITPLOAD_HOST
 const char *dir=getenv("GITPLOAD_HOST_DIR");
 if(!dir||!*dir) dir=".";
 if(strlen(dir)+19>cap) return 0;
 sprintf(path,"%s/%.8s.GITOBJ.%c",dir,oid,fm);
#else
 if(cap<20) return 0;
 sprintf(path,"%.8s.GITOBJ.%c",oid,fm);
#endif
 return 1;
}

static int write_loose(FILE *out,const char *oid,int type,
                       unsigned long size,const unsigned char *body) {
 unsigned long k,m,take;
 const char *typename=type==1?"COMMIT":type==2?"TREE":
                      type==3?"BLOB":"TAG";
 static const char hex[]="0123456789ABCDEF";
 if(fprintf(out,"OID %s\nTYPE %s\nSIZE %lu\n",
            oid,typename,size)<0) return 0;
 for(k=0;k<size;k+=take) {
  take=size-k;
  if(take>32) take=32;
  if(fputs("DATA ",out)==EOF) return 0;
  for(m=0;m<take;m++) {
   if(fputc(hex[body[k+m]>>4],out)==EOF||
      fputc(hex[body[k+m]&15],out)==EOF) return 0;
  }
  if(fputc('\n',out)==EOF) return 0;
 }
 return 1;
}

static void oid_text(const unsigned char *oid,char *out) {
 static const char hex[]="0123456789ABCDEF";
 int i;
 for(i=0;i<20;i++) {
  out[i*2]=hex[oid[i]>>4];
  out[i*2+1]=hex[oid[i]&15];
 }
 out[40]=0;
}

/* Consume one stage body without decoding it. */
static int skip_stage_body(FILE *f,unsigned long n) {
 static char line[8192];
 unsigned long k,take;
 if(n==0)
  return linein(f,line,sizeof line)&&line[0]==0;
 for(k=0;k<n;k+=take) {
  take=n-k;
  if(take>2000) take=2000;
  if(!linein(f,line,sizeof line)||strlen(line)!=take*2) return 0;
 }
 return 1;
}

/* Install the index-selected objects by walking the stage once in object
   order.  CMS fseek into a text stage is O(offset), so the old per-object
   seek made a full activation take hours. */
static int load_batch(char fm,const char *expectedtext,
                      const char *limittext) {
 FILE *idx=0,*stage=0,*old=0,*out=0,*check=0;
 unsigned char *idxoid=0,oidbin[20],stored[20],got[20];
 unsigned long total,unique,limit,i,num,objnum,objsize,slot;
 unsigned long typeval,size,offset,processed=0;
 unsigned long installed=0,already=0,tags=0;
 unsigned long *bynum=0;
 char oid[41],extra,path[96];
 static char line[8192];
 int fields,stage_type;
#ifdef GITPLOAD_HOST
 int created;
#endif
 char *end;
 total=strtoul(expectedtext,&end,10);
 if(*end||total<1||total>OBJMAX) {
  puts("PACKOBJ BATCH COUNT INVALID");
  return 4;
 }
 limit=strtoul(limittext,&end,10);
 if(*end) { puts("PACKOBJ BATCH LIMIT INVALID");return 4; }
 idx=fopen("dd:IDXIN","r");
 if(!idx) { perror("IDXIN");return 8; }
 if(!linein(idx,line,sizeof line)) goto badindex;
 fields=sscanf(line,"PIDX1 %lu %lu %c",&num,&unique,&extra);
 if(fields!=2||num!=total||unique<1||unique>num||
    unique>OBJMAX) goto badindex;
 if(limit==0) limit=unique;
 if(limit>unique) goto badindex;
 idxoid=(unsigned char *)malloc((size_t)(limit*20));
 bynum=(unsigned long *)calloc((size_t)(total+1),sizeof *bynum);
 if(!idxoid||!bynum) goto badindex;
 for(i=1;i<=limit;i++) {
  if(!linein(idx,line,sizeof line)) goto badindex;
  fields=sscanf(line,"OID %40s %lu %lu %lu %lu %c",
                oid,&objnum,&typeval,&objsize,&offset,&extra);
  if(fields!=5||!hexoid(oid,oidbin)||objnum<1||objnum>total||
     typeval<1||typeval>4||objsize>OBJMAXSZ||
     offset>0x7fffffffUL) goto badindex;
  if(i>1&&memcmp(idxoid+(i-2)*20,oidbin,20)>=0) goto badindex;
  memcpy(idxoid+(i-1)*20,oidbin,20);
  bynum[objnum]=i;
 }
 if(limit==unique) {
  if(!linein(idx,line,sizeof line)) goto badindex;
  fields=sscanf(line,"PEND1 %lu %lu %c",&num,&typeval,&extra);
  if(fields!=2||num!=total||typeval!=unique||
     fgetc(idx)!=EOF||ferror(idx)) goto badindex;
 }
 if(fclose(idx)!=0) { idx=0;goto fail; }
 idx=0;
 stage=fopen("dd:STGIN","r");
 if(!stage) { perror("STGIN");goto fail; }
 while(1) {
  if(!linein(stage,line,sizeof line)) {
   if(feof(stage)) break;
   goto fail;
  }
  if(!parse_header(line,&num,&stage_type,&size,stored)) goto fail;
  if(num<1||num>total) goto fail;
  processed++;
  slot=bynum[num];
  if(!slot) {
   if(!skip_stage_body(stage,size)) goto fail;
   continue;
  }
  if(memcmp(idxoid+(slot-1)*20,stored,20)!=0) goto fail;
  if(stage_type==4) {
   if(!skip_stage_body(stage,size)) goto fail;
   tags++;
   continue;
  }
  oid_text(stored,oid);
  if(!object_path(path,sizeof path,oid,fm)) goto badindex;
#ifdef GITPLOAD_HOST
  errno=0;
  old=fopen(path,"r");
#else
  typeval=cms_state(oid,fm);
  if(typeval==0) old=fopen(path,"r");
  else if(typeval!=28) {
   printf("PACKOBJ BATCH OBJECT STATE FAILED %s RC %lu\n",oid,typeval);
   goto fail;
  }
#endif
  if(old) {
   if(!read_loose_into(old,oid,stage_type,size,batch_body)) {
    fclose(old);old=0;
    printf("PACKOBJ BATCH EXISTING OBJECT INVALID %s\n",oid);
    goto fail;
   }
   if(fclose(old)!=0) { old=0;goto fail; }
   old=0;
   if(!skip_stage_body(stage,size)) goto fail;
   already++;
   continue;
  }
#ifdef GITPLOAD_HOST
  if(errno!=ENOENT) {
   printf("PACKOBJ BATCH OBJECT PROBE FAILED %s ERRNO %d\n",
          oid,errno);
   goto fail;
  }
#endif
  if(!readbody_into(stage,size,batch_body)||
     !object_oid(stage_type,batch_body,size,got)||
     memcmp(stored,got,20)!=0) {
   printf("PACKOBJ BATCH STAGE OBJECT INVALID %s\n",oid);
   goto fail;
  }
#ifdef GITPLOAD_HOST
  created=1;
  out=fopen(path,"w");
  if(!out) {
   printf("PACKOBJ BATCH OBJECT CREATE FAILED %s ERRNO %d\n",
          oid,errno);
   goto fail;
  }
  if(!write_loose(out,oid,stage_type,size,batch_body)) {
   fclose(out);out=0;
   if(created) remove(path);
   printf("PACKOBJ BATCH OBJECT WRITE FAILED %s\n",oid);
   goto fail;
  }
  if(fclose(out)!=0) {
   out=0;
   if(created) remove(path);
   printf("PACKOBJ BATCH OBJECT CLOSE FAILED %s\n",oid);
   goto fail;
  }
  out=0;
#else
  if(cms_write(oid,fm,stage_type,size,batch_body)!=0) {
   printf("PACKOBJ BATCH OBJECT CMS WRITE FAILED %s\n",oid);
   goto fail;
  }
#endif
  check=fopen(path,"r");
  if(!check||!read_loose_into(check,oid,stage_type,size,batch_body)) {
   if(check) fclose(check);
   check=0;
#ifdef GITPLOAD_HOST
   if(created) remove(path);
#endif
   printf("PACKOBJ BATCH OBJECT READBACK FAILED %s\n",oid);
   goto fail;
  }
  if(fclose(check)!=0) {
   check=0;
#ifdef GITPLOAD_HOST
   if(created) remove(path);
#endif
   printf("PACKOBJ BATCH OBJECT READBACK CLOSE FAILED %s\n",oid);
   goto fail;
  }
  check=0;
  installed++;
  if(installed%1000==0)
   printf("PACKOBJ BATCH INSTALLED %lu\n",installed);
 }
 if(processed!=total) {
  puts("PACKOBJ BATCH STAGE COUNT INVALID");
  goto fail;
 }
 if(installed+already+tags!=limit) {
  puts("PACKOBJ BATCH INSTALL COUNT INVALID");
  goto fail;
 }
 if(fclose(stage)!=0) { stage=0;goto fail; }
 stage=0;
 free(idxoid);
 free(bynum);
 printf("PACKOBJ BATCH PASS INSTALLED %lu ALREADY %lu TAGS %lu "
        "PROCESSED %lu UNIQUE %lu\n",installed,already,tags,
        limit,unique);
 return 0;
badindex:
 puts("PACKOBJ BATCH INDEX INVALID");
fail:
 if(old) fclose(old);
 if(out) fclose(out);
 if(check) fclose(check);
 if(idx) fclose(idx);
 if(stage) fclose(stage);
 free(idxoid);
 free(bynum);
 return 8;
}

int main(int argc,char **argv) {
 FILE *in,*out;
 unsigned char want[20],stored[20],got[20],*body=0;
 unsigned long num,size,offset,k,take,m,expectnum,expectsize;
 int type,fields,expecttype;
 char line[128],oid[41],extra;
 static const char hex[]="0123456789ABCDEF";
 const char *typename;
 if((argc==4||argc==5)&&strcmp(argv[1],"BATCH")==0&&
    strlen(argv[2])==1)
  return load_batch(argv[2][0],argv[3],argc==5?argv[4]:"0");
 if(argc!=6||!hexoid(argv[1],want)) {
  puts("Usage: GITPLOAD BATCH filemode object-count [limit] | oid"
       " object-number type size stage-offset");
  return 4;
 }
 fields=sscanf(argv[2],"%lu%c",&num,&extra);
 if(fields!=1||num<1) return 4;
 expectnum=num;
 fields=sscanf(argv[3],"%d%c",&type,&extra);
 if(fields!=1||type<1||type>4) return 4;
 expecttype=type;
 fields=sscanf(argv[4],"%lu%c",&size,&extra);
 if(fields!=1||size>OBJMAXSZ) return 4;
 expectsize=size;
 fields=sscanf(argv[5],"%lu%c",&offset,&extra);
 if(fields!=1||offset>0x7fffffffUL) return 4;
 in=fopen("dd:STGIN","r");
 if(!in) { perror("STGIN");return 8; }
 if(fseek(in,(long)offset,SEEK_SET)!=0||
    !linein(in,line,sizeof line)||
    !parse_header(line,&num,&type,&size,stored)||
    num!=expectnum||type!=expecttype||size!=expectsize||
    memcmp(want,stored,20)!=0||!readbody(in,size,&body)) {
  puts("PACKOBJ STAGE RECORD INVALID");fclose(in);return 8;
 }
 if(fclose(in)!=0) { free(body);return 8; }
 if(!object_oid(type,body,size,got)||memcmp(got,want,20)!=0) {
  puts("PACKOBJ STAGE HASH INVALID");free(body);return 8;
 }
 strcpy(oid,argv[1]);
 typename=type==1?"COMMIT":type==2?"TREE":
          type==3?"BLOB":"TAG";
 out=fopen("dd:OBJOUT","w");
 if(!out) { perror("OBJOUT");free(body);return 8; }
 if(fprintf(out,"OID %s\nTYPE %s\nSIZE %lu\n",
            oid,typename,size)<0) goto bad;
 for(k=0;k<size;k+=take) {
  take=size-k;if(take>32) take=32;
  if(fputs("DATA ",out)==EOF) goto bad;
  for(m=0;m<take;m++) {
   fputc(hex[body[k+m]>>4],out);
   fputc(hex[body[k+m]&15],out);
  }
  if(fputc('\n',out)==EOF) goto bad;
 }
 if(fclose(out)!=0) { free(body);return 8; }
 free(body);
 printf("PACKOBJ LOOSE PASS %s\n",oid);
 return 0;
bad:
 fclose(out);free(body);puts("PACKOBJ LOOSE WRITE FAIL");return 8;
}
