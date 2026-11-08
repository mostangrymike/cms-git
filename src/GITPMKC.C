/* M280: create a Git packfile from CMS loose objects.
 *
 * Reads a staging file of OBJ records (type size oid hex...), compresses
 * each object with DEFLATE stored blocks inside a zlib wrapper (RFC 1950),
 * and writes a Git packfile with a correct SHA1 trailer.
 *
 * Usage: GITPMK BUILD <staging-file> <pack-file>
 *
 * Staging file format (one object per record):
 *   OBJ <type> <size> <oid>
 *   <hex data, 64 chars per line, empty line for zero-size objects>
 *
 * Uses DEFLATE stored blocks (BTYPE=00) so no Huffman tables are needed.
 * Correct but not maximally compressed: fine for small CMS pushes.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define OBJMAX 100000UL
#define MAXOBJS 10000UL
#define CHUNK 65535UL
#define W32 0xffffffffUL
#define PACKMAX (16UL*1024UL*1024UL)

static unsigned long sh[5];

/* Pack output buffer (global so append_bytes can use it). */
static unsigned char packbuf[PACKMAX];
static unsigned long packlen=0;

static int append_bytes(const unsigned char *d,unsigned long n) {
 if(packlen+n>PACKMAX) return 0;
 memcpy(packbuf+packlen,d,n);
 packlen+=n;
 return 1;
}

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
 while(n>0&&(line[n-1]=='\n'||line[n-1]=='\r'||line[n-1]==' ')) line[--n]=0;
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

/* ---- SHA1 ---- */

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
  w[i]=((unsigned long)p[i*4]<<24)|((unsigned long)p[i*4+1]<<16)|
       ((unsigned long)p[i*4+2]<<8)|p[i*4+3];
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

static void initsha(void) {
 sh[0]=0x67452301UL;sh[1]=0xefcdab89UL;
 sh[2]=0x98badcfeUL;sh[3]=0x10325476UL;sh[4]=0xc3d2e1f0UL;
}

static void sha_final(unsigned char digest[20],
                      const unsigned char *taildata,unsigned long taillen,
                      unsigned long totalbytes) {
 unsigned char tail[128];
 unsigned long rem, i, j;
 rem=taillen;
 for(i=0;i<128;i++) tail[i]=0;
 if(rem>0) memcpy(tail,taildata,(size_t)rem);
 tail[rem]=0x80;
 for(i=0;i<8;i++)
  tail[(rem<56?56:120)+i]=
   (unsigned char)(i<4?0:((totalbytes*8)>>(8*(7-i))));
 block(tail);
 if(rem>=56) block(tail+64);
 for(i=0;i<5;i++) for(j=0;j<4;j++)
  digest[i*4+j]=(unsigned char)(sh[i]>>(24-j*8));
}

/* ---- zlib/DEFLATE stored-block compression ---- */

static unsigned long adler32(const unsigned char *data,unsigned long len) {
 unsigned long a=1,b=0,i;
 for(i=0;i<len;i++) {
  a=(a+data[i])%65521UL;
  b=(b+a)%65521UL;
 }
 return (b<<16)|a;
}

static unsigned long deflate_stored(const unsigned char *in,unsigned long inlen,
                                    unsigned char *out,unsigned long outcap) {
 unsigned long op=0,ip=0;
 if(inlen==0) {
  if(outcap<5) return 0;
  out[0]=1; out[1]=0; out[2]=0; out[3]=0xff; out[4]=0xff;
  return 5;
 }
 while(ip<inlen) {
  unsigned long blocklen=inlen-ip;
  int final;
  if(blocklen>CHUNK) blocklen=CHUNK;
  final=(ip+blocklen>=inlen)?1:0;
  if(op>=outcap) return 0;
  out[op++]=(unsigned char)final;
  if(op+4>outcap) return 0;
  out[op++]=(unsigned char)(blocklen&0xFF);
  out[op++]=(unsigned char)((blocklen>>8)&0xFF);
  out[op++]=(unsigned char)((~blocklen)&0xFF);
  out[op++]=(unsigned char)((~blocklen>>8)&0xFF);
  if(op+blocklen>outcap) return 0;
  memcpy(out+op,in+ip,(size_t)blocklen);
  op+=blocklen;
  ip+=blocklen;
 }
 return op;
}

static unsigned long zlib_wrap(const unsigned char *deflate,unsigned long dlen,
                               const unsigned char *plain,unsigned long plen,
                               unsigned char *out,unsigned long outcap) {
 unsigned long adler;
 if(outcap<dlen+6) return 0;
 out[0]=0x78;
 out[1]=0x01;
 memcpy(out+2,deflate,dlen);
 adler=adler32(plain,plen);
 out[dlen+2]=(unsigned char)((adler>>24)&0xFF);
 out[dlen+3]=(unsigned char)((adler>>16)&0xFF);
 out[dlen+4]=(unsigned char)((adler>>8)&0xFF);
 out[dlen+5]=(unsigned char)(adler&0xFF);
 return dlen+6;
}

/* ---- Pack object header ---- */

static unsigned long pack_header(int type,unsigned long size,
                                 unsigned char *out,unsigned long outcap) {
 unsigned long op=0,remaining=size;
 int cont;
 out[op]=(unsigned char)((type<<4)|(remaining&0xF));
 cont=(remaining>0xF)?1:0;
 if(cont) out[op]|=0x80;
 op++;
 remaining>>=4;
 while(cont) {
  if(op>=outcap) return 0;
  out[op]=(unsigned char)(remaining&0x7F);
  remaining>>=7;
  cont=(remaining>0)?1:0;
  if(cont) out[op]|=0x80;
  op++;
 }
 return op;
}

/* ---- Object record from staging file ---- */

struct objrec {
 unsigned long type;
 unsigned long size;
 unsigned char oid[20];
 unsigned char *data;
};

static int read_objrecs(FILE *f,struct objrec *objs,unsigned long *count) {
 char line[8192];
 unsigned long n=0;
 while(n<MAXOBJS) {
  if(!linein(f,line,sizeof line)) break;
  if(strlen(line)==0) continue;
  unsigned long typ,sz;
  char oidtext[41],extra;
  int fields=sscanf(line,"OBJ %lu %lu %40s %c",&typ,&sz,oidtext,&extra);
  if(fields!=3||typ<1||typ>4||sz>(16UL*1024UL*1024UL)||
     !hexoid(oidtext,objs[n].oid)) {
   fprintf(stderr,"GITPMK: bad OBJ header: %s\n",line);
   return 0;
  }
  objs[n].type=typ;
  objs[n].size=sz;
  objs[n].data=NULL;
  if(sz==0) {
   if(!linein(f,line,sizeof line)||line[0]!='\0') {
    fprintf(stderr,"GITPMK: expected empty data line\n");
    return 0;
   }
   objs[n].data=(unsigned char *)calloc(1,1);
   if(!objs[n].data) return 0;
  } else {
   unsigned long k,take;
   objs[n].data=(unsigned char *)malloc((size_t)sz);
   if(!objs[n].data) return 0;
   for(k=0;k<sz;) {
    if(!linein(f,line,sizeof line)) {
     fprintf(stderr,"GITPMK: truncated object data\n");
     return 0;
    }
    take=(unsigned long)strlen(line)/2;
    if(take==0||strlen(line)%2||take>sz-k) {
     fprintf(stderr,"GITPMK: bad hex data line\n");
     return 0;
    }
    unsigned long m;
    for(m=0;m<take;m++) {
     int hi=nib((unsigned char)line[m*2]);
     int lo=nib((unsigned char)line[m*2+1]);
     if(hi<0||lo<0) {
      fprintf(stderr,"GITPMK: bad hex digit\n");
      return 0;
     }
     objs[n].data[k+m]=(unsigned char)((hi<<4)|lo);
    }
    k+=take;
   }
  }
  n++;
 }
 *count=n;
 return 1;
}

/* ---- Main ---- */

int main(int argc,char **argv) {
 if(argc!=2||strcmp(argv[1],"BUILD")!=0) {
  fprintf(stderr,"Usage: GITPMK BUILD  (reads dd:OBJSTG, writes dd:OBJOUT)\n");
  return 4;
 }
 FILE *fin=fopen("dd:OBJSTG","r");
 if(!fin) { perror("OBJSTG"); return 8; }
 struct objrec objs[MAXOBJS];
 unsigned long nobj=0;
 if(!read_objrecs(fin,objs,&nobj)) { fclose(fin); return 8; }
 fclose(fin);

 if(nobj==0) {
  fprintf(stderr,"GITPMK: no objects to pack\n");
  return 8;
 }

 /* Pack header. */
 unsigned char head[12];
 memcpy(head,"PACK",4);
 head[4]=0;head[5]=0;head[6]=0;head[7]=2;
 head[8]=0;head[9]=0;head[10]=(unsigned char)((nobj>>8)&0xFF);
 head[11]=(unsigned char)(nobj&0xFF);
 if(!append_bytes(head,12)) { fprintf(stderr,"GITPMK: pack too large\n");return 8; }

 /* Compression buffers sized for the largest object. */
 unsigned long maxsize=0;
 unsigned long i;
 for(i=0;i<nobj;i++) if(objs[i].size>maxsize) maxsize=objs[i].size;
 unsigned long deflatecap=maxsize+maxsize/CHUNK*5+64;
 if(deflatecap<CHUNK+4096) deflatecap=CHUNK+4096;
 unsigned char *deflate=malloc(deflatecap);
 unsigned char *zlib=malloc(deflatecap+64);
 if(!deflate||!zlib) { fprintf(stderr,"GITPMK: out of memory\n");return 8; }

 initsha();

 for(i=0;i<nobj;i++) {
  unsigned long comp_len=deflate_stored(objs[i].data,objs[i].size,
                                        deflate,deflatecap);
  if(comp_len==0) {
   fprintf(stderr,"GITPMK: deflate failed for object %lu\n",i+1);
   return 8;
  }
  unsigned long zlen=zlib_wrap(deflate,comp_len,objs[i].data,objs[i].size,
                               zlib,deflatecap+64);
  if(zlen==0) {
   fprintf(stderr,"GITPMK: zlib wrap failed for object %lu\n",i+1);
   return 8;
  }

  unsigned char hdr[10];
  unsigned long hlen=pack_header((int)objs[i].type,objs[i].size,hdr,10);
  if(hlen==0) {
   fprintf(stderr,"GITPMK: pack header failed for object %lu\n",i+1);
   return 8;
  }

  if(!append_bytes(hdr,hlen)) { fprintf(stderr,"GITPMK: pack too large\n");return 8; }
  if(!append_bytes(zlib,zlen)) { fprintf(stderr,"GITPMK: pack too large\n");return 8; }
 }

 /* SHA1 trailer. */
 unsigned char digest[20];
 /* Process all full 64-byte blocks of packbuf through SHA1. */
 unsigned long shaoff=0;
 while(packlen-shaoff>=64) { block(packbuf+shaoff); shaoff+=64; }
 sha_final(digest,packbuf+shaoff,packlen-shaoff,packlen);
 if(!append_bytes(digest,20)) { fprintf(stderr,"GITPMK: pack too large\n");return 8; }

 FILE *fout=fopen("dd:OBJOUT","w");
 if(!fout) { perror("OBJOUT"); return 8; }
 if(fwrite(packbuf,1,packlen,fout)!=packlen) {
  perror("OBJOUT");fclose(fout);return 8;
 }
 fclose(fout);

 for(i=0;i<nobj;i++) free(objs[i].data);
 free(deflate);free(zlib);

 printf("PACK CREATED OBJECTS %lu\n",nobj);
 puts("M280 PACK BUILD PASS");
 return 0;
}