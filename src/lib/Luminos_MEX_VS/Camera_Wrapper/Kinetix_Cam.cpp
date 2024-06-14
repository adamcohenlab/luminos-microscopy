#include "pch.h"
#include "Cam_Wrapper.h"

#ifdef KINETIX_CONFIGURED

#include "Kinetix_Cam.h"
#include "master.h"
#include <stdio.h>
#include <iostream>
#include <mutex>
#include <cstring>
#include <fstream>
#include <windows.h>
#include <process.h>

#include <algorithm>
#include <thread>
#include <chrono>
#include <condition_variable>

Kinetix_Cam::Kinetix_Cam() {
  if (PV_OK != InitAndOpenOneCamera(contexts, cSingleCamIndex)) {
    throw std::runtime_error("Failed to initialize camera.");
  }
  ghMutexCapturing = CreateMutex(NULL, FALSE, NULL);
  cam_ctx = contexts[cSingleCamIndex];
  acq_done = 1;
  read_mode =
      0; // 0 gives External start trigger mode (one trigger at the beginning of
         // the recording).
         // gives external synchronous trigger mode (one frame per trigger)

  // Adding end of frame handler allows functions to react to changes to
  // FrameInfo. Necessary to stop continuous acquisition in stream_data_to_file.
  pl_cam_register_callback_ex3(cam_ctx->hcam, PL_CALLBACK_EOF,
                               (void *)GenericEofHandler, cam_ctx);

  // remove the postprocessing so we just get the raw data
  output_pp_parameter_state();

  // set exposure time to a resolution of us
  int32 exp_res_ID = EXP_RES_ONE_MICROSEC;
  pl_set_param(cam_ctx->hcam, PARAM_EXP_RES_INDEX, (void *)&exp_res_ID);

  pl_set_param(cam_ctx->hcam, PARAM_READOUT_PORT,
               (void *)&cam_ctx->speedTable[2].value);

  // more postprocessing removal
  pixel_filter_off();

  ROI.x = 1087;
  ROI.y = 1087;
  ROI.w = 1024;
  ROI.h = 1024;
  bin = 1;
  exposureTimeSeconds = 0.15;
  oldROI.w = ROI.w;
  oldROI.h = ROI.h;
  oldROI.x = ROI.x;
  oldROI.y = ROI.y;

  // allocate memory for the last frame
  LastFrame = (CamFrame *)malloc(sizeof(CamFrame));
  int frame_size = MAX_IMG_WIDTH * MAX_IMG_HEIGHT * sizeof(uint16_t);
  LastFrame->buf = calloc(MAX_IMG_WIDTH * MAX_IMG_HEIGHT, sizeof(uint16_t));
  // std::this_thread::sleep_for(std::chrono::milliseconds(100));
}

/*
Remove the postprocessing so we just get the raw data
 */
void Kinetix_Cam::output_pp_parameter_state() {
  const std::vector<PvcamPpFeature> ppFeatures =
      DiscoverCameraPostProcessing(cam_ctx);
  for (const PvcamPpFeature &ppFeature : ppFeatures) {
    // Print IDs as signed integers to display invalid value as -1 instead of a
    // large number. Valid ID is usually a small number based on current pattern
    // in pvcam.h.
    // ppFeature.index,
    //         (int32)ppFeature.id, ppFeature.name.c_str());
    for (const PvcamPpParameter &ppParam : ppFeature.parameterList) {
      uns32 cur_val;
      int16 f_index = ppFeature.index;
      int16 pp_index = ppParam.index;
      pl_set_param(cam_ctx->hcam, PARAM_PP_INDEX, (void *)(&f_index));
      pl_set_param(cam_ctx->hcam, PARAM_PP_PARAM_INDEX, (void *)(&pp_index));
    }
  }

  return;
}

void Kinetix_Cam::pixel_filter_off(void) {
  // turn off pixel denoising postprocessing
  // DESPECKLE BRIGHT LOW
  int16 id1 = 0, index1 = 0;
  uns32 value1 = 0;
  pl_set_param(cam_ctx->hcam, PARAM_PP_INDEX, (void *)&id1);
  pl_set_param(cam_ctx->hcam, PARAM_PP_PARAM_INDEX, (void *)&index1);
  pl_set_param(cam_ctx->hcam, PARAM_PP_PARAM, &value1);

  // DESPECKLE BRIGHT HIGH
  int16 id2 = 1, index2 = 0;
  uns32 value2 = 0;
  pl_set_param(cam_ctx->hcam, PARAM_PP_INDEX, (void *)&id2);
  pl_set_param(cam_ctx->hcam, PARAM_PP_PARAM_INDEX, (void *)&index2);
  pl_set_param(cam_ctx->hcam, PARAM_PP_PARAM, &value2);

  // DESPECKLE DARK LOW
  int16 id3 = 2, index3 = 0;
  uns32 value3 = 0;
  pl_set_param(cam_ctx->hcam, PARAM_PP_INDEX, (void *)&id3);
  pl_set_param(cam_ctx->hcam, PARAM_PP_PARAM_INDEX, (void *)&index3);
  pl_set_param(cam_ctx->hcam, PARAM_PP_PARAM, &value3);

  // DESPECKLE DARK HIGH
  int16 id4 = 3, index4 = 0;
  uns32 value4 = 0;
  pl_set_param(cam_ctx->hcam, PARAM_PP_INDEX, (void *)&id4);
  pl_set_param(cam_ctx->hcam, PARAM_PP_PARAM_INDEX, (void *)&index4);
  pl_set_param(cam_ctx->hcam, PARAM_PP_PARAM, &value4);
  return;
}

bool Kinetix_Cam::set_centered_roi(double hSizeTry, double vSizeTry) {
  if (!cam_ctx->isCamOpen) {
    return false;
  }
  oldROI.w = ROI.w;
  oldROI.h = ROI.h;
  oldROI.x = ROI.x;
  oldROI.y = ROI.y;
  WaitForSingleObject(ghMutexCapturing, INFINITE);
  ROI.w = (int)round(fmin(round(hSizeTry / 8.0) * 8, SENSOR_W));
  ROI.h = (int)round(fmin(round(vSizeTry / 8.0) * 8, SENSOR_H));
  ROI.x = (int)round(fmax((SENSOR_W - ROI.w) / 2 + 1, 1));
  ROI.y = (int)round(fmax((SENSOR_H - ROI.h) / 2 + 1, 1));
  ReleaseMutex(ghMutexCapturing);
  return true;
}

bool Kinetix_Cam::set_arbitrary_roi(double hPosTry, double hSizeTry,
                                    double vPosTry, double vSizeTry) {
  if (!cam_ctx->isCamOpen) {
    return false;
  }
  oldROI.w = ROI.w;
  oldROI.h = ROI.h;
  oldROI.x = ROI.x;
  oldROI.y = ROI.y;
  WaitForSingleObject(ghMutexCapturing, INFINITE);
  // set the width
  ROI.w = round(hSizeTry / 4.0) * 4;
  ROI.w = fmax(ROI.w, 4);
  ROI.w = fmin(ROI.w, SENSOR_W);

  // set the height
  ROI.h = round(vSizeTry / 4.0) * 4;
  ROI.h = fmax(ROI.h, 4);
  ROI.h = fmin(ROI.h, SENSOR_H);

  // set the x position
  ROI.x = fmax(ROI.x, 0);
  ROI.x = round(hPosTry / 4.0) * 4;
  ROI.x = fmin(ROI.x, SENSOR_W - ROI.w);

  // set the y position
  ROI.y = fmax(ROI.y, 0);
  ROI.y = round(vPosTry / 4.0) * 4;
  ROI.y = fmin(ROI.y, SENSOR_H - ROI.h);
  ReleaseMutex(ghMutexCapturing);
  return true;
}

void Kinetix_Cam::aq_live_stop() {
  printf("Called aq_live_stop\n");
  WaitForSingleObject(ghMutexCapturing, INFINITE);
  isCapturing = false;
  isRecording = false;
  ReleaseMutex(ghMutexCapturing);
  if (PV_OK != pl_exp_abort(cam_ctx->hcam, CCS_HALT)) {
  }
  printf("Finished aq_live_stop\n");
}

// Stop synchronous acquisition Call to clean up after synchronous acquisition
void Kinetix_Cam::aq_sync_stop() {
  printf("Called aq_sync_stop\n");
  if (isCapturing) {
    WaitForSingleObject(ghMutexCapturing, INFINITE);
    isCapturing = false;
    ReleaseMutex(ghMutexCapturing);
    if (PV_OK != pl_exp_abort(cam_ctx->hcam, CCS_HALT)) {
      printf("Finished aq_sync_stop\n");
    }
  }
}

bool Kinetix_Cam::aq_live_restart() {
  // Function overload that just runs based on already defined values.
  return aq_live_restart(ROI, bin, exposureTimeSeconds);
}

bool Kinetix_Cam::aq_live_restart(SDL_Rect inputROI, int binning,
                                  double exposureTime) {
  if (!cam_ctx->isCamOpen) {
    return false;
  }
  if (isCapturing) {
    // need to stop capturing
    if (isRecording) {
      // synchronized recording to disk
      aq_sync_stop();
    } else {
      // live imaging
      aq_live_stop();
    }
  }
  // here assume capturing is stopped

  WaitForSingleObject(ghMutexCapturing, INFINITE);
  bin = binning;
  exposureTimeSeconds = exposureTime;
  double exposureTimeMicroseconds = exposureTime * 1e+6;

  set_arbitrary_roi(inputROI.x, inputROI.w, inputROI.y, inputROI.h);

  int16 expMode;
  if (!SelectCameraExpMode(cam_ctx, expMode, TIMED_MODE, EXT_TRIG_INTERNAL)) {
    CloseAllCamerasAndUninit(contexts);
    ReleaseMutex(ghMutexCapturing);
    return APP_EXIT_ERROR;
  }

  rgn_type roi = {(uns16)(ROI.x), (uns16)(ROI.x + ROI.w - 1), (uns16)binning,
                  (uns16)(ROI.y), (uns16)(ROI.y + ROI.h - 1), (uns16)binning};

  // std::string message = "Exposure Time: " + std::to_string(exposureTime) +
  // "\n"; message += "expMode: " + std::to_string(expMode) + "\n"; message +=
  // "roi: (" + std::to_string(roi.s1) + ", " + std::to_string(roi.s2) +
  //            ", " + std::to_string(roi.sbin) + ", " + std::to_string(roi.p1)
  //            +
  //            ", " + std::to_string(roi.p2) + ", " + std::to_string(roi.pbin)
  //            +
  //            ")\n";
  // std::cout << message;

  if (PV_OK != pl_exp_setup_cont(cam_ctx->hcam, 1, &roi, expMode,
                                 exposureTimeMicroseconds, &exposureBytes,
                                 bufferMode)) {
    ReleaseMutex(ghMutexCapturing);
    return false;
  }
  // print all the inputs to the function above

  char errmsg[MAX_MSG_LEN];
  // sprintf(errmsg, "Exposure bytes is %u\n", exposureBytes);

  UpdateCtxImageFormat(cam_ctx);

  const uns32 circBufferBytes = circBufferFrames * exposureBytes;

  delete[] liveCircBufferInMemory;
  liveCircBufferInMemory = new (std::nothrow) uns8[circBufferBytes];

  if (!liveCircBufferInMemory) {
    ReleaseMutex(ghMutexCapturing);
    return false;
  }

  if (PV_OK != pl_exp_start_cont(cam_ctx->hcam, liveCircBufferInMemory,
                                 circBufferBytes)) {
    PrintErrorMessage(pl_error_code(), "pl_exp_start_cont() error");
    ReleaseMutex(ghMutexCapturing);
    return false;
  }

  isCapturing = true;
  ReleaseMutex(ghMutexCapturing);
  return true;
}

CamFrame *Kinetix_Cam::aq_thread_snap() {
  // printf("called aq_thread_snap");
  if (!isCapturing) {
    return LastFrame;
  }

  // int16 status;
  // uns32 byte_cnt;
  // uns32 buffer_cnt;
  // while (PV_OK == pl_exp_check_cont_status(cam_ctx->hcam, &status, &byte_cnt,
  //                                          &buffer_cnt) &&
  //        status != FRAME_AVAILABLE && status != READOUT_NOT_ACTIVE &&
  //        !cam_ctx->threadAbortFlag) {
  //   /**
  //   WARNING: Removing the sleep or setting it to a value too low may
  //   significantly increase the CPU load. Shorter sleeps do not guarantee the
  //   code does not miss a frame 'notification' if the frame rate is too high.
  //   */
  //   std::this_thread::sleep_for(std::chrono::milliseconds(10));
  // }
  // if (status == READOUT_FAILED) {
  //   return LastFrame;
  // }

  // Lock capturing mutex while writing to LastFrame. Ensure that mutex is
  // checked out before trying to read.
  WaitForSingleObject(ghMutexCapturing, INFINITE);

  // this only needs to be done at the start of aq_live_restart
  LastFrame->iFrame = -1; // dunno what this does
  LastFrame->width = round(ROI.w / bin);
  LastFrame->height = round(ROI.h / bin);
  LastFrame->top = round(ROI.y / bin);
  LastFrame->left = round(ROI.x / bin);
  // load the latest frame into the buffer
  /*if (PV_OK != pl_exp_get_latest_frame(cam_ctx->hcam, &(LastFrame->buf))) {
    LastFrame->buf = nullptr;
    return LastFrame;
  }*/
  void *frame_ptr;
  if (PV_OK != pl_exp_get_latest_frame(cam_ctx->hcam, &(frame_ptr))) {
    ReleaseMutex(ghMutexCapturing);
    return LastFrame;
  }

  memcpy(LastFrame->buf, frame_ptr,
         LastFrame->width * LastFrame->height * sizeof(uint16_t));
  ReleaseMutex(ghMutexCapturing);
  return LastFrame;
}

bool Kinetix_Cam::aq_sync_prepare(SDL_Rect inputROI, int binning,
                                  double exposureTime) {
  aq_live_stop();

  WaitForSingleObject(ghMutexCapturing, INFINITE);
  // set the object property bin to the input binning
  bin = binning;
  double exposureTimeMicroseconds = exposureTime * 1e+6;
  acq_done = 0;
  // Assuming inputROI represents the ROI with x, y as the top-left corner
  // and w, h as the width and height of the ROI respectively
  set_arbitrary_roi(inputROI.x, inputROI.w, inputROI.y, inputROI.h);

  rgn_type roi = {(uns16)(ROI.x), (uns16)(ROI.x + ROI.w - 1), (uns16)binning,
                  (uns16)(ROI.y), (uns16)(ROI.y + ROI.h - 1), (uns16)binning};
  // const int16 expMode = EXT_TRIG_EDGE_RISING;
  //  Select the appropriate internal trigger mode for this camera.

  int16 expMode;

  if (read_mode == 1) {
    expMode = EXT_TRIG_EDGE_RISING;
    printf("Selected Rising Edge/ External mode.\n");
  } else if (read_mode == 0) {
    expMode = EXT_TRIG_TRIG_FIRST;
    printf("Selected Single Pulse/Internal mode.\n");
  }

  // print the roi
  printf("aq_sync_prepare ROI: (%d, %d, %d, %d, %d, %d)\n", roi.s1, roi.s2,
         roi.sbin, roi.p1, roi.p2, roi.pbin); // print the roi

  if (PV_OK == pl_exp_setup_cont(cam_ctx->hcam, 1, &roi, expMode,
                                 exposureTimeMicroseconds, &exposureBytes,
                                 bufferMode)) {
  }
  ReleaseMutex(ghMutexCapturing);
  return true;
}

struct ThreadParams {
  Kinetix_Cam *obj;
  int32 recordFrames;
  char *fpath;
};

//!!!!!!!!!!!!!!!!!!!!!!!!!
bool Kinetix_Cam::aq_sync_start(int32 recordFrames, const char *fpath) {
  WaitForSingleObject(ghMutexCapturing, INFINITE);
  isRecording = true;
  isCapturing = true;
  ReleaseMutex(ghMutexCapturing);
  ThreadParams *params = new ThreadParams; // dynamically allocate
  params->obj = this;
  params->recordFrames = recordFrames;
  params->fpath = new char[strlen(fpath) + 1]; // +1 for the null terminator
  strcpy(params->fpath, fpath); // Copy the string. This is done because fpath
                                // gets reallocated and corrupted otherwise.

  waitdonethread = (HANDLE)_beginthreadex(NULL, 0, &aq_sync_start_FcnWrapper,
                                          (void *)params, 0, &waitdonethreadid);
  //while (isRecording == true && isCapturing == true) {
  //  printf("Waiting for thread to finish.\n");
  //  Sleep(250);
  //}
  //printf("Thread ended. isRecording is false.\n");
  //aq_live_restart();
  return true;
}

unsigned int __stdcall Kinetix_Cam::aq_sync_start_FcnWrapper(void *params) {
  ThreadParams *threadParams = (ThreadParams *)params;
  bool result = threadParams->obj->aq_sync_start_Fcn(threadParams->recordFrames,
                                                     threadParams->fpath);
  delete threadParams;

  return result ? 0 : 1;
}

bool Kinetix_Cam::aq_sync_start_Fcn(int32 recordFrames, const char *fpath) {
  // set the right circular buffer size based on available RAM
  uns32 MAX_BUFFER_FRAMES = static_cast<uns32>(RAM_SIZE / exposureBytes);
  uns32 MAX_BUFFER_SIZE = MAX_BUFFER_FRAMES * exposureBytes;
  uns32 circBufferBytes_test = recordFrames * exposureBytes;

  const uns32 circBufferBytes =
      (MAX_BUFFER_FRAMES < static_cast<uns32>(recordFrames))
          ? MAX_BUFFER_SIZE
          : circBufferBytes_test;
  printf("circBufferBytes: %u\n", circBufferBytes); // Use %u for uns32
  uns8 *circBufferInMemory = new (std::nothrow) uns8[circBufferBytes];
  if (!circBufferInMemory) {
    return false;
  }

  if (PV_OK !=
      pl_exp_start_cont(cam_ctx->hcam, circBufferInMemory, circBufferBytes)) {
    delete[] circBufferInMemory;
    return false;
  }

  // Writing buffer to file
  if (stream_data_to_file(fpath, circBufferInMemory, circBufferBytes,
                          recordFrames)) {
    delete[] circBufferInMemory;
  }

  acq_done = 1;
  printf("About to end thread\n");
  aq_sync_stop();
  _endthreadex(0);
  return true;
}

bool Kinetix_Cam::stream_data_to_file(const char *fpath, uns8 *circBufferPtr,
                                      const uns32 circBufferSize,
                                      int totalFrames) {

  // Convert fpath to std::string and add ".bin" extension
  std::string modifiedFpath = std::string(fpath) + ".bin";

  // Open the file with correct extension
  FILE *f = std::fopen(modifiedFpath.c_str(), "wb");

  int16 status = -1;
  uns32 bytes_arrived;
  uns32 buffer_cnt;
  FRAME_INFO frame_info;
  uns32 bytesBufferInc = 0, bytesToWrite, frameNrPrev = 0;
  uint64_t bytesWritten = 0;

  while (status != READOUT_NOT_ACTIVE) {
    if (PV_OK != pl_exp_check_cont_status_ex(cam_ctx->hcam, &status,
                                             &bytes_arrived, &buffer_cnt,
                                             &frame_info)) {
      delete[] circBufferPtr;
      WaitForSingleObject(ghMutexCapturing, INFINITE);
      isCapturing = false;
      ReleaseMutex(ghMutexCapturing);
      std::fclose(f);
      return false;
    }

    bytesBufferInc = bytesWritten % circBufferSize;
    bytesToWrite = (frame_info.FrameNr - frameNrPrev) * exposureBytes;
    printf("%u\n", frame_info.FrameNr);

    size_t written = std::fwrite(
        reinterpret_cast<const void *>(circBufferPtr + bytesBufferInc), 1,
        bytesToWrite, f);

    frameNrPrev = frame_info.FrameNr;
    bytesWritten += bytesToWrite;
    if (frame_info.FrameNr >= int32(totalFrames)) {
      printf("Collected enough frames.");
      status = READOUT_NOT_ACTIVE;
    }
  }
  printf("bytesWritten=%u, bytesToWrite=%u\n", bytesWritten,
         uint64_t(totalFrames) * uint64_t(exposureBytes));
  if (bytesWritten < uint64_t(totalFrames) * uint64_t(exposureBytes)) {
    bytesBufferInc = bytesWritten % circBufferSize;
    bytesToWrite = (totalFrames * exposureBytes - bytesWritten);
    printf("Final write: bytesBufferInc=%u, bytesToWrite=%u\n", bytesBufferInc,
           bytesToWrite);

    size_t final_written =
        std::fwrite(reinterpret_cast<const void *>(
                        circBufferPtr + circBufferSize - bytesToWrite),
                    1, bytesToWrite, f);
    printf("Final write to file: %zu bytes\n", final_written);
  }

  std::fclose(f);

  WaitForSingleObject(ghMutexCapturing, INFINITE);
  isRecording = false;
  ReleaseMutex(ghMutexCapturing);
  printf("File closed: %s\n", fpath);

  aq_live_restart();

  return true;
}

bool Kinetix_Cam::dc_shutdown(void) {
  if (!cam_ctx->isCamOpen) {
    return false;
  }
  aq_live_stop();

  delete[] liveCircBufferInMemory;

  CloseAllCamerasAndUninit(contexts);
  free(LastFrame->buf);
  return true;
}

double Kinetix_Cam::find_sensor_size(void) {
  double value = SENSOR_H;
  return value;
}

#endif