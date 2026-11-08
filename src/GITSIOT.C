/* GITSIOT: measure CMS record I/O cost, sequential and random.
 * Usage: GITSIOT MAKE records reclen
 *        GITSIOT SEQ
 *        GITSIOT SEEK byte-offset
 * The caller sets FILEDEF TEST DISK ... with the desired RECFM/LRECL.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

static double secs(clock_t a,clock_t b) {
 return (double)(b-a)/(double)CLOCKS_PER_SEC;
}

int main(int argc,char **argv) {
 FILE *f;
 clock_t t0,t1;
 long i,n,sz,k,off,lines,bytes;
 char *buf;
 char c;

 if(argc<2) return 4;
 t0=clock();
 if(strcmp(argv[1],"MAKE")==0) {
  if(argc!=4) return 4;
  n=atol(argv[2]);
  sz=atol(argv[3]);
  f=fopen("dd:TEST","w");
  if(!f) {
   perror("TEST");
   return 8;
  }
  for(i=0;i<n;i++) {
   for(k=0;k<sz;k++)
    fputc((int)('A'+(int)((i+k)%26)),f);
   fputc('\n',f);
  }
  if(fclose(f)!=0) return 8;
  t1=clock();
  printf("SIOT MAKE RECS %ld LEN %ld SEC %.3f\n",n,sz,secs(t0,t1));
  return 0;
 }
 if(strcmp(argv[1],"SEQ")==0) {
  buf=(char *)malloc(65536);
  if(!buf) return 8;
  lines=0;
  bytes=0;
  f=fopen("dd:TEST","r");
  if(!f) {
   perror("TEST");
   return 8;
  }
  while(fgets(buf,65536,f)) {
   lines++;
   bytes+=(long)strlen(buf);
  }
  fclose(f);
  t1=clock();
  printf("SIOT SEQ LINES %ld BYTES %ld SEC %.3f\n",lines,bytes,secs(t0,t1));
  free(buf);
  return 0;
 }
 if(strcmp(argv[1],"SEEK")==0) {
  if(argc!=3) return 4;
  off=atol(argv[2]);
  buf=(char *)malloc(65536);
  if(!buf) return 8;
  f=fopen("dd:TEST","r");
  if(!f) {
   perror("TEST");
   return 8;
  }
  if(fseek(f,off,SEEK_SET)!=0) {
   perror("seek");
   return 8;
  }
  c=(char)((fgets(buf,65536,f)!=0)?1:0);
  t1=clock();
  printf("SIOT SEEK OFF %ld GOT %d LEN %ld SEC %.3f\n",off,(int)c,
         (long)strlen(buf),secs(t0,t1));
  free(buf);
  fclose(f);
  return 0;
 }
 return 4;
}
