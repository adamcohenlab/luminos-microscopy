#include "pch.h"
#include "Cam_Wrapper.h"
#ifdef HAMAMATSU_CONFIGURED
#include "Hamamatsu_Cam.h"
#include <stdexcept>

// no argument wrapper for constructor
Hamamatsu_Cam::Hamamatsu_Cam() { Hamamatsu_Cam("\0"); }

// Implements communication with Hamamatsu scientific CMOS cameras. camid can be
// used to specify the serial # of the camera if multiple cameras are present on
// a system. Otherwise it can be an empty string. The free DcamAPI library is
// required to be installed on your system. See https://dcam-api.com/
Hamamatsu_Cam::Hamamatsu_Cam(const char *camid)
    : waitopen(), isDevOpen(false), isWaitAndBufferOpen(false),
      readoutTimeSeconds(), exposureTimeMilliseconds_ceil(),
      readoutTimeMilliseconds_ceil(), ghMutexCapturing(), hdcam(NULL),
      hwait(NULL), err(), verboseFlag(true), hrec(NULL), hSensorSize(),
      vSensorSize(), hConvertThread(), fpath_dcimg_copy(), fext_dcimg_copy(),
      fpath_bin_temp_copy(), fext_bin_temp_copy(), fpath_bin_tgt_copy(),
      fext_bin_tgt_copy(), msg(), requestedframes(), waitdonethread(),
      waitdonethreadid(), wide_recopen_path() {
  read_mode = 0; // 0 gives External start trigger mode. 1 gives external
                 // synchronous trigger mode (one frame per trigger)
  exposureTimeSeconds = .15;
  snprintf(fpath_bin_temp_copy, MAX_MSG_LEN, "R:\\temp");
  snprintf(fext_bin_temp_copy, MAX_MSG_LEN, "bin");
  snprintf(fext_dcimg_copy, MAX_MSG_LEN, "dcimg");
  rdrive_mode =
      true; // if true, data will be streamed to virtual "R://" drive in RAM.
            // Use a 3rd-party program such as ImDisk to set up this RAMDrive
  //(https://en.wikipedia.org/wiki/List_of_RAM_drive_software)
  acq_done = 0;
  dropped_frame_count = 0;
  const char *fpath_bin_tgt_copy = (const char *)malloc(512 * sizeof(char));
  isCapturing = false;
  isRecording = false;
  ghMutexCapturing = CreateMutex(NULL, FALSE, NULL);
  bin = 1;
  LastFrame = (CamFrame *)malloc(sizeof(CamFrame));
  if (isDevOpen) {
    printf("device already open\n");
  } else {
    // initialize DCAM-API and open device
    hdcam = hd_dcamcon_init_open(camid);
    if (!hdcam) { // failed open DCAM handle
      throw(std::runtime_error(
          "dcamcon_init_open returned NULL pointer. Is the camera on? Is the "
          "camid valid?\n Try rebuilding libs or restart MATLAB. \n"));
      return;
    }
    printf("dcamcon_init_open ok\n");
    isDevOpen = true;
    // show device information
    dcamcon_show_dcamdev_info(hdcam);
  }
  pixarraysize = (int)find_sensor_size();
  ROI.x = 0;
  ROI.y = 0;
  ROI.w = pixarraysize;
  ROI.h = pixarraysize;
  set_hsynctrigger();
  return;
}

// Open dcam buffer and 'wait' object used for camera state signalling.
bool Hamamatsu_Cam::dc_wait_buffer_open(int32 bufferFrames) {
  if (isDevOpen) {
    // open wait handle
    memset(&waitopen, 0, sizeof(waitopen));
    waitopen.size = sizeof(waitopen);
    waitopen.hdcam = hdcam;

    err = dcamwait_open(&waitopen);
    if (failed(err)) {
      dcamcon_show_dcamerr(hdcam, err, "dcamwait_open()", NULL);
    } else {
      printf("wait open\n");
      hwait = waitopen.hwait;

      // allocate buffer
      err = dcambuf_alloc(hdcam, bufferFrames);
      if (failed(err)) {
        dcamcon_show_dcamerr(hdcam, err, "dcambuf_alloc()", NULL);
      } else {
        printf("buffer allocated\n");
        return true;
      }
    }
  } else {
    printf("no camera open\n");
  }
  return false;
}

//
bool Hamamatsu_Cam::dc_record_open_attach(int32 recordFrames,
                                          const char *fpath) {
  if (isWaitAndBufferOpen) {
    strcpy(fpath_bin_tgt_copy, fpath);
    DCAMREC_OPEN recopen;
    // create file
    memset(&recopen, 0, sizeof(recopen));
    recopen.size = sizeof(recopen);
    // if true, data will be streamed to virtual "R://" drive in
    // RAM. Use a 3rd-party program such as ImDisk to set up this
    // RAMDrive
    //(https://en.wikipedia.org/wiki/List_of_RAM_drive_software)
    if (rdrive_mode) {
      snprintf(fpath_dcimg_copy, MAX_MSG_LEN, "R:\\tempdc");
      recopen.path = _T("R:\\tempdc"); // it should set new file name.
    }
    // Otherwise, stream to location on disk
    else {
      snprintf(fpath_dcimg_copy, MAX_MSG_LEN, fpath);
      mbstowcs(wide_recopen_path, fpath_bin_tgt_copy, MAX_MSG_LEN);
      recopen.path = wide_recopen_path;
    }
    recopen.ext = _T("dcimg");
    recopen.maxframepersession = recordFrames;

    err = dcamrec_open(&recopen);
    if (failed(err)) {
      dcamcon_show_dcamerr(hdcam, err, "dcamrec_open()", NULL);
    } else {
      printf("record open\n");
      hrec = recopen.hrec;

      // attach recording handle to DCAM handle
      err = dcamcap_record(hdcam, hrec);
      if (failed(err)) {
        dcamcon_show_dcamerr(hdcam, err, "dcamcap_record()", NULL);
      } else {
        printf("record attached\n");
        return true;
      }
    }
  } else {
    printf("buffer not allocated\n");
  }
  return false;
}

// Query property of Hamamatsu camera by property ID. See dcamapi.h for
// definitions (installed with dcamapi: https://dcam-api.com/)
double Hamamatsu_Cam::get_property(const char idtxt[], int32 IDPROP) {
  if (isDevOpen) {
    sprintf(msg, "get property %s ", idtxt);
    printf(msg);
    double value;
    err = dcamprop_getvalue(hdcam, IDPROP, &value);
    if (failed(err)) {
      dcamcon_show_dcamerr(hdcam, err, "dcamprop_getvalue()", NULL);
      return -1;
    } else {
      sprintf(msg, "returned value %g\n", value);
      return value;
    }
  } else {
    printf("no camera open\n");
  }
  return -1;
}

// Set property of Hamamatsu camera by property ID
bool Hamamatsu_Cam::set_property(const char idtxt[], int32 IDPROP,
                                 double value) {
  if (isDevOpen) {
    sprintf(msg, "set property %s with value %g\n", idtxt, value);
    err = dcamprop_setvalue(hdcam, IDPROP, value);
    if (failed(err)) {
      dcamcon_show_dcamerr(hdcam, err, "dcamprop_setvalue()", NULL);
      get_property(idtxt, IDPROP);
      return false;
    }
  } else {
    printf("no camera open\n");
  }
  return true;
}

// get camera sensor size
double Hamamatsu_Cam::find_sensor_size(void) {
  int value = 2048;
  if (isCapturing) {
    aq_live_stop();
  }
  set_property("SUBARRAYMODE, ON", DCAM_IDPROP_SUBARRAYMODE, DCAMPROP_MODE__ON);
  set_property("SUBARRAYHPOS", DCAM_IDPROP_SUBARRAYHPOS, 0);
  set_property("SUBARRAYHSIZE", DCAM_IDPROP_SUBARRAYHSIZE, 2048);
  set_property("SUBARRAYHSIZE", DCAM_IDPROP_SUBARRAYHSIZE, 2304);
  value = (int)get_property("SUBARRAYHSIZE", DCAM_IDPROP_SUBARRAYHSIZE);
  return value;
}

// Set ROI (subarray) position
bool Hamamatsu_Cam::set_subarray() {
  if (!isDevOpen) {
    printf("no camera open\n");
    return false;
  }
  set_property("SUBARRAYMODE, OFF", DCAM_IDPROP_SUBARRAYMODE,
               DCAMPROP_MODE__OFF);
  set_property("SUBARRAYHPOS", DCAM_IDPROP_SUBARRAYHPOS, ROI.x);
  set_property("SUBARRAYHSIZE", DCAM_IDPROP_SUBARRAYHSIZE, ROI.w);
  set_property("SUBARRAYVPOS", DCAM_IDPROP_SUBARRAYVPOS, ROI.y);
  set_property("SUBARRAYVSIZE", DCAM_IDPROP_SUBARRAYVSIZE, ROI.h);
  set_property("SUBARRAYMODE, ON", DCAM_IDPROP_SUBARRAYMODE, DCAMPROP_MODE__ON);
  return true;
}

// calculate and set centered ROI (equal rows above and below center). This
// gives optimal readout speed.
bool Hamamatsu_Cam::set_centered_roi(SDL_Rect ROItry) {
  if (!isDevOpen) {
    printf("no camera open\n");
    return false;
  }
  ROI.w = (int)round(ROItry.w / 8.0) * 8;
  ROI.h = (int)round(ROItry.h / 8.0) * 8;
  if (ROI.w != ROItry.w) {
    sprintf(msg, "rounding hSize from %d to %d\n", ROItry.w, ROI.w);
  }
  if (ROI.h != ROItry.h) {
    sprintf(msg, "rounding vSize from %d to %d\n", ROItry.h, ROI.h);
  }
  ROI.x = (pixarraysize - ROI.w) / 2;
  ROI.y = (pixarraysize - ROI.h) / 2;
  set_subarray();
  return true;
}

// Calculate and set arbitrary ROI
bool Hamamatsu_Cam::set_arbitrary_roi(SDL_Rect ROItry) {
  if (!isDevOpen) {
    printf("no camera open\n");
    return false;
  }
  ROI.w = (int)round(ROItry.w / 4.0) * 4;
  ROI.w = (int)fmax(ROI.w, 4);
  ROI.w = (int)fmin(ROI.w, pixarraysize);
  ROI.h = (int)round(ROItry.h / 4.0) * 4;
  ROI.h = (int)fmax(ROI.h, 4);
  ROI.h = (int)fmin(ROI.h, pixarraysize);
  if (ROI.w != ROItry.w) {
    sprintf(msg, "rounding hSize from %d to %d\n", ROItry.w, ROI.w);
    printf(msg);
  }
  if (ROI.h != ROItry.h) {
    sprintf(msg, "rounding vSize from %d to %d\n", ROItry.h, ROI.h);
    printf(msg);
  }
  ROI.x = (int)round(ROItry.x / 4.0) * 4;
  ROI.x = (int)fmax(ROI.x, 0);
  ROI.x = (int)fmin(ROI.x, pixarraysize - ROI.w);
  ROI.y = (int)round(ROItry.y / 4.0) * 4;
  ROI.y = (int)fmax(ROI.y, 0);
  ROI.y = (int)fmin(ROI.y, pixarraysize - ROI.h);
  if (ROI.x != ROItry.x) {
    sprintf(msg, "rounding hPos from %d to %d\n", ROItry.x, ROI.x);
    printf(msg);
  }
  if (ROI.y != ROItry.y) {
    sprintf(msg, "rounding vPos from %d to %d\n", ROItry.y, ROI.y);
    printf(msg);
  }
  set_subarray();
  return true;
}

// Configure hsync and vsync output signals
bool Hamamatsu_Cam::set_hsynctrigger() {
  if (!isDevOpen) {
    printf("no camera open\n");
    return false;
  }
  // First output trigger = Positive polarity 0 delay, 2us pulse width triggered
  // from Hsync signal (row readout start = 100kHz clock)
  set_property("OUTPUTTRIGGER_KIND, PROGRAMABLE",
               DCAM_IDPROP_OUTPUTTRIGGER_KIND,
               DCAMPROP_OUTPUTTRIGGER_KIND__PROGRAMABLE);
  set_property("OUTPUTTRIGGER_POLARITY, POSITIVE",
               DCAM_IDPROP_OUTPUTTRIGGER_POLARITY,
               DCAMPROP_OUTPUTTRIGGER_POLARITY__POSITIVE);
  set_property("OUTPUTTRIGGER_SOURCE, HSYNC", DCAM_IDPROP_OUTPUTTRIGGER_SOURCE,
               DCAMPROP_OUTPUTTRIGGER_SOURCE__HSYNC);
  set_property("OUTPUTTRIGGER_DELAY", DCAM_IDPROP_OUTPUTTRIGGER_DELAY, 0);
  set_property("OUTPUTTRIGGER_PERIOD", DCAM_IDPROP_OUTPUTTRIGGER_PERIOD, 2e-6);
  double val =
      get_property("OUTPUTTRIGGER_SOURCE", DCAM_IDPROP_OUTPUTTRIGGER_SOURCE);

  // Second output trigger (DCAM_IDPROP__OUTPUTTRIGGER gives offset of second
  // trigger relative to first): Positive Polarity 0 delay, 2us pulse width
  // triggered from Vsync (frame readout start = center row exposure end)
  set_property("OUTPUTTRIGGER_KIND, PROGRAMABLE",
               DCAM_IDPROP_OUTPUTTRIGGER_KIND + DCAM_IDPROP__OUTPUTTRIGGER,
               DCAMPROP_OUTPUTTRIGGER_KIND__PROGRAMABLE);
  set_property("OUTPUTTRIGGER_POLARITY, POSITIVE",
               DCAM_IDPROP_OUTPUTTRIGGER_POLARITY + DCAM_IDPROP__OUTPUTTRIGGER,
               DCAMPROP_OUTPUTTRIGGER_POLARITY__POSITIVE);
  set_property("OUTPUTTRIGGER_SOURCE, VSYNC",
               DCAM_IDPROP_OUTPUTTRIGGER_SOURCE + DCAM_IDPROP__OUTPUTTRIGGER,
               DCAMPROP_OUTPUTTRIGGER_SOURCE__VSYNC);
  set_property("OUTPUTTRIGGER_DELAY",
               DCAM_IDPROP_OUTPUTTRIGGER_DELAY + DCAM_IDPROP__OUTPUTTRIGGER, 0);
  set_property("OUTPUTTRIGGER_PERIOD",
               DCAM_IDPROP_OUTPUTTRIGGER_PERIOD + DCAM_IDPROP__OUTPUTTRIGGER,
               2e-6);

  return true;
}

// Stop synchronous acquisition
void Hamamatsu_Cam::aq_sync_stop() {
  if (isCapturing) {
    WaitForSingleObject(ghMutexCapturing, INFINITE);
    isCapturing = false;
    ReleaseMutex(ghMutexCapturing);
    dcamcap_stop(hdcam);
    printf("capture stopped\n");
  } else {
    printf("capture already stopped\n");
  }
  if (isRecording) {
    dcamrec_close(hrec);
    unsigned int threadID;
    hConvertThread = (HANDLE)_beginthreadex(NULL, 0, &convertThreadFcn,
                                            (void *)this, 0, &threadID);
    printf("converting file in background\n");
    printf("record closed\n");
    isRecording = false;
  } else {
    printf("record already stopped\n");
  }
  if (isWaitAndBufferOpen) {
    dcambuf_release(hdcam);
    printf("buffer released\n");
    dcamwait_close(hwait);
    printf("wait closed\n");
    isWaitAndBufferOpen = false;
  } else {
    printf("wait and buffer already closed\n");
  }
}

// Stop live acquisition

void Hamamatsu_Cam::aq_live_stop() {
  if (isCapturing) {
    WaitForSingleObject(ghMutexCapturing, INFINITE);
    isCapturing = false;
    ReleaseMutex(ghMutexCapturing);
    dcamcap_stop(hdcam);
    printf("capture stopped\n");
    // lastBufferFrame = NULL;
  } else {
    printf("capture already stopped\n");
  }

  if (isWaitAndBufferOpen) {
    dcambuf_release(hdcam);
    printf("buffer released\n");
    dcamwait_close(hwait);
    printf("wait closed\n");
    isWaitAndBufferOpen = false;
  } else {
    printf("wait and buffer already closed\n");
  }
}

// Prepare synchronous acquisition
bool Hamamatsu_Cam::aq_sync_prepare(SDL_Rect inputROI, int binning,
                                    double exposureTime) {
  if (isDevOpen) {
    if (isCapturing) {
      // need to stop capturing
      if (isRecording) {
        // synchronized recording to disk
        aq_sync_stop();
      } else {
        // live imaging
        aq_live_stop();
      } // both cases will have set isWaitAndBufferOpen to false also
    } else {
      // no need to stop capturing
    }
    // here assume capturing is stopped
    // set sync imaging parameters
    bin = binning;
    acq_done = 0;
    set_property("BINNING", DCAM_IDPROP_BINNING, binning);
    set_arbitrary_roi(inputROI);
    set_property("READOUTSPEED, FASTEST", DCAM_IDPROP_READOUTSPEED,
                 DCAMPROP_READOUTSPEED__FASTEST);
    if (read_mode == 0) { // External Start trigger mode
      set_property("TRIGGER_MODE, START", DCAM_IDPROP_TRIGGER_MODE,
                   DCAMPROP_TRIGGER_MODE__START);
      set_property("TRIGGERSOURCE, EXTERNAL", DCAM_IDPROP_TRIGGERSOURCE,
                   DCAMPROP_TRIGGERSOURCE__EXTERNAL);
      set_property("TRIGGERACTIVE, EDGE", DCAM_IDPROP_TRIGGERACTIVE,
                   DCAMPROP_TRIGGERACTIVE__EDGE);
      set_property("EXPOSURETIME", DCAM_IDPROP_EXPOSURETIME, exposureTime);
    } else { // External synchronous trigger mode (one frame per trigger)
      set_property("TRIGGER_MODE, NORMAL", DCAM_IDPROP_TRIGGER_MODE,
                   DCAMPROP_TRIGGER_MODE__NORMAL);
      set_property("TRIGGERSOURCE, EXTERNAL", DCAM_IDPROP_TRIGGERSOURCE,
                   DCAMPROP_TRIGGERSOURCE__EXTERNAL);
      set_property("TRIGGERACTIVE, SYNCREADOUT", DCAM_IDPROP_TRIGGERACTIVE,
                   DCAMPROP_TRIGGERACTIVE__SYNCREADOUT);
    }
    set_property("TRIGGER_CONNECTOR, BNC", DCAM_IDPROP_TRIGGER_CONNECTOR,
                 DCAMPROP_TRIGGER_CONNECTOR__BNC);
    set_property("TRIGGERPOLARITY, POSITIVE", DCAM_IDPROP_TRIGGERPOLARITY,
                 DCAMPROP_TRIGGERPOLARITY__POSITIVE);
    set_hsynctrigger();
    double result;
    result = get_property("EXPOSURETIME", DCAM_IDPROP_EXPOSURETIME);
    exposureTimeSeconds = result;
    exposureTimeMilliseconds_ceil = (int)ceil(exposureTimeSeconds * 1e3);
    result = get_property("TIMING_READOUTTIME", DCAM_IDPROP_TIMING_READOUTTIME);
    readoutTimeSeconds = result;
    readoutTimeMilliseconds_ceil = (int)ceil(readoutTimeSeconds * 1e3);

    int result_i;
    result_i = get_property("BINNING",DCAM_IDPROP_BINNING);
    bin = result_i;
  } else {
    printf("no camera open\n");
  }
  return false;
}

// Print recording status information to stdout for debugging purposes
void show_recording_status(HDCAM hdcam, HDCAMREC hrec) {
  DCAMERR err;
  // get recording status
  DCAMREC_STATUS recstatus;
  memset(&recstatus, 0, sizeof(recstatus));
  recstatus.size = sizeof(recstatus);
  err = dcamrec_status(hrec, &recstatus);
  if (failed(err)) {
    dcamcon_show_dcamerr(hdcam, err, "dcamrec_status()", NULL);
  } else {
    printf("flags: 0x%08x, latest index: %06d, miss: 0x%06d, total: %d\n",
           recstatus.flags, recstatus.currentframe_index,
           recstatus.missingframe_count, recstatus.totalframecount);
  }
}

// Start synchronous acquisition
bool Hamamatsu_Cam::aq_sync_start(int32 recordFrames, const char *fpath) {
  if (isDevOpen) {
    if (isCapturing) {
      // need to stop capturing
      if (isRecording) {
        // synchronized recording to disk
        aq_sync_stop();
      } else {
        // live imaging
        aq_live_stop();
      } // both cases will have set isWaitAndBufferOpen to false also
    } else {
      // no need to stop capturing
    }
    if (!isWaitAndBufferOpen) {
      int32 bufferFrames = 50;
      isWaitAndBufferOpen = dc_wait_buffer_open(bufferFrames);
      if (!isRecording) {
        isRecording = dc_record_open_attach(recordFrames, fpath);
        if (!isCapturing) {
          err = dcamcap_start(hdcam, DCAMCAP_START_SEQUENCE);
          if (failed(err)) {
            dcamcon_show_dcamerr(hdcam, err, "dcamcap_start()", NULL);
          } else {
            printf("capture started\n");
            requestedframes = recordFrames;
            WaitForSingleObject(ghMutexCapturing, INFINITE);
            isCapturing = true;
            ReleaseMutex(ghMutexCapturing);
            // start thread to wait for acquisition to finish
            waitdonethread = (HANDLE)_beginthreadex(
                NULL, (unsigned int)1e8, &waitdonefunction, (void *)this, 0,
                &waitdonethreadid);
            return true;
          }
        } else {
          printf("capture is already started\n");
        }
      } else {
        printf("record is already open\n");
      }
    } else {
      printf("wait and buffer are already open\n");
    }
  } else {
    printf("no camera open\n");
  }
  return false;
}

// shutdown camera and cleanup.
bool Hamamatsu_Cam::dc_shutdown(void) {
  if (isDevOpen) {
    if (isCapturing) {
      // need to stop capturing
      if (isRecording) {
        // synchronized recording to disk
        aq_sync_stop();

        unsigned int threadID;
        hConvertThread = (HANDLE)_beginthreadex(NULL, 0, &convertThreadFcn,
                                                (void *)this, 0, &threadID);

        printf("converting file in background\n%s.%s\n", fpath_dcimg_copy,
               fext_dcimg_copy);
        // printf(msg);
      } else {
        // live imaging
        aq_live_stop();
      } // both cases will have set isWaitAndBufferOpen to false also
    } else {
      // no need to stop capturing
    }
    dcamdev_close(hdcam);
    printf("dcamdev_close ok\n");
    // finalize DCAM-API
    dcamapi_uninit();
    printf("dcamapi_uninit ok\n");
    isDevOpen = false;
    return true;
  } else {
    printf("no camera open\n");
  }
  return false;
}

bool Hamamatsu_Cam::aq_live_restart() {
  // Function overload that just runs based on already defined values.
  return aq_live_restart(ROI, bin, exposureTimeSeconds);
}

// Restart live acquisition with given ROI, binning, exposureTime (s)
bool Hamamatsu_Cam::aq_live_restart(SDL_Rect inputROI, int binning,
                                    double exposureTime) {
  static DCAMERR err;
  if (isDevOpen) {
    if (isCapturing) {
      // need to stop capturing
      if (isRecording) {
        // synchronized recording to disk
        aq_sync_stop();
      } else {
        // live imaging
        aq_live_stop();
      } // both cases will have set isWaitAndBufferOpen to false also
    } else {
      // no need to stop capturing
    }
    // here assume capturing is stopped
    // set live imaging parameters
    bin = binning;
    set_property("BINNING", DCAM_IDPROP_BINNING, binning);
    set_arbitrary_roi(inputROI);
    set_property("READOUTSPEED, FASTEST", DCAM_IDPROP_READOUTSPEED,
                 DCAMPROP_READOUTSPEED__FASTEST);
    set_property("TRIGGER_MODE, NORMAL", DCAM_IDPROP_TRIGGER_MODE,
                 DCAMPROP_TRIGGER_MODE__NORMAL);
    set_property("TRIGGERSOURCE, INTERNAL", DCAM_IDPROP_TRIGGERSOURCE,
                 DCAMPROP_TRIGGERSOURCE__INTERNAL);
    set_property("EXPOSURETIME", DCAM_IDPROP_EXPOSURETIME, exposureTime);
    double result;
    result = get_property("EXPOSURETIME", DCAM_IDPROP_EXPOSURETIME);
    exposureTimeSeconds = result;
    exposureTimeMilliseconds_ceil = (int)ceil(exposureTimeSeconds * 1e3);
    result = get_property("TIMING_READOUTTIME", DCAM_IDPROP_TIMING_READOUTTIME);
    readoutTimeSeconds = result;
    readoutTimeMilliseconds_ceil = (int)ceil(readoutTimeSeconds * 1e3);

    int result_i;
    result_i = get_property("BINNING", DCAM_IDPROP_BINNING);
    bin = result_i;
    // start aq: wait and buffer, no recording, start camera
    if (!isWaitAndBufferOpen) {
      int32 bufferFrames = 50;
      isWaitAndBufferOpen = dc_wait_buffer_open(bufferFrames);

      if (!isCapturing) {
        err = dcamcap_start(hdcam, DCAMCAP_START_SEQUENCE);
        if (failed(err)) {
          dcamcon_show_dcamerr(hdcam, err, "dcamcap_start()", NULL);
        } else {
          printf("capture started\n");
          WaitForSingleObject(ghMutexCapturing, INFINITE);
          isCapturing = true;
          ReleaseMutex(ghMutexCapturing);
          return true;
        }
      } else {
        printf("capture is already started\n");
      }
    } else {
      printf("wait and buffer are already open\n");
    }
  } else {
    printf("no camera open\n");
  }
  return false;
}

// Acquire snapshot image
CamFrame *Hamamatsu_Cam::aq_snap() {
  if (isCapturing) {
    int32 nFrame = 1;
    // wait start param
    static DCAMWAIT_START waitstart;
    memset(&waitstart, 0, sizeof(waitstart));
    waitstart.size = sizeof(waitstart);
    waitstart.eventmask = DCAMWAIT_CAPEVENT_FRAMEREADY;
    waitstart.timeout = exposureTimeMilliseconds_ceil +
                        readoutTimeMilliseconds_ceil; // milliseconds
    // prepare frame param
    static DCAMBUF_FRAME bufframe;
    memset(&bufframe, 0, sizeof(bufframe));
    bufframe.size = sizeof(bufframe);
    bufframe.iFrame = -1; // latest captured image
    DCAMERR err;
    // wait image
    err = dcamwait_start(hwait, &waitstart);
    if (failed(err)) {
      dcamcon_show_dcamerr(hdcam, err, "dcamwait_start()", NULL);
      return NULL;
    }
    printf("wait started\n");
    // access image
    err = dcambuf_lockframe(hdcam, &bufframe);
    if (failed(err)) {
      dcamcon_show_dcamerr(hdcam, err, "dcambuf_lockframe()", NULL);
      return NULL;
    }
    printf("frame locked\n");
    LastFrame->buf = bufframe.buf;
    LastFrame->height = bufframe.height;
    LastFrame->width = bufframe.width;
    LastFrame->top = bufframe.top;
    LastFrame->left = bufframe.left;
    return LastFrame;
  } else {
    printf("camera is not capturing\n");
  }
  return NULL;
}

// Extract single frame while camera is performing acquisition
CamFrame *Hamamatsu_Cam::aq_thread_snap() {
  // if (isCapturing){ // camera is always capturing when this function is
  // called
  int32 nFrame = 1;

  // wait start param
  DCAMWAIT_START waitstart;
  memset(&waitstart, 0, sizeof(waitstart));
  waitstart.size = sizeof(waitstart);
  waitstart.eventmask = DCAMWAIT_CAPEVENT_FRAMEREADY;
  waitstart.timeout = 2 * (exposureTimeMilliseconds_ceil +
                           readoutTimeMilliseconds_ceil); // milliseconds

  // prepare frame param
  static DCAMBUF_FRAME bufframe;
  memset(&bufframe, 0, sizeof(bufframe));
  bufframe.size = sizeof(bufframe);
  bufframe.iFrame = -1; // latest captured image
  //	bufframe.option=DCAMBUF_FRAME_OPTION__PROC_HIGHCONTRAST; //Uncomment
  // this line for high contrast mode.

  DCAMERR err;

  // wait image
  err = dcamwait_start(hwait, &waitstart);
  if (failed(err)) {
    // dcamcon_show_dcamerr( hdcam, err, "dcamwait_start()" );
    return NULL;
  }

  // access image
  err = dcambuf_lockframe(hdcam, &bufframe);
  if (failed(err)) {
    // dcamcon_show_dcamerr( hdcam, err, "dcambuf_lockframe()" );
    return NULL;
  }
  LastFrame->buf = bufframe.buf;
  LastFrame->height = bufframe.height;
  LastFrame->width = bufframe.width;
  LastFrame->top = bufframe.top;
  LastFrame->left = bufframe.left;
  return LastFrame;
}

// This function repeatedly checks the camera status until the camera has
// acquired the full number of frames specified for the acquisition at which
// point it stops the camera and restarts the live acquisition.
unsigned __stdcall waitdonefunction(void *pArguments) {
  Hamamatsu_Cam *cam = (Hamamatsu_Cam *)pArguments;
  BOOL bStop = FALSE;
  DCAMERR err;

  DCAMREC_STATUS recstatus;
  // get recording status
  while (!bStop) {
    memset(&recstatus, 0, sizeof(recstatus));
    recstatus.size = sizeof(recstatus);
    err = dcamrec_status(cam->hrec, &recstatus);
    if (failed(err)) {
      dcamcon_show_dcamerr(cam->hdcam, err, "dcamrec_status()", NULL);
      cam->acq_done = 1;
    } else {
      printf("flags: 0x%08x, latest index: %06d, miss: 0x%06d, total: %d\n",
             recstatus.flags, recstatus.currentframe_index,
             recstatus.missingframe_count, recstatus.totalframecount);
      if (recstatus.totalframecount == cam->requestedframes) {
        bStop = true;
      }
    }
  }
  cam->dropped_frame_count = recstatus.missingframe_count;
  cam->acq_done = 1;
  printf("finished\n");
  dcamcap_stop(cam->hdcam);
  cam->aq_live_restart();
  _endthreadex(0);
  return 0;
}

// thread to convert dcimg to binary.
unsigned __stdcall convertThreadFcn(void *pArguments) {
  Hamamatsu_Cam *cam = (Hamamatsu_Cam *)pArguments;
  char dcimg_fname[MAX_MSG_LEN], fname_bin_temp[MAX_MSG_LEN],
      fname_bin_tgt[MAX_MSG_LEN];
  sprintf(dcimg_fname, "%s.%s", cam->fpath_dcimg_copy, cam->fext_dcimg_copy);
  cam->rm_dup_slashes(dcimg_fname, dcimg_fname);
  sprintf(fname_bin_temp, "%s.%s", cam->fpath_bin_temp_copy,
          cam->fext_bin_temp_copy);
  cam->rm_dup_slashes(fname_bin_temp, fname_bin_temp);
  sprintf(fname_bin_tgt, "%s.bin", cam->fpath_bin_tgt_copy);
  cam->rm_dup_slashes(fname_bin_tgt, fname_bin_tgt);
  if (cam->rdrive_mode) {
    if (convert_file(dcimg_fname, fname_bin_temp)) {
      // successful, lets delete dcimg file
      remove(dcimg_fname);
      size_t srcnamelen = strlen(fname_bin_temp) + 1;
      wchar_t *srcname = new wchar_t[srcnamelen];
      mbstowcs(srcname, fname_bin_temp, srcnamelen);

      size_t tgtnamelen = strlen(fname_bin_tgt) + 1;
      wchar_t *tgtname = new wchar_t[tgtnamelen];
      mbstowcs(tgtname, fname_bin_tgt, tgtnamelen);
      bool x = MoveFileEx((LPCWSTR)srcname, (LPCWSTR)tgtname,
                          MOVEFILE_REPLACE_EXISTING | MOVEFILE_COPY_ALLOWED);
      DWORD dw = GetLastError();

      delete[] tgtname;
      delete[] srcname;
    }
  } else {
    if (convert_file(dcimg_fname, fname_bin_tgt)) {
      // successful, lets delete dcimg file
      remove(dcimg_fname);
    }
  }
  _endthreadex(0);
  return 0;
}

// dcimg2bin doesn't like duplicate slashes in paths. This helper function
// removes duplicate slashes from the input path. Copies the contents of path
// into the location at &curr, with duplicate slashes removed and returns a
// pointer to curr.
char *Hamamatsu_Cam::rm_dup_slashes(const char *path, char *curr) {
  if (path == NULL || curr == NULL) {
    return NULL;
  }
  char *begin = curr;
  // always copy first character
  *curr = *path;
  // if it's just a single `NUL`, we're done
  if (*curr == '\0') {
    return curr;
  }
  for (path++; *path; ++path) {
    // path points to next char to read
    // curr points to last written
    if (*curr != *path || (*curr != '\\' && *curr != '/')) {
      // only copy if not duplicate slash
      *++curr = *path;
    }
  }
  *++curr = '\0'; // terminate string
  return begin;
}

// Ask camera for information specified by idStr. Output information will be
// saved in location &text.
inline const int my_dcamdev_string(DCAMERR &err, HDCAM hdcam, int32 idStr,
                                   char *text, int32 textbytes) {
  DCAMDEV_STRING param;
  memset(&param, 0, sizeof(param));
  param.size = sizeof(param);
  param.text = text;
  param.textbytes = textbytes;
  param.iString = idStr;

  err = dcamdev_getstring(hdcam, &param);
  return (failed(err) == 0); // Return true if failed(err) is 0, false
                             // otherwise.
}

// Initialize and open Hamamatsu camera controller
HDCAM hd_dcamcon_init_open(const char *camid_requested) {
  // Initialize DCAM-API ver 4.0
  DCAMAPI_INIT paraminit;
  memset(&paraminit, 0, sizeof(paraminit));
  paraminit.size = sizeof(paraminit);
  char cameraid[64];

  DCAMERR err;
  err = dcamapi_init(&paraminit);
  if (failed(err)) {
    // failure
    dcamcon_show_dcamerr(NULL, err, "dcamapi_init()", NULL);
    return NULL;
  }

  int32 nDevice = paraminit.iDeviceCount;
  ASSERT(nDevice > 0); // nDevice must be larger than 0

  int32 iDevice;

  // show all camera information by text
  for (iDevice = 0; iDevice < nDevice; iDevice++) {
    dcamcon_show_dcamdev_info((HDCAM)(UINT_PTR)iDevice);
  }
  bool devmatch = false;
  // If multiple devices, find match to requested id.
  if (nDevice > 1) {
    for (int32 i = 0; i < nDevice; i++) {
      devmatch = true;
      my_dcamdev_string(err, (HDCAM)(UINT_PTR)i, DCAM_IDSTR_CAMERAID, cameraid,
                        sizeof(cameraid));
      devmatch = STREQHD(cameraid, camid_requested);
      if (devmatch) {
        iDevice = i;
      }
    }
  }
  // Otherwise connect to only device available.
  else {
    iDevice = 0;
    my_dcamdev_string(err, (HDCAM)(UINT_PTR)iDevice, DCAM_IDSTR_CAMERAID,
                      cameraid, sizeof(cameraid));
    devmatch = STREQHD(cameraid, camid_requested);
  }

  if (0 <= iDevice && iDevice < nDevice) {
    // open specified camera
    DCAMDEV_OPEN paramopen;
    memset(&paramopen, 0, sizeof(paramopen));
    paramopen.size = sizeof(paramopen);
    paramopen.index = iDevice;
    err = dcamdev_open(&paramopen);
    if (!failed(err)) {
      HDCAM hdcam = paramopen.hdcam;

      // success
      return hdcam;
    }

    dcamcon_show_dcamerr((HDCAM)(UINT_PTR)iDevice, err, "dcamdev_open()",
                         "index is %d\n", iDevice);
  }

  // uninitialize DCAM-API
  dcamapi_uninit();

  // failure
  return NULL;
}
#endif