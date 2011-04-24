#include <dlfcn.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

int
(*cclmain)();

int
main(int argc, char *argv[], char *envp, void *auxv)
{
  char buf[PATH_MAX], *path;
  int n;
  void *libhandle;

  if ((n = readlink("/proc/self/exe", buf, PATH_MAX)) > 0) {
    path = malloc(n+4);
    memmove(path,buf,n);
    memmove(path+n,".so",3);
    path[n+3] = 0;
    libhandle = dlopen(path,RTLD_GLOBAL|RTLD_NOW);
    if (libhandle != NULL) {
      cclmain = dlsym(libhandle, "cclmain");
      if (cclmain != NULL) {
        return cclmain(argc,argv,envp, auxv);
      } else {
        fprintf(stderr, "Couldn't resolve library entrpoint.\n");
      }
    } else {
      fprintf(stderr, "Couldn't open shared library %s : %s\n",
              path, dlerror());
    }
    return 1;
  }
}




  
