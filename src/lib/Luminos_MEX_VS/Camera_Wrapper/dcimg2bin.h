#pragma once
#ifndef _include_dcimg2bin_h_
#define _include_dcimg2bin_h_
#include "Cam_Control.h"
#include "Hamamatsu_Cam.h"

#ifndef mex_h
#define myErrMsgFcn(MSG)                                                       \
  {                                                                            \
    printf(MSG);                                                               \
    printf("\n");                                                              \
    return false;                                                              \
  }
#else
#define myErrMsgFcn(MSG)                                                       \
  { mexErrMsgTxt(MSG); }
#endif

void dcimgcon_show_dcimgerr(DCIMG_ERR errid, const char *apiname);
HDCIMG dcimgcon_init_open(const wchar_t *filename);
char *get_extension(char *p);
bool convert_file(const char *dcimg_fname, const char *fname_bin_temp);

#endif