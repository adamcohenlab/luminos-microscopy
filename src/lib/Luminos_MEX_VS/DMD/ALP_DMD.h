#pragma once
#include "alp.h"
#include <cstdio>
#include <windows.h>
#include <memory>
#include <mutex>

#ifdef ALP_DMD_HD_EXPORTS
#define ALP_DMD_HD_API __declspec(dllexport)
#else
#define ALP_DMD_HD_API __declspec(dllimport)
#endif

class ALP_DMD_HD_API ALP_DMD {
public:
  ALP_DMD();
  ~ALP_DMD();
  int CleanUp();
  int Reset_Image();
  long Project();
  long Project(unsigned char *image);
  long Project_White();
  long Project_Black();
  long Project_Checkerboard();
  unsigned char *image;
  unsigned char *testpatterns;
  long nDmdType, nSizeX, nSizeY;
  ALP_ID nDevId, nSeqId;
  unsigned long serial;
  long nPictureTime;
};
