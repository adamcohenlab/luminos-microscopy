#include "pch.h"
#include "Cam_Wrapper.h"

#ifdef ANDOR_CONFIGURED

#include "Andor_Cam.h"

// Implements Andor scientific CCD communication.
Andor_Cam::Andor_Cam() {
  exposureTimeSeconds = .05;
  wchar_t *abuffer = new wchar_t[256];
  GetCurrentDirectory(256, (LPWSTR)abuffer);
  unsigned int ermsg;
  ermsg = Initialize(aBuffer);
  ermsg = GetDetector(&xpixels, &ypixels);
  ermsg = SetTemperature(4);
  ermsg = CoolerON();
  ermsg = SetAcquisitionMode(5); // run til abort
  // mrh 7/20/21
  ermsg = GetFastestRecommendedVSSpeed(&vssindex, &vsspeed);
  SetVSSpeed(vssindex);
  isCapturing = false;
  isRecording = false;
  ghMutexCapturing = CreateMutex(NULL, FALSE, NULL);
  SetReadMode(4); // image
  SetImage(1, 1, 1, xpixels, 1, ypixels);
  ROI.x = 0;
  ROI.y = 0;
  ROI.w = xpixels;
  ROI.h = ypixels;
  if (xpixels > ypixels) {
    pixarraysize = xpixels;
  } else {
    pixarraysize = ypixels;
  }
  LastFrame = (CamFrame *)malloc(sizeof(CamFrame));
  hbin = 1;
  vbin = 1;
  bin = 1;
  buff32 =
      (int32_t *)malloc((long long)ROI.w * (long long)ROI.h * sizeof(int32_t));
  buff16 = (uint16_t *)malloc((long long)ROI.w * (long long)ROI.h *
                              sizeof(uint16_t));
  return;
}

double Andor_Cam::find_sensor_size() { return xpixels; }

bool Andor_Cam::set_arbitrary_roi(SDL_Rect ROItry) {
  unsigned int ermsg;
  ermsg = SetImage(1, 1, ROItry.x + 1, ROItry.w + ROItry.x, ROItry.y + 1,
                   ROItry.h + ROItry.y);
  ROI.x = ROItry.x;
  ROI.y = ROItry.y;
  ROI.w = ROItry.w;
  ROI.h = ROItry.h;
  return true;
}

void Andor_Cam::Set_Mode(int mode_id) {}

// aq_snap will return null pointer. Not implemented for Andor.
CamFrame *Andor_Cam::aq_snap() { return (CamFrame *)NULL; }

bool Andor_Cam::aq_live_restart() {
  // Function overload that just runs based on already defined values.
  return aq_live_restart(ROI, bin, exposureTimeSeconds);
}

bool Andor_Cam::aq_live_restart(SDL_Rect inputROI, int binning,
                                double exposureTime) {
  unsigned int ermsg;
  if (isCapturing) {
    WaitForSingleObject(ghMutexCapturing, INFINITE);
    isCapturing = false;
    ReleaseMutex(ghMutexCapturing);
    aq_live_stop();
  }
  hbin = (int)binning;
  vbin = (int)binning;
  ermsg = SetTriggerMode(0); // internal trig
  set_arbitrary_roi(inputROI);
  ermsg = SetShutter(1, 1, 0, 0);
  ermsg = SetAcquisitionMode(5);
  ermsg = SetExposureTime((float)exposureTime);
  exposureTimeSeconds = exposureTime;
  ermsg = StartAcquisition();
  WaitForSingleObject(ghMutexCapturing, INFINITE);
  isCapturing = true;
  ReleaseMutex(ghMutexCapturing);
  return true;
}
void Andor_Cam::aq_live_stop() {
  WaitForSingleObject(ghMutexCapturing, INFINITE);
  isCapturing = false;
  ReleaseMutex(ghMutexCapturing);
  AbortAcquisition();
}
CamFrame *Andor_Cam::aq_thread_snap() {
  unsigned int ermsg;
  ermsg = WaitForAcquisition();
  ermsg = GetMostRecentImage16(buff16, ROI.w * ROI.h);
  LastFrame->buf = buff16;
  LastFrame->height = ROI.h;
  LastFrame->width = ROI.w;
  LastFrame->top = ROI.y;
  LastFrame->left = ROI.x;
  return LastFrame;
}

// Prepare synchronous acquisition
bool Andor_Cam::aq_sync_prepare(SDL_Rect inputROI, int binning,
                                double exposureTime) {
  unsigned int ermsg;
  if (isCapturing) {
    aq_live_stop();
  }
  hbin = (int)binning;
  vbin = (int)binning;
  set_arbitrary_roi(inputROI);
  ermsg = SetAcquisitionMode(5);
  ermsg = SetExposureTime((float)exposureTime);
  ermsg = SetTriggerMode(6); // external trig
  return true;
}

// Start synchronous acquisition
bool Andor_Cam::aq_sync_start(int32 recordFrames, const char *fpath) {
  unsigned int ermsg;
  long acquired_count;
  WaitForSingleObject(ghMutexCapturing, INFINITE);
  isRecording = true;
  isCapturing = true;
  ReleaseMutex(ghMutexCapturing);
  ermsg = SetSpool(1, 2, (char *)fpath, (int)recordFrames);
  ermsg = StartAcquisition();
  do {
    ermsg = GetTotalNumberImagesAcquired(&acquired_count);
  } while (acquired_count < (long)recordFrames);
  aq_sync_stop();
  ermsg = SetSpool(0, 2, (char *)fpath, (int)recordFrames);
  aq_live_restart();
  return true;
}

// stop synchronous acquisition
void Andor_Cam::aq_sync_stop() {
  AbortAcquisition();
  WaitForSingleObject(ghMutexCapturing, INFINITE);
  isRecording = false;
  isCapturing = false;
  ReleaseMutex(ghMutexCapturing);
}

bool Andor_Cam::dc_shutdown(void) {
  unsigned int ermsg;
  AbortAcquisition();
  ermsg = SetShutter(1, 2, 0, 0);
  // ermsg=SetTemperature(25);
  ermsg = CoolerOFF(); // Put in temperature check loop.
  ermsg = ShutDown();
  free(buff16);
  free(buff32);
  return true;
}

#endif // ANDOR_CONFIGURED