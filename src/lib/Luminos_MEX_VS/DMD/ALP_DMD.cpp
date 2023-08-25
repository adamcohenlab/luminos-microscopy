#include "ALP_DMD.h"
ALP_DMD::ALP_DMD() {
  long ret;
  nPictureTime = 100000;
  ret = AlpDevAlloc(ALP_DEFAULT, ALP_DEFAULT, &nDevId);
  ret = AlpDevInquire(nDevId, ALP_DEV_DMDTYPE, &nDmdType);
  switch (nDmdType) {
  case ALP_DMDTYPE_XGA_055A:
  case ALP_DMDTYPE_XGA_055X:
  case ALP_DMDTYPE_XGA_07A:
    nSizeX = 1024;
    nSizeY = 768;
    break;
  case ALP_DMDTYPE_DISCONNECT:
  case ALP_DMDTYPE_1080P_095A:
    nSizeX = 1920;
    nSizeY = 1080;
    break;
  case ALP_DMDTYPE_WUXGA_096A:
    nSizeX = 1920;
    nSizeY = 1200;
    break;
  case ALP_DMDTYPE_WXGA_S450:
    nSizeX = 1280;
    nSizeY = 800;
    break;
  default:
    printf("unsupported DMD type");
  }
  image = (unsigned char *)malloc(nSizeX * nSizeY * sizeof(unsigned char));
}

ALP_DMD::~ALP_DMD() { CleanUp(); }

int ALP_DMD::CleanUp() { return 0; }

long ALP_DMD::Project() {
  long ret;
  AlpDevHalt(nDevId);
  AlpSeqFree(nDevId, nSeqId);
  ret = AlpSeqAlloc(nDevId, 1, 1, &nSeqId);
  ret = AlpSeqPut(nDevId, nSeqId, 0, 1, image);
  ret = AlpSeqControl(nDevId, nSeqId, ALP_BIN_MODE, ALP_BIN_UNINTERRUPTED);
  ret = AlpSeqTiming(nDevId, nSeqId, ALP_DEFAULT, nPictureTime, ALP_DEFAULT,
                     ALP_DEFAULT, ALP_DEFAULT);
  ret = AlpProjStartCont(nDevId, nSeqId);
  return ret;
}

long ALP_DMD::Project(unsigned char *newimage) {
  memcpy(image, newimage, nSizeX * nSizeY * sizeof(unsigned char));
  return Project();
}

long ALP_DMD::Project_Checkerboard() {
  int x, y;
  for (y = 0; y < nSizeY; y++)
    for (x = 0; x < nSizeX; x++)
      image[y * nSizeX + x] = (unsigned char)((x ^ y) & 32) ? 0 : 128;
  return Project();
}

long ALP_DMD::Project_Black() {
  int x, y;
  for (y = 0; y < nSizeY; y++)
    for (x = 0; x < nSizeX; x++)
      image[y * nSizeX + x] = 0;
  return Project();
}

long ALP_DMD::Project_White() {
  int x, y;
  for (y = 0; y < nSizeY; y++)
    for (x = 0; x < nSizeX; x++)
      image[y * nSizeX + x] = 128;
  return Project();
}

int ALP_DMD::Reset_Image() { return (int)Project_Black(); }
