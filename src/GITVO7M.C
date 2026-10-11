/* M197: strict C89 full Git object SHA1 from disposable OBJIN. */
/* Read-only object verifier; NEVER open original G stage or index. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <limits.h>

#define W32 0xffffffffUL
#define MAXSIZE (16UL*1024UL*1024UL)
#define MAXOBJ 100000UL

static unsigned long sha[5];

static unsigned long rol(unsigned long n,unsigned int x) {
 n&=W32;
 return ((n<<x)|(n>>(32-x)))&W32;
}
static unsigned long sxor(unsigned long a,unsigned long b) {
 return ((a|b)&(~(a&b)))&W32;
}
static void sha_block(const unsigned char p[64]) {
 unsigned long w[80],a,b,c,d,e,t,f,k;
 unsigned int i;
 for(i=0;i<16;i++)
  w[i]=((unsigned long)p[4*i]<<24)|
       ((unsigned long)p[4*i+1]<<16)|
       ((unsigned long)p[4*i+2]<<8)|p[4*i+3];
 for(i=16;i<80;i++)
  w[i]=rol(sxor(sxor(w[i-3],w[i-8]),
                sxor(w[i-14],w[i-16])),1);
 a=sha[0];b=sha[1];c=sha[2];d=sha[3];e=sha[4];
 for(i=0;i<80;i++) {
  if(i<20) {
   f=(b&c)|((~b)&d);k=0x5a827999UL;
  } else if(i<40) {
   f=sxor(sxor(b,c),d);k=0x6ed9eba1UL;
  } else if(i<60) {
   f=(b&c)|(b&d)|(c&d);k=0x8f1bbcdcUL;
  } else {
   f=sxor(sxor(b,c),d);k=0xca62c1d6UL;
  }
  t=(rol(a,5)+f+e+k+w[i])&W32;
  e=d;d=c;c=rol(b,30);b=a;a=t;
 }
 sha[0]=(sha[0]+a)&W32;sha[1]=(sha[1]+b)&W32;
 sha[2]=(sha[2]+c)&W32;sha[3]=(sha[3]+d)&W32;
 sha[4]=(sha[4]+e)&W32;
}
static void sha_init(void) {
 sha[0]=0x67452301UL;sha[1]=0xefcdab89UL;
 sha[2]=0x98badcfeUL;sha[3]=0x10325476UL;
 sha[4]=0xc3d2e1f0UL;
}
static void sha_parts(const unsigned char *head,unsigned long hn,
                      const unsigned char *body,unsigned long n,
                      unsigned char out[20]) {
 unsigned char block[64],tail[128];
 unsigned long total=hn+n,done=0,at,rem,bits;
 unsigned int i,j;
 sha_init();
 while(total-done>=64UL) {
  for(i=0;i<64;i++) {
   at=done+(unsigned long)i;
   block[i]=at<hn?head[at]:body[at-hn];
  }
  sha_block(block);
  done+=64UL;
 }
 rem=total-done;
 memset(tail,0,sizeof tail);
 for(i=0;i<rem;i++) {
  at=done+(unsigned long)i;
  tail[i]=at<hn?head[at]:body[at-hn];
 }
 tail[rem]=0x80;
 bits=total*8UL;
 for(i=0;i<8;i++)
  tail[(rem<56?56:120)+i]=
   (unsigned char)(i<4?0:(bits>>(8*(7-i))));
 sha_block(tail);
 if(rem>=56) sha_block(tail+64);
 for(i=0;i<5;i++) for(j=0;j<4;j++)
  out[i*4+j]=(unsigned char)(sha[i]>>(24-j*8));
}
static const char *kind[5]={"","commit","tree","blob","tag"};
static int object_sha(int type,const unsigned char *body,
                      unsigned long n,unsigned char out[20]) {
 unsigned char head[32],reverse[16];
 unsigned long rem;
 int i=0,j=0;
 const char *name;
 if(type<1||type>4||n>MAXSIZE) return 0;
 name=kind[type];
 while(*name) head[i++]=(unsigned char)*name++;
 head[i++]=0x20;
 rem=n;
 do {
  reverse[j++]=(unsigned char)('0'+rem%10UL);
  rem/=10UL;
 } while(rem);
 while(j) head[i++]=reverse[--j];
 head[i++]=0;
 sha_parts(head,(unsigned long)i,body,n,out);
 return 1;
}
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
static void oidprint(const unsigned char in[20]) {
 static const char hex[]="0123456789ABCDEF";
 int i;
 for(i=0;i<20;i++) {
  putchar(hex[in[i]>>4]);
  putchar(hex[in[i]&15]);
 }
}
static int decimal(const char *s,unsigned long *v) {
 char *end;
 if(!s||!*s||*s<'0'||*s>'9') return 0;
 errno=0;
 *v=strtoul(s,&end,10);
 return !errno&&!*end;
}
/* Read one text record at most 80 chars; reject NUL and truncation. */
static int record(FILE *f,char *dst) {
 int c,n=0,seen=0;
 while((c=fgetc(f))!=EOF) {
  seen=1;
  if(c=='\n') break;
  if(c==0||n>=80) return 0;
  dst[n++]=(char)c;
 }
 if(!seen) return 0;
 while(n&&(dst[n-1]=='\r'||dst[n-1]==' '))
  n--;
 dst[n]=0;
 return 1;
}
static int verify(FILE *f,unsigned long target,
                  const unsigned char expected[20]) {
 char line[81],text[41],extra;
 unsigned char oid[20],hash[20],*body=0;
 unsigned long number,size,at,take,j,records=0;
 int type,fields,h,l,ok=0;
 if(!record(f,line)) goto done;
 fields=sscanf(line,"OBJ %lu %d %lu %40s %c",
               &number,&type,&size,text,&extra);
 if(fields!=4||number!=target||type<1||type>4||
    size>MAXSIZE||!oidparse(text,oid)||
    memcmp(oid,expected,20)!=0) goto done;
 body=(unsigned char *)malloc((size_t)(size?size:1));
 if(!body) goto done;
 if(size==0) {
  if(!record(f,line)||line[0]!=0) goto done;
  records=1;
 } else {
  at=0;
  while(at<size) {
   take=size-at;
   if(take>32UL) take=32UL;
   if(!record(f,line)||strlen(line)!=(size_t)(2UL*take))
    goto done;
   for(j=0;j<take;j++) {
    h=nib((unsigned char)line[2*j]);
    l=nib((unsigned char)line[2*j+1]);
    if(h<0||l<0) goto done;
    body[at+j]=(unsigned char)((h<<4)|l);
   }
   at+=take;
   records++;
  }
 }
 if(record(f,line)||!feof(f)||ferror(f)) goto done;
 if(!object_sha(type,body,size,hash)||
    memcmp(hash,expected,20)!=0) {
  puts("M197 OBJECT SHA1 MISMATCH");
  goto done;
 }
 printf("M197 OBJECT %lu TYPE %d SIZE %lu BODY RECORDS %lu\n",
        number,type,size,records);
 printf("M197 VERIFIED OID ");
 oidprint(hash);
 putchar('\n');
 puts("M197 READ ONLY FULL OBJECT SHA1 PASS");
 ok=1;
done:
 if(!ok) puts("M197 OBJECT VALIDATION FAIL");
 free(body);
 return ok;
}
int main(int argc,char **argv) {
 FILE *f;
 unsigned long number;
 unsigned char expected[20];
 int rc=8,ok;
 if(argc!=4||strcmp(argv[1],"VERIFY")!=0||
    !decimal(argv[2],&number)||number==0||
    number>MAXOBJ||!oidparse(argv[3],expected)) {
  puts("Usage: GITVO7M VERIFY object-number 40-hex-oid");
  return 4;
 }
 f=fopen("dd:OBJIN","r");
 if(!f) {
  puts("M197 OBJIN MISSING");
  return 8;
 }
 ok=verify(f,number,expected);
 if(fclose(f)!=0) ok=0;
 if(ok) rc=0;
 return rc;
}
