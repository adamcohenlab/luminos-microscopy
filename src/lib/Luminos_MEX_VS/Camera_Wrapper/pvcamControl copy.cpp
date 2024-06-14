#include "pvcamControl.h"

#define SENSOR_H 3200
#define SENSOR_W 3200

bool verboseFlag = true;
bool isCapturing = false;
bool isRecording = false;

const int16 bufferMode = CIRC_OVERWRITE;
const uns16 circBufferFrames = 20;
uns8 *liveCircBufferInMemory;
uns32 exposureBytes;
BUF_FRAME bufframe;
uns32 circBufferCnt = 0;

std::vector<CameraContext *> contexts;
static CameraContext *cam_ctx = NULL;
static double exposureTime = .1;
static double hPos, hSize, vPos, vSize, hBinning, vBinning;
static uns32 exposureTimeMicroseconds, readoutTimeMicroseconds;
double exposureTimeSeconds, readoutTimeSeconds; // hamamatsu

std::string out_pp_param;
std::string out_speedtable;

char fpath_dcimg_copy[MAX_MSG_LEN];
char fext_dcimg_copy[MAX_MSG_LEN];
char fpath_bin_temp_copy[MAX_MSG_LEN];
char fext_bin_temp_copy[MAX_MSG_LEN];
char fpath_bin_tgt_copy[MAX_MSG_LEN];
char fext_bin_tgt_copy[MAX_MSG_LEN];

char msg[MAX_MSG_LEN];

extern std::mutex ghMutexCapturing;

// we want this one
bool pvcam_startup(void) {
  if (PV_OK == InitAndOpenOneCamera(contexts, cSingleCamIndex)) {
    cam_ctx = contexts[cSingleCamIndex];

    pl_cam_register_callback_ex3(cam_ctx->hcam, PL_CALLBACK_EOF,
                                 (void *)GenericEofHandler, cam_ctx);

    output_pp_parameter_state(out_pp_param);
    //         output_speedtable(out_speedtable);

    int32 exp_res_ID = EXP_RES_ONE_MICROSEC;
    pl_set_param(cam_ctx->hcam, PARAM_EXP_RES_INDEX, (void *)&exp_res_ID);
    pl_set_param(cam_ctx->hcam, PARAM_READOUT_PORT,
                 (void *)&cam_ctx->speedTable[2].value);
    pixel_filter_off();
    return true;
  }

  return false;
}

void pixel_filter_off(void) {
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

/**
 * @brief Outputs the current state of the camera's post-processing parameters.
 *
 * This function discovers the camera's post-processing features and parameters,
 * and outputs their IDs, names, and current values.
 *
 * @param out_msg A reference to a string that will contain the output message.
 */
void output_pp_parameter_state(std::string &out_msg) {
  char s_buf[100];
  out_msg.clear();
  const std::vector<PvcamPpFeature> ppFeatures =
      DiscoverCameraPostProcessing(cam_ctx);
  sprintf(s_buf, "Camera Post-Processing tree:\n");
  out_msg += s_buf;
  for (const PvcamPpFeature &ppFeature : ppFeatures) {
    // Print IDs as signed integers to display invalid value as -1 instead of a
    // large number. Valid ID is usually a small number based on current pattern
    // in pvcam.h.
    sprintf(s_buf, "- FEATURE at index %d: id=%d, name='%s'\n", ppFeature.index,
            (int32)ppFeature.id, ppFeature.name.c_str());
    out_msg += s_buf;
    for (const PvcamPpParameter &ppParam : ppFeature.parameterList) {
      uns32 cur_val;
      int16 f_index = ppFeature.index;
      int16 pp_index = ppParam.index;
      pl_set_param(cam_ctx->hcam, PARAM_PP_INDEX, (void *)(&f_index));
      pl_set_param(cam_ctx->hcam, PARAM_PP_PARAM_INDEX, (void *)(&pp_index));
      pl_get_param(cam_ctx->hcam, PARAM_PP_PARAM, ATTR_CURRENT,
                   (void *)&cur_val);
      sprintf(s_buf, "  - PARAMETER at index %d: id=%d, name='%s', value=%d\n",
              ppParam.index, (int32)ppParam.id, ppParam.name.c_str(), cur_val);
      out_msg += s_buf;

      uns32 cnt;
      pl_get_param(cam_ctx->hcam, PARAM_PP_PARAM, ATTR_COUNT, (void *)&cnt);
      for (uns32 i = 0; i < 2; i++) {
        int32 value;
        char name[20];
        pl_get_enum_param(cam_ctx->hcam, PARAM_PP_PARAM, i, &value, name, 20);
        sprintf(s_buf, "    - value=%d, name='%s'\n", value, name);
        out_msg += s_buf;
      }
    }
  }

  return;
}

void output_speedtable(std::string &out_msg) {
  char s_buf[100];
  out_msg.clear();
  // Build and cache the camera speed table
  if (!GetSpeedTable(cam_ctx, cam_ctx->speedTable))
    return;

  // Speed table has been created, print it out
  sprintf(s_buf, "  Speed table:\n");
  out_msg += s_buf;
  for (const auto &port : cam_ctx->speedTable) {
    sprintf(s_buf, "  - port '%s', value %d\n", port.name.c_str(), port.value);
    out_msg += s_buf;
    for (const auto &speed : port.speeds) {
      sprintf(s_buf, "    - speed index %d, running at %f MHz\n", speed.index,
              1000 / (float)speed.pixTimeNs);
      out_msg += s_buf;
      for (const auto &gain : speed.gains) {
        sprintf(s_buf, "      - gain index %d, %sbit-depth %d bpp\n",
                gain.index,
                (gain.name.empty()) ? "" : ("'" + gain.name + "', ").c_str(),
                gain.bitDepth);
        out_msg += s_buf;
      }
    }
  }
  sprintf(s_buf, "\n");
  out_msg += s_buf;
}

bool set_centered_roi(double hSizeTry, double vSizeTry) {
  if (!cam_ctx->isCamOpen) {
    printf("no camera open\n");
    return false;
  }
  hSize = round(fmin(round(hSizeTry / 8.0) * 8, SENSOR_W));
  vSize = round(fmin(round(vSizeTry / 8.0) * 8, SENSOR_H));
  hPos = round(fmax((SENSOR_W - hSize) / 2 + 1, 1));
  vPos = round(fmax((SENSOR_H - vSize) / 2 + 1, 1));

  return true;
}

bool set_arbitrary_roi(double hPosTry, double hSizeTry, double vPosTry,
                       double vSizeTry) {
  if (!cam_ctx->isCamOpen) {
    printf("no camera open\n");
    return false;
  }
  hSize = round(hSizeTry / 4.0) * 4;
  hSize = fmax(hSize, 4);
  hSize = fmin(hSize, SENSOR_W);
  vSize = round(vSizeTry / 4.0) * 4;
  vSize = fmax(vSize, 4);
  vSize = fmin(vSize, SENSOR_H);

  hPos = fmax(hPos, 1);
  vPos = fmax(vPos, 1);
  hPos = round(hPosTry / 4.0) * 4;
  hPos = fmin(hPos, SENSOR_W - hSize + 1);
  vPos = round(vPosTry / 4.0) * 4;
  vPos = fmin(vPos, SENSOR_H - vSize + 1);

  return true;
}

bool aq_live_stop() {
  ghMutexCapturing.lock();
  isCapturing = false;
  ghMutexCapturing.unlock();
  if (PV_OK != pl_exp_abort(cam_ctx->hcam, CCS_HALT)) {
    return false;
    //             printf("Live acquisition stopped on camera \n");
  }

  return true;
}

bool aq_live_restart(bool isCentered, double *inputROI, double binning,
                     double exposureTimeMiliseconds) {
  if (!cam_ctx->isCamOpen) {
    printf("no camera open\n");
    return false;
  }

  aq_live_stop();
  vBinning = binning;
  hBinning = binning;
  exposureTimeMicroseconds = exposureTimeMiliseconds * 1e+3;

  if (isCentered) {
    set_centered_roi(inputROI[0], inputROI[1]);
  } else {
    set_arbitrary_roi(inputROI[0], inputROI[1], inputROI[2], inputROI[3]);
  }

  const int16 expMode = EXT_TRIG_INTERNAL;
  //     rgn_type roi = {0,2048,1,0,2048,1};
  rgn_type roi = {(uns16)(vPos - 1),         (uns16)(vPos + vSize - 2),
                  (uns16)vBinning,           (uns16)(hPos - 1),
                  (uns16)(hPos + hSize - 2), (uns16)hBinning};
  //
  if (PV_OK != pl_exp_setup_cont(cam_ctx->hcam, 1, &roi, expMode,
                                 exposureTimeMicroseconds, &exposureBytes,
                                 bufferMode)) {
    return false;
  }

  exposureTimeSeconds = double(exposureTimeMicroseconds) / 1e6;
  pl_get_param(cam_ctx->hcam, PARAM_EXPOSURE_TIME, ATTR_CURRENT,
               &readoutTimeMicroseconds);
  readoutTimeSeconds = double(readoutTimeMicroseconds) / 1e6;
  printf("Live acquisition set up success on camera\n");
  //
  UpdateCtxImageFormat(cam_ctx);
  //
  const uns32 circBufferBytes = circBufferFrames * exposureBytes;
  //
  ghMutexCapturing.lock();

  delete[] liveCircBufferInMemory;
  liveCircBufferInMemory = new (std::nothrow) uns8[circBufferBytes];

  if (!liveCircBufferInMemory) {
    printf("Unable to allocate buffer for camera %d\n");
    ghMutexCapturing.unlock();
    return false;
  }

  if (PV_OK != pl_exp_start_cont(cam_ctx->hcam, liveCircBufferInMemory,
                                 circBufferBytes)) {
    PrintErrorMessage(pl_error_code(), "pl_exp_start_cont() error");
    ghMutexCapturing.unlock();
    return false;
    //         free(liveCircBufferInMemory);
  }
  // //

  isCapturing = true;
  ghMutexCapturing.unlock();
  printf("Live acquisition started on camera\n");
  return true;
}

bool aq_sync_prepare(bool isCentered, double *inputROI, double binning,
                     double exposureTime) {
  if (!cam_ctx->isCamOpen) {
    printf("no camera open\n");
    return false;
  }

  aq_live_stop();
  vBinning = binning;
  hBinning = binning;
  exposureTimeMicroseconds = exposureTime * 1e+3;

  if (isCentered) {
    set_centered_roi(inputROI[0], inputROI[1]);
  } else {
    set_arbitrary_roi(inputROI[0], inputROI[1], inputROI[2], inputROI[3]);
  }

  //     SelectCameraExpMode(cam_ctx, expMode, STROBED_MODE, (void*) &expMode);
  rgn_type roi = {(uns16)(vPos - 1),         (uns16)(vPos + vSize - 2),
                  (uns16)vBinning,           (uns16)(hPos - 1),
                  (uns16)(hPos + hSize - 2), (uns16)hBinning};
  const int16 expMode = EXT_TRIG_EDGE_RISING;
  if (PV_OK == pl_exp_setup_cont(cam_ctx->hcam, 1, &roi, expMode,
                                 exposureTimeMicroseconds, &exposureBytes,
                                 bufferMode)) {

    exposureTimeSeconds = double(exposureTimeMicroseconds) / 1e6;
    pl_get_param(cam_ctx->hcam, PARAM_READOUT_TIME, ATTR_CURRENT,
                 &readoutTimeMicroseconds);
    readoutTimeSeconds = double(readoutTimeMicroseconds) / 1e6;
    printf("Live acquisition set up success on camera\n");
  }

  return true;
}

void aq_sync_start(int32 recordFrames, const char *fpath, const char *fext) {
  std::thread aq_sync_start_thread =
      std::thread(aq_sync_start_Fcn, recordFrames, fpath, fext);
  aq_sync_start_thread.detach();
  return;
}

bool aq_sync_start_Fcn(int32 recordFrames, const char *fpath,
                       const char *fext) {
  if (!cam_ctx->isCamOpen) {
    printf("no camera open\n");
    return false;
  }
  uns32 MAX_BUFFER_FRAMES = (int)1.5e+9 / exposureBytes;
  uns32 MAX_BUFFER_SIZE = ((int)1.5e+9 / exposureBytes) * exposureBytes;
  uns32 circBufferBytes_test = recordFrames * exposureBytes;
  //     const uns32 circBufferBytes =
  //     (MAX_BUFFER_SIZE<circBufferBytes_test)?MAX_BUFFER_SIZE:circBufferBytes_test;
  const uns32 circBufferBytes = (MAX_BUFFER_FRAMES < (uns32)recordFrames)
                                    ? MAX_BUFFER_SIZE
                                    : circBufferBytes_test;
  uns8 *circBufferInMemory = new (std::nothrow) uns8[circBufferBytes];
  if (!circBufferInMemory) {
    printf("Unable to allocate buffer for camera %d\n");
  }

  if (PV_OK !=
      pl_exp_start_cont(cam_ctx->hcam, circBufferInMemory, circBufferBytes)) {
    PrintErrorMessage(pl_error_code(), "pl_exp_start_cont() error");
    delete[] circBufferInMemory;
    return false;
  }
  //
  ghMutexCapturing.lock();
  isCapturing = true;
  ghMutexCapturing.unlock();
  printf("Sync acquisition started on camera\n");

  // 	int16 status;
  // 	uns32 bytes_arrived;
  // 	uns32 buffer_cnt;
  //
  // //     wait_for_thread_abort(cam_ctx, (exposureTimeSeconds+1)*1e+3);
  //
  // 	while(status != READOUT_NOT_ACTIVE){
  // 		if(PV_OK != pl_exp_check_cont_status(cam_ctx->hcam, &status,
  // &bytes_arrived, &buffer_cnt)){
  //             delete [] circBufferInMemory;
  //             ghMutexCapturing.lock();
  //                 isCapturing = false;
  //             ghMutexCapturing.unlock();
  // 			return false;
  // 		}
  // 	}
  // //     ghMutexCapturing.lock();
  // //         isCapturing = false;
  //
  char fname_bin_tgt[MAX_MSG_LEN];
  sprintf(fname_bin_tgt, "%s.%s", fpath, fext);
  rm_dup_slashes(fname_bin_tgt, fname_bin_tgt);

  //     FILE* f = std::fopen(fname_bin_tgt,"wb");
  //     std::fwrite(reinterpret_cast<const void*>(circBufferInMemory), 1,
  //     circBufferBytes, f);
  // //     fprintf(f,"%s","test");
  //     std::fclose(f);

  // 	SaveImage(circBufferInMemory, circBufferBytes, fname_bin_tgt);

  //     ghMutexCapturing.unlock();
  //     delete [] circBufferInMemory;
  if (stream_data_to_file(fname_bin_tgt, circBufferInMemory, circBufferBytes,
                          recordFrames)) {
    delete[] circBufferInMemory;
  }
  return true;
}

BUF_FRAME *aq_snap() {
  //     if(isCapturing){
  //         if(~isRecording){
  //             bufframe.width = round(vSize/vBinning);
  //             bufframe.height = round(hSize/hBinning);
  //             circBufferCnt %= circBufferFrames;
  //             bufframe.buf = liveCircBufferInMemory + circBufferCnt *
  //             exposureBytes;
  // //                 bufframe.buf = nullptr;
  // //                 return &bufframe;
  //     //         bufframe.buf = cam_ctx->eofFrame;
  //             return &bufframe;
  //         }
  //     }

  //     bufframe.buf = nullptr;
  //     return &bufframe;
  if (isCapturing) {
    bufframe.width = round(vSize / vBinning);
    bufframe.height = round(hSize / hBinning);
    //         void* latest_frame;
    if (PV_OK != pl_exp_get_latest_frame(cam_ctx->hcam, &(bufframe.buf))) {
      //         if(PV_OK !=
      //         pl_exp_get_latest_frame(cam_ctx->hcam,&(latest_frame))){
      bufframe.buf = nullptr;
      return &bufframe;
    }
    //         bufframe.buf = cam_ctx->eofFrame;
    //         memcpy(bufframe.buf,latest_frame,bufframe.width*bufframe.height*sizeof(uint16_t));
    return &bufframe;
  }

  bufframe.buf = nullptr;
  return &bufframe;
}

bool pvcam_shutdown(void) {
  if (!cam_ctx->isCamOpen) {
    printf("no camera open\n");
    return false;
  }
  aq_live_stop();

  delete[] liveCircBufferInMemory;

  CloseAllCamerasAndUninit(contexts);

  return true;
}

bool wait_for_thread_abort(CameraContext *ctx, uns32 timeoutMs) {
  std::unique_lock<std::mutex> lock(ctx->eofEvent.mutex);

  ctx->eofEvent.cond.wait_for(lock, std::chrono::milliseconds(timeoutMs),
                              [ctx]() { return ctx->threadAbortFlag; });
  return ctx->threadAbortFlag;
}

bool stream_data_to_file(char *fpath, uns8 *circBufferPtr,
                         const uns32 circBufferSize, int totalFrames) {

  FILE *f = std::fopen(fpath, "wb");
  int16 status;
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
      ghMutexCapturing.lock();
      isCapturing = false;
      ghMutexCapturing.unlock();
      std::fclose(f);
      return false;
    }

    //         bytesWritten %= circBufferSize;
    bytesBufferInc = bytesWritten % circBufferSize;
    bytesToWrite = (frame_info.FrameNr - frameNrPrev) * exposureBytes;
    //         std::fwrite(reinterpret_cast<const void*>(circBufferPtr +
    //         bytesWritten), 1,
    //                     bytesToWrite, f);
    //         if(bytesToWrite+bytesWritten < circBufferSize){
    std::fwrite(reinterpret_cast<const void *>(circBufferPtr + bytesBufferInc),
                1, bytesToWrite, f);
    //         }
    //         else{
    //             std::fwrite(reinterpret_cast<const void*>(circBufferPtr +
    //             bytesBufferInc), 1,
    //                     bytesToWrite+bytesWritten - circBufferSize, f);
    //             std::fwrite(reinterpret_cast<const void*>(circBufferPtr +
    //             bytesBufferInc), 1,
    //                     bytesToWrite+bytesWritten - circBufferSize, f);
    //         }
    frameNrPrev = frame_info.FrameNr;
    bytesWritten += bytesToWrite;
  }

  if (bytesWritten < uint64_t(totalFrames) * uint64_t(exposureBytes)) {
    //         bytesWritten %= circBufferSize;
    bytesBufferInc = bytesWritten % circBufferSize;
    //         bytesToWrite =
    //         (totalFrames*exposureBytes-circBufferSize*buffer_cnt -
    //         bytesWritten);
    bytesToWrite = (totalFrames * exposureBytes - bytesWritten);
    //         std::fwrite(reinterpret_cast<const void*>(circBufferPtr +
    //         bytesWritten), 1,
    //                 bytesToWrite, f);
    //         std::fwrite(reinterpret_cast<const void*>(circBufferPtr +
    //         bytesBufferInc), 1,
    //                     bytesToWrite, f);
    std::fwrite(reinterpret_cast<const void *>(circBufferPtr + circBufferSize -
                                               bytesToWrite),
                1, bytesToWrite, f);
  }
  std::fclose(f);
  return true;
}
