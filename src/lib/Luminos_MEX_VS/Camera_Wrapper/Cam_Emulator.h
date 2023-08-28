#pragma once

#include "Cam_Control.h"
#include <thread>
#include <iostream>
#include <cstdlib>
#include <process.h>
#include <windows.h>

unsigned __stdcall DispCalcHD(void *pArguments);

class Cam_Emulator : public Cam_Control {
public:
  Cam_Emulator();
  ~Cam_Emulator();
  bool dc_shutdown();
  CamFrame *aq_snap(void);
  CamFrame *aq_thread_snap(void);
  bool aq_live_restart(SDL_Rect inputROI, int binning, double exposureTime);
  bool aq_live_restart();
  double find_sensor_size();
  bool aq_sync_prepare(SDL_Rect inputROI, int binning, double exposureTime) {
    return false;
  };
  bool aq_sync_start(int32 recordFrames, const char *fpath) { return false; };
  void aq_sync_stop(){};
  void aq_live_stop();
  int lastImageDataHeight, lastImageDataWidth;
  CamFrame Em_Data;
  HANDLE Em_Mutex;
  uint16_t *middlebuffer;
  HANDLE tbthread;
  int framecounter;
  bool newframe_avail;
};
