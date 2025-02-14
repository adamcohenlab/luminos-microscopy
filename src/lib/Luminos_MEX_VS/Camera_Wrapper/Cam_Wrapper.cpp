#include "pch.h"
#include "framework.h"
#include "Cam_Wrapper.h"
#ifdef ANDOR_CONFIGURED
#include "Andor_Cam.h"
#endif

#ifdef HAMAMATSU_CONFIGURED
#include "Hamamatsu_Cam.h"
#endif

#ifdef KINETIX_CONFIGURED
#include "Kinetix_Cam.h"
#endif

#include "Cam_Emulator.h"
// Add any other specific camera implementations above.

// Defines general Camera Wrapper class that exposes camera functionality to the
// client under a consistent interface.
// Since the live SDisplay is not directly accessible to the client, this
// wrapper also exposes the necessary functionality of the SDisplay.

// Initialize new Cam_Wrapper of type denoted by <cam_type> (integer or constant
// defined in Cam_Wrapper.h).
//  camid can generally be an empty string, but if multiple cameras of the same
//  type are connected, it should be used to denote a particular camera by
//  serial number.
Cam_Wrapper::Cam_Wrapper(int cam_type, const char *camid)
    : SDisplay(), ROI(), cam(nullptr) {
  if (cam_type == TYPE_EMULATOR) {
    cam = new Cam_Emulator;
  } else if (cam_type == TYPE_HAMAMATSU) {
#ifdef HAMAMATSU_CONFIGURED
    if (camid == 0) {
      throw(std::invalid_argument("Null pointer passed as camid to Cam_Wrapper "
                                  "constructor. Expected valid char*"));
      return;
    }
    cam = new Hamamatsu_Cam(camid);
#else
    throw(std::invalid_argument(
        "Hamamatsu drivers not installed. Please install Hamamatsu drivers and "
        "recompile. See documentation for details."));
#endif
  } else if (cam_type == TYPE_ANDOR) {
#ifdef ANDOR_CONFIGURED

    // Can implement camid checking as above if multiple
    // Andor cameras need to be handled
    cam = new Andor_Cam();
#else
    throw(std::invalid_argument(
        "Andor drivers not installed. Please install Andor drivers and "
        "recompile. See documentation for details."));
#endif
  }

  else if (cam_type == TYPE_KINETIX) {
#ifdef KINETIX_CONFIGURED
    cam = new Kinetix_Cam();
#else
    throw(std::invalid_argument(
        "Kinetix drivers not installed. Please install Kinetix drivers and "
        "recompile. See documentation for details."));
#endif
  }

  else {
    throw(std::invalid_argument("Invalid Camera Type Code. Valid codes are "
                                "enumerated in Cam_Wrapper.h"));
    printf("Invalid camera type");
    return;
  }
  SDisplay.attach_camera(cam);      // attach camera to live display
  SDisplay.launch_disp_threads();   // start live display
  SDisplay.Launch_Handoff_Thread(); // start piping data to live display
  cam->aq_live_restart();           // start live acquisition
}

Cam_Wrapper::~Cam_Wrapper() {
  if (cam) {
    Cleanup();
  }
}

// stop the previous acquisition, set the parameters

// Prepare camera for triggered acquisition. Provide desired exposuretime (in
// seconds), ROI, and binning.
// ROI should be array of integers (units of pixels) as follows: [x, w, y, h];
void Cam_Wrapper::Prepare_Sync_Acquisition(double exposuretime, int32 *ROI_in,
                                           uint32_t binning) {
  ROI.x = *ROI_in;
  ROI.w = *(ROI_in + 1);
  ROI.y = *(ROI_in + 2);
  ROI.h = *(ROI_in + 3);
  cam->aq_live_restart(cam->ROI, binning, exposuretime);
  cam->aq_sync_prepare(ROI, binning, cam->exposureTimeSeconds);
  GetROI(ROI_in);
  ROI = cam->ROI;
}

/*
Start acquiring data

Arguments
- numframes: number of frames to acquire
- fpath: destination to save frames.

*/
bool Cam_Wrapper::Start_Acquisition(int32 numframes, const char *fpath) {
  return (cam->aq_sync_start(numframes, fpath));
}

// Use to restart camera from Matlab
bool Cam_Wrapper::aq_live_restart() {
  return (cam->aq_live_restart());
}

// Stop triggered acquisition
void Cam_Wrapper::Stop_Sync_Acquisition() { cam->aq_sync_stop(); }

// Stop live acquisition
void Cam_Wrapper::Stop_Live_Acquisition() { cam->aq_live_stop(); }

// Take single snapshot from streamed camera data. Client provides memory
// location *snapframe that is capable of storing <numpixels> uint16 elements
// into which snapshot is copied.
void Cam_Wrapper::GetSnap(uint16_t *snapframe, int numpixels) {
  WaitForSingleObject(SDisplay.HandoffMutex, INFINITE);
  memcpy(snapframe, SDisplay.lastImageData, numpixels * sizeof(uint16_t));
  ReleaseMutex(SDisplay.HandoffMutex);
}

// Set virtual R: drive mode of camera. True corresponds to streaming data to
// virtual drive in RAM (R:\\), false to streaming data to true storage drive.
void Cam_Wrapper::Set_RDrive_Mode(bool mode) { cam->rdrive_mode = mode; }

// Set camera readout mode (device specific significance)
void Cam_Wrapper::Set_Read_Mode(int mode) { cam->read_mode = mode; }

// Check if camera is currently recording
bool Cam_Wrapper::Is_Cam_Recording() { return ((bool)cam->isRecording); }

// Set exposure time of camera. Request exposure of exp_request (in seconds).
// Returns resulting exposure time (in seconds).
double Cam_Wrapper::Set_Exposure(double exp_request) {
  int32_t binning = Get_Binning();
  cam->aq_live_restart(cam->ROI, binning, exp_request);
  return ((double)cam->exposureTimeSeconds);
}

// Get current exposure time of camera (in seconds)
double Cam_Wrapper::Get_Exposure() {
  return ((double)cam->exposureTimeSeconds);
}

// Get ROI of camera: [x, w, y, h] in integer units of binned pixels
// (pixels/binning).
void Cam_Wrapper::GetROI(int32 *ROI) {
  *ROI = cam->ROI.x;
  *(ROI + 1) = cam->ROI.w;
  *(ROI + 2) = cam->ROI.y;
  *(ROI + 3) = cam->ROI.h;
}

// Set ROI of camera: [x, w, y, h] in integer units of binned pixels
// (pixels/binning). Returns boolean representing success (true) or failure
// (false) of ROI setting.
bool Cam_Wrapper::Set_ROI(int32 *ROI_in) {
  bool result;
  ROI.x = ROI_in[0];
  ROI.w = ROI_in[1];
  ROI.y = ROI_in[2];
  ROI.h = ROI_in[3];
  result = cam->aq_live_restart(ROI, cam->bin, cam->exposureTimeSeconds);
  GetROI(ROI_in);
  return result;
}

// Rotate camera stream clockwise 90 deg
int Cam_Wrapper::RotateCamFOV() {
  SDisplay.rotated = (SDisplay.rotated + 1) % 4;
  return SDisplay.rotated;
}

// Rotate camera stream counterclockwise 90 deg
int Cam_Wrapper::RotateCamFOVcounter() {
  SDisplay.rotated = (SDisplay.rotated - 1 + 4) % 4;
  return SDisplay.rotated;
}

// Flip camera stream horizontally
bool Cam_Wrapper::FlipCamFOV() {
  SDisplay.flipped = !SDisplay.flipped;
  return SDisplay.flipped;
}


// Set binning mode. Also adjusts ROI to compensate for new binning.
bool Cam_Wrapper::Set_Binning(uint32_t binning) {
  bool result;
  ROI.x = cam->ROI.x;
  ROI.w = cam->ROI.w;
  ROI.y = cam->ROI.y;
  ROI.h = cam->ROI.h;
  result = cam->aq_live_restart(ROI, binning, cam->exposureTimeSeconds);
  return result;
}

// Set magnification from Main tab objectives and tubelenses panel.
// Use to calculate distances in steam using contour.
bool Cam_Wrapper::Set_Magnification(double magnification) {
  bool result = 0;
  char mag[64];
  sprintf(mag, "%f", magnification);
  printf(mag);
  StreamDisplayHD::Px_to_um = magnification;
  result = 1;
  return result;
}


bool Cam_Wrapper::Set_Master(bool master_in) {
  cam->master = master_in;
  return true;
}

// Return current binning
double Cam_Wrapper::Get_Binning() { return ((double)cam->bin);
}

// Returns size of available data in the roi_buff that collects ROI mean data.
// This roi is the SDisplay sum_rect ROI, which may not correspond to the camera
// ROI.
int Cam_Wrapper::ROI_Buff_Avail() { return (int)SDisplay.roi_buff.size(); }

// Returns size of available data in the roi_sum_buff that collects ROI sum
// data. This roi is the SDisplay ROI, which may not correspond to the camera
// ROI.
int Cam_Wrapper::ROI_Sum_Buff_Avail() {
  return (int)SDisplay.roi_sum_buff.size();
}

// Get coordinates of display sum_rect ROI used to collect intensity trace data.
// [x,w,y,h] (pixels) will be saved in provided memory location.
void Cam_Wrapper::GetSumRect(int32 *ROI) {
  *ROI = SDisplay.sum_rect.x;
  *(ROI + 1) = SDisplay.sum_rect.w;
  *(ROI + 2) = SDisplay.sum_rect.y;
  *(ROI + 3) = SDisplay.sum_rect.h;
}

// Copy <samps> oldest samples from sum_rect roi mean buffer to *dataout. Return
// value is true if data has been overwritten (circular buffer is full)
bool Cam_Wrapper::Get_ROI_Buffer(double *dataout, int samps) {
  bool dloss = SDisplay.roi_buff.full();
  WaitForSingleObject(SDisplay.roidatamutex, INFINITE);
  for (int i = 0; i < samps; i++) {
    *(dataout + i) = SDisplay.roi_buff.get();
  }
  ReleaseMutex(SDisplay.roidatamutex);
  return dloss;
}

// Copy <samps> oldest samples from sum_rect roi sum buffer to *dataout. Return
// value is true if data has been overwritten (circular buffer is full).
bool Cam_Wrapper::Get_ROI_Sum_Buffer(double *dataout, int samps) {
  bool dloss = SDisplay.roi_sum_buff.full();
  WaitForSingleObject(SDisplay.roidatamutex, INFINITE);
  for (int i = 0; i < samps; i++) {
    *(dataout + i) = SDisplay.roi_sum_buff.get();
  }
  ReleaseMutex(SDisplay.roidatamutex);
  return dloss;
}

// Check number of elements in contour storage buffer. REMOVE?
int Cam_Wrapper::Get_Contour_numel() { return SDisplay.contour_numel; }

// Check if new contour data is ready to read. REMOVE?
bool Cam_Wrapper::Contour_Data_Ready() { return SDisplay.newcontstore; }

// Copy <len> elements from the SDisplay contour buffer into *dataout. REMOVE?
bool Cam_Wrapper::Get_Contour_Data(double *dataout, int len) {
  bool freshdata = SDisplay.newcontstore;
  WaitForSingleObject(SDisplay.contourstoremutex, INFINITE);
  memcpy(dataout, SDisplay.contour_store, len * sizeof(double));
  SDisplay.newcontstore = false;
  ReleaseMutex(SDisplay.contourstoremutex);
  return freshdata;
}

// Clean up necessary things before deletion (stop capture, cleanup display,
// shutdown camera, and delete object)
void Cam_Wrapper::Cleanup() {
  if (cam->isCapturing) {
    cam->isCapturing = false;
    cam->aq_live_stop();
  }
  SDisplay.cleanup();
  cam->dc_shutdown();
  //delete cam;
}

int Cam_Wrapper::Check_for_ROI() { return SDisplay.ROI_click_toggle; }

// Return number of dropped frames (frames that were not streamed to storage in
// time and were overwritten in buffer)
int Cam_Wrapper::Dropped_Frame_Check() { return (cam->dropped_frame_count); }

// Is previously prepared acquisition done?
int Cam_Wrapper::Acq_Done_Check() { return (cam->acq_done); }

// Set display colormap thresholds (0 to 1)
void Cam_Wrapper::Set_Cmap_Thresholds(double cmap_low_val,
                                      double cmap_high_val) {
  SDisplay.cmap_high = cmap_high_val;
  SDisplay.cmap_low = cmap_low_val;
}
