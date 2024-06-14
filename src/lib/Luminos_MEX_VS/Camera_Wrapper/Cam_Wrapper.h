// check if hamamatsu camera is configured
#if __has_include("../inc/custom/dcamsdk4/inc/dcamapi4.h") &&                         \
                  __has_include("../inc/custom/dcimgsdk/inc/dcimgapi.h")
#define HAMAMATSU_CONFIGURED
#endif

// check if andor camera is configured
#if __has_include("../inc/custom/Andor_SDK/ATMCD32D.H")
#define ANDOR_CONFIGURED
#endif

#if __has_include("../inc/custom/PVCAM/inc/pvcam.h")
#define KINETIX_CONFIGURED
#endif

#include "StreamDisplayHD.h"
#include "Cam_Control.h"

#pragma once

// This class is exported from the dll
class LUMINOSCAMERA_API Cam_Wrapper {
public:
  Cam_Wrapper(int Cam_type, const char *camid);
  ~Cam_Wrapper();
  // TYPE CONSTANTS to define camera type "macros" (const better than
  // preprocessor macros in c++)
  static const int TYPE_EMULATOR = 0;
  static const int TYPE_HAMAMATSU = 1;
  static const int TYPE_ANDOR = 2;
  static const int TYPE_KINETIX = 3;
  // START METHOD LIST
  void Prepare_Sync_Acquisition(double exposuretime, int32 *ROI_in,
                                uint32_t binning);
  void Set_Cmap_Thresholds(double cmap_low_val, double cmap_high_val);
  bool Start_Acquisition(int32 numframes, const char *fpath);
  double Set_Exposure(double exp_request);
  double Get_Exposure();
  int ROI_Buff_Avail();
  int ROI_Sum_Buff_Avail();
  void GetROI(int32 *ROI);
  void GetSumRect(int32 *ROI);
  void GetSnap(uint16_t *snapframe, int numpixels);
  bool Get_ROI_Buffer(double *dataout, int samps);
  bool Get_ROI_Sum_Buffer(double *dataout, int samps);
  bool Set_Binning(uint32_t binning);
  double Get_Binning();
  void Stop_Sync_Acquisition();
  void Stop_Live_Acquisition();
  bool Set_ROI(int32 *ROI_in);
  bool Is_Cam_Recording();
  int Get_Contour_numel();
  bool Get_Contour_Data(double *dataout, int len);
  bool Contour_Data_Ready();
  int Dropped_Frame_Check();
  int Acq_Done_Check();
  void Cleanup();
  void Set_RDrive_Mode(bool mode);
  void Set_Read_Mode(int mode);
  // END METHOD LIST
private:
  Cam_Control *cam;
  StreamDisplayHD SDisplay;
  SDL_Rect ROI;
};
