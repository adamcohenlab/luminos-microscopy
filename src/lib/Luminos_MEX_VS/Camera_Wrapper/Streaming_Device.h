#pragma once
#include <string>
//Streaming_Device prototype
class Streaming_Device {
public:
  virtual bool aq_live_restart(SDL_Rect inputROI, int binning,
                               double exposureTime) = 0;
  virtual CamFrame *aq_thread_snap(void) = 0;
  virtual void aq_live_stop() = 0;
  virtual double find_sensor_size() = 0; //Must have double return value to accomodate confocal, and other systems with non-integer 'size'
  bool framereset_switch;
  bool isCapturing;
  bool isRecording;
  HANDLE ghMutexCapturing;
  SDL_Rect ROI;
  SDL_Rect oldROI;
  CamFrame *LastFrame;
  double exposureTimeSeconds;
  int bin;
  int pixarraysize;
};