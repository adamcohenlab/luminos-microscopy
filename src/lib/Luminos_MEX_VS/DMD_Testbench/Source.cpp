#define _CRTDBG_MAP_ALLOC
#include <iostream>
#include "ALP_DMD.h"
int main(int argc, char *argv[]) {
  ALP_DMD *dmd = new ALP_DMD();
  char x = 'a';
  while (x != EOF) {
    dmd->Project_Checkerboard();
    x = getchar();
  }
  return 0;
}
