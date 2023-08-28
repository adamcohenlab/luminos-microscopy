#pragma once
#include "Cam_Control.h"

#include "../inc/Andor_SDK/ATMCD32D.H"

unsigned convertThreadFcn(void *pArguments);
#pragma message("Need to be defined")
class Andor_Cam : public Cam_Control {
public:
  Andor_Cam();
  void Set_Mode(int modeid);
  double find_sensor_size();
  void aq_sync_stop();
  void aq_live_stop();
  bool aq_sync_prepare(SDL_Rect inputROI, int binning, double exposureTime);
  bool aq_sync_start(int32 recordFrames, const char *fpath);
  bool dc_shutdown();
  bool aq_live_restart(SDL_Rect inputROI, int binning, double exposureTime);
  bool aq_live_restart();
  bool set_arbitrary_roi(SDL_Rect ROItry);
  CamFrame *aq_snap();
  CamFrame *aq_thread_snap();
  int xpixels, ypixels;
  // mrh 7/20/21
  int vssindex;
  float vsspeed;
  int hbin, vbin;
  char aBuffer[256];
  int32_t *buff32;
  uint16_t *buff16;

private:
  bool verboseFlag = true;
};
