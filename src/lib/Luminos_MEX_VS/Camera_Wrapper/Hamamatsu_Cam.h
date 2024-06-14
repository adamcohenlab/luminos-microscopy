#pragma once
#define MAX_MSG_LEN 256
#include "Cam_Control.h"
#include "dcimgapi.h"
#include "dcimg2bin.h"
#include "Hamamatsu_console4.h"
#include "../inc/custom/dcamsdk4/samples/cpp/misc/common.h"
#include <wchar.h>
#define STREQHD(x, y) !(std::strcmp(x, y))
class Cam_Control;

unsigned convertThreadFcn(void *pArguments);
unsigned waitdonefunction(void *pArguments);
#pragma message("Need to be defined")
class Hamamatsu_Cam : public Cam_Control {
public:
  Hamamatsu_Cam();
  Hamamatsu_Cam(const char *camid);
  bool dc_wait_buffer_open(int32 bufferFrames);
  bool dc_record_open_attach(int32 recordFrames, const char *fpath);
  double get_property(const char idtxt[], int32 IDPROP);
  bool set_property(const char idtxt[], int32 IDPROP, double value);
  double find_sensor_size(void);
  void aq_sync_stop();
  void aq_live_stop();
  bool aq_sync_prepare(SDL_Rect inputROI, int binning, double exposureTime);
  bool aq_sync_start(int32 recordFrames, const char *fpath);
  bool dc_shutdown(void);
  bool aq_live_restart(SDL_Rect inputROI, int binning, double exposureTime);
  bool aq_live_restart();
  CamFrame *aq_snap(void);
  CamFrame *aq_thread_snap(void);
  DCAMWAIT_OPEN waitopen;
  bool isDevOpen;
  bool isWaitAndBufferOpen;
  double readoutTimeSeconds;
  int32 exposureTimeMilliseconds_ceil, readoutTimeMilliseconds_ceil;
  HANDLE ghMutexCapturing;
  HANDLE waitdonethread;
  char *rm_dup_slashes(const char *path, char *curr);
  char fpath_dcimg_copy[MAX_MSG_LEN];
  char fext_dcimg_copy[MAX_MSG_LEN];
  char fpath_bin_temp_copy[MAX_MSG_LEN];
  char fext_bin_temp_copy[MAX_MSG_LEN];
  char fpath_bin_tgt_copy[MAX_MSG_LEN];
  char fext_bin_tgt_copy[MAX_MSG_LEN];
  wchar_t wide_recopen_path[MAX_MSG_LEN];
  HDCAM hdcam;
  HDCAMREC hrec;
  int32 requestedframes;
  unsigned waitdonethreadid;

private:
  bool set_centered_roi(SDL_Rect ROItry);
  bool set_arbitrary_roi(SDL_Rect ROItry);
  bool set_subarray();
  bool verboseFlag = true;
  int32 hSensorSize, vSensorSize;
  HANDLE hConvertThread;
  char msg[MAX_MSG_LEN];
  HDCAMWAIT hwait;
  DCAMERR err;
  bool set_hsynctrigger();
};

void show_recording_status(HDCAM hdcam, HDCAMREC hrec);
HDCAM hd_dcamcon_init_open(const char *camid_requested);