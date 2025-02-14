#pragma once
#include "Cam_Control.h"

#ifdef KINETIX_CONFIGURED

#include "CommonPV.h"

#include "CamFrame.h"
#include <stdio.h>
#include "master.h"
#include "pvcam.h"
#include <iostream>
#include <mutex>
#define MAX_MSG_LEN 256

#define SENSOR_H 3200
#define SENSOR_W 3200

class Cam_Control;

class Kinetix_Cam : public Cam_Control {
public:
  Kinetix_Cam();
  CamFrame *aq_thread_snap(void);
  bool aq_live_restart();
  bool aq_live_restart(SDL_Rect inputROI, int binning, double exposureTime);
  bool aq_sync_prepare(SDL_Rect inputROI, int binning, double exposureTime);
  bool aq_sync_start(int32 recordFrames, const char *fpath);
  bool aq_sync_start_Fcn(int32 recordFrames,
                         const char *fpath); // new function
  void aq_sync_stop();
  bool dc_shutdown();
  void aq_live_stop();
  double find_sensor_size(); //  Sensor size hardcoded in Kinetix_Cam.cpp
  bool Set_Master(bool master); 

private:
  void pixel_filter_off();
  void output_pp_parameter_state();
  bool set_centered_roi(double hSizeTry, double vSizeTry);
  bool set_arbitrary_roi(double hPosTry, double hSizeTry, double vPosTry,
                         double vSizeTry);
  bool stream_data_to_file(const char *fpath, uns8 *circBufferPtr,
                           const uns32 circBufferSize, int totalFrames);
  static unsigned int __stdcall aq_sync_start_FcnWrapper(void *params);

  // variables
  std::vector<CameraContext *> contexts;
  CameraContext *cam_ctx = NULL;
  HANDLE changing_acquisition_params_MUTEX;
  HANDLE waitdonethread;
  unsigned waitdonethreadid;
  const uns16 circBufferFrames = 64;
  uns8 *liveCircBufferInMemory;
  const int16 bufferMode = CIRC_OVERWRITE;
  uns32 exposureBytes;


  // uns8 *circBufferInMemory;

  const int RAM_SIZE = 1.5e9; // in bytes
};
#endif // KINETIX_CONFIGURED
