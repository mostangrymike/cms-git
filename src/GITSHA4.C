/* Read-only SHA-256 for native CMS record contents. */
#include <stdio.h>
#include <string.h>

#define W32 0xffffffffUL

static const unsigned long kt[64]={
 0x428a2f98UL,0x71374491UL,0xb5c0fbcfUL,0xe9b5dba5UL,
 0x3956c25bUL,0x59f111f1UL,0x923f82a4UL,0xab1c5ed5UL,
 0xd807aa98UL,0x12835b01UL,0x243185beUL,0x550c7dc3UL,
 0x72be5d74UL,0x80deb1feUL,0x9bdc06a7UL,0xc19bf174UL,
 0xe49b69c1UL,0xefbe4786UL,0x0fc19dc6UL,0x240ca1ccUL,
 0x2de92c6fUL,0x4a7484aaUL,0x5cb0a9dcUL,0x76f988daUL,
 0x983e5152UL,0xa831c66dUL,0xb00327c8UL,0xbf597fc7UL,
 0xc6e00bf3UL,0xd5a79147UL,0x06ca6351UL,0x14292967UL,
 0x27b70a85UL,0x2e1b2138UL,0x4d2c6dfcUL,0x53380d13UL,
 0x650a7354UL,0x766a0abbUL,0x81c2c92eUL,0x92722c85UL,
 0xa2bfe8a1UL,0xa81a664bUL,0xc24b8b70UL,0xc76c51a3UL,
 0xd192e819UL,0xd6990624UL,0xf40e3585UL,0x106aa070UL,
 0x19a4c116UL,0x1e376c08UL,0x2748774cUL,0x34b0bcb5UL,
 0x391c0cb3UL,0x4ed8aa4aUL,0x5b9cca4fUL,0x682e6ff3UL,
 0x748f82eeUL,0x78a5636fUL,0x84c87814UL,0x8cc70208UL,
 0x90befffaUL,0xa4506cebUL,0xbef9a3f7UL,0xc67178f2UL
};

static unsigned long hs[8];
static unsigned char buf[64];
static unsigned int used;
static unsigned long bytes;

static unsigned long sxor(unsigned long a,unsigned long b) {
 return ((a|b)&(~(a&b)))&W32;
}

static unsigned long ror(unsigned long x,unsigned int n) {
 return ((x>>n)|(x<<(32-n)))&W32;
}

static void block(const unsigned char *p) {
 unsigned long w[64],a,b,c,d,e,f,g,h,t1,t2,s0,s1,ch,maj;
 unsigned int i;
 for(i=0;i<16;i++)
  w[i]=((unsigned long)p[4*i]<<24)|
       ((unsigned long)p[4*i+1]<<16)|
       ((unsigned long)p[4*i+2]<<8)|p[4*i+3];
 for(i=16;i<64;i++) {
  s0=sxor(sxor(ror(w[i-15],7),ror(w[i-15],18)),w[i-15]>>3);
  s1=sxor(sxor(ror(w[i-2],17),ror(w[i-2],19)),w[i-2]>>10);
  w[i]=(w[i-16]+s0+w[i-7]+s1)&W32;
 }
 a=hs[0];b=hs[1];c=hs[2];d=hs[3];
 e=hs[4];f=hs[5];g=hs[6];h=hs[7];
 for(i=0;i<64;i++) {
  s1=sxor(sxor(ror(e,6),ror(e,11)),ror(e,25));
  ch=sxor(e&f,(~e)&g);
  t1=(h+s1+ch+kt[i]+w[i])&W32;
  s0=sxor(sxor(ror(a,2),ror(a,13)),ror(a,22));
  maj=sxor(sxor(a&b,a&c),b&c);
  t2=(s0+maj)&W32;
  h=g;g=f;f=e;e=(d+t1)&W32;
  d=c;c=b;b=a;a=(t1+t2)&W32;
 }
 hs[0]=(hs[0]+a)&W32;hs[1]=(hs[1]+b)&W32;
 hs[2]=(hs[2]+c)&W32;hs[3]=(hs[3]+d)&W32;
 hs[4]=(hs[4]+e)&W32;hs[5]=(hs[5]+f)&W32;
 hs[6]=(hs[6]+g)&W32;hs[7]=(hs[7]+h)&W32;
}

static void init(void) {
 hs[0]=0x6a09e667UL;hs[1]=0xbb67ae85UL;
 hs[2]=0x3c6ef372UL;hs[3]=0xa54ff53aUL;
 hs[4]=0x510e527fUL;hs[5]=0x9b05688cUL;
 hs[6]=0x1f83d9abUL;hs[7]=0x5be0cd19UL;
 used=0;bytes=0;
}

static int update(unsigned char c) {
 if(bytes==W32) return 0;
 buf[used++]=c;bytes++;
 if(used==64) { block(buf);used=0; }
 return 1;
}

static void finish(unsigned char out[32]) {
 unsigned long hi=(bytes>>29)&W32,lo=(bytes<<3)&W32;
 unsigned int i;
 buf[used++]=0x80;
 if(used>56) {
  while(used<64) buf[used++]=0;
  block(buf);used=0;
 }
 while(used<56) buf[used++]=0;
 for(i=0;i<4;i++) buf[used++]=(unsigned char)(hi>>(24-i*8));
 for(i=0;i<4;i++) buf[used++]=(unsigned char)(lo>>(24-i*8));
 block(buf);
 for(i=0;i<8;i++) {
  out[4*i]=(unsigned char)(hs[i]>>24);
  out[4*i+1]=(unsigned char)(hs[i]>>16);
  out[4*i+2]=(unsigned char)(hs[i]>>8);
  out[4*i+3]=(unsigned char)hs[i];
 }
}

static int nib(int c) {
 if(c>='0'&&c<='9') return c-'0';
 if(c>='A'&&c<='F') return c-'A'+10;
 if(c>='a'&&c<='f') return c-'a'+10;
 return -1;
}

static int selftest(void) {
 static const char *vectors[]={
  "",
  "616263",
  ("6162636462636465636465666465666765666768666768696768696a68696a6b"
   "696a6b6c6a6b6c6d6b6c6d6e6c6d6e6f6d6e6f706e6f7071")
 };
 static const char *wants[]={
  "E3B0C44298FC1C149AFBF4C8996FB924"
  "27AE41E4649B934CA495991B7852B855",
  "BA7816BF8F01CFEA414140DE5DAE2223"
  "B00361A396177A9CB410FF61F20015AD",
  "248D6A61D20638B8E5C026930C3E6039"
  "A33CE45964FF2167F6ECEDD419DB06C1"
 };
 unsigned char data[64],digest[32];
 char got[65];
 unsigned int v,i,n;
 int hi,lo;
 for(v=0;v<3;v++) {
  n=0;
  for(i=0;vectors[v][i];i+=2) {
   hi=nib(vectors[v][i]);lo=nib(vectors[v][i+1]);
   if(hi<0||lo<0) return 0;
   data[n++]=(unsigned char)((hi<<4)|lo);
  }
  init();
  for(i=0;i<n;i++) if(!update(data[i])) return 0;
  finish(digest);
  for(i=0;i<32;i++) sprintf(got+2*i,"%02X",digest[i]);
  got[64]=0;
  if(strcmp(got,wants[v])!=0) return 0;
 }
 puts("SHA256 SELFTEST PASS 3 VECTORS");
 return 1;
}

int main(int argc,char **argv) {
 FILE *f;
 unsigned char digest[32];
 const char *path;
 unsigned int i;
 int c,records;
 if(argc==2&&strcmp(argv[1],"TEST")==0)
  return selftest()?0:8;
 records=(argc==1);
 path=records?"dd:HASHIN":argv[1];
 if(argc==3&&strcmp(argv[1],"RECORDS")==0) {
  records=1;path=argv[2];
 } else if(argc>2) {
  puts("Usage: GITSHA4 [host-file] | RECORDS host-file | TEST");
  return 4;
 }
 f=fopen(path,records?"r":"rb");
 if(!f) { perror(path);return 8; }
 init();
 while((c=fgetc(f))!=EOF) {
  /* CMS text streams expose record boundaries as newline bytes. */
  if(records&&c=='\n') continue;
  if(!update((unsigned char)c)) {
   puts("SHA256 FILE EXCEEDS 32-BIT BYTE LIMIT");
   fclose(f);return 8;
  }
 }
 if(ferror(f)) { puts("SHA256 READ ERROR");fclose(f);return 8; }
 if(fclose(f)!=0) { puts("SHA256 CLOSE ERROR");return 8; }
 finish(digest);
 printf("SHA256 %lu\n",bytes);
 for(i=0;i<32;i++) printf("%02X",digest[i]);
 putchar('\n');
 return 0;
}
