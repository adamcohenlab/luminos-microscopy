#include "pch.h"
#include "Cam_Emulator.h"
#include <chrono>

/*Camera emulator provides a simulated Cam_Wrapper compatible camera. It provides a drifting diagonal grating.*/
Cam_Emulator::Cam_Emulator()
    : framecounter(), lastImageDataHeight(), lastImageDataWidth(), tbthread() {
  Em_Mutex = CreateMutex(NULL, FALSE, NULL);
  ghMutexCapturing = CreateMutex(NULL, FALSE, NULL);
  Em_Data.buf =
      (uint16_t *)malloc(MAX_IMG_WIDTH * MAX_IMG_HEIGHT * sizeof(uint16_t));
  middlebuffer =
      (uint16_t *)malloc(MAX_IMG_WIDTH * MAX_IMG_HEIGHT * sizeof(uint16_t));
  isCapturing = true;
  newframe_avail = false;
  ROI.x = 0;
  ROI.y = 0;
  ROI.w = MAX_IMG_WIDTH;
  ROI.h = MAX_IMG_HEIGHT;
  exposureTimeSeconds = .15;
}

//destructor
Cam_Emulator::~Cam_Emulator() {
  if (isCapturing == true) {
    dc_shutdown();
  }
}

//stop live acquisition
void Cam_Emulator::aq_live_stop() {
  if (isCapturing) {
    WaitForSingleObject(ghMutexCapturing, INFINITE);
    isCapturing = false;
    ReleaseMutex(ghMutexCapturing);
    printf("capture stopped\n");
  } else {
    printf("capture already stopped\n");
  }
}

//Restart live acquisition (no-arguments wrapper).
bool Cam_Emulator::aq_live_restart() {
  aq_live_restart(ROI, 1, exposureTimeSeconds);
  return 0;
}

//restart live acquisition with given ROI, binning, and exposure time (s))
bool Cam_Emulator::aq_live_restart(SDL_Rect inputROI, int binning,
                                   double exposureTime) {
  WaitForSingleObject(ghMutexCapturing, INFINITE);
  isCapturing = false;
  ReleaseMutex(ghMutexCapturing);
  SDL_Delay(10);
  WaitForSingleObject(ghMutexCapturing, INFINITE);
  ROI = inputROI;
  exposureTimeSeconds = exposureTime;
  bin = (int)binning;
  unsigned calcthreadid;
  isCapturing = true;
  //start thread for producing simulated grating frames.
  tbthread = (HANDLE)_beginthreadex(NULL, (unsigned int)1e9, &DispCalcHD,
                                    (void *)this, 0, &calcthreadid);
  ReleaseMutex(ghMutexCapturing);
  return 0;
}

//Virtual Sensor size
double Cam_Emulator::find_sensor_size() { return MAX_IMG_WIDTH; }

//Calculate simulated sawtooth grating image. Currently only SSE2 version supported. If desired, scalar version could be enabled or
//processor compatibility check introduced (see StreamDisplayHD.cpp), but SSE2 is supported by all 64 bit Intel and AMD processors,
//so scalar versions are very likely unnecessary.
unsigned __stdcall DispCalcHD(void *pArguments) {
  Cam_Emulator *cam = (Cam_Emulator *)pArguments;
  uint16_t __declspec(align(16)) tempbuffer[MAX_IMG_WIDTH * MAX_IMG_HEIGHT];
  int j = 0;

  auto time_to_wake = std::chrono::steady_clock::now();
  std::chrono::microseconds exposureTimeMicroseconds_chrono;
  while (cam->isCapturing) {
      //Timing to produce steady frame rate.
    exposureTimeMicroseconds_chrono =
        std::chrono::microseconds((int)(cam->exposureTimeSeconds * 1e6));
    std::chrono::steady_clock::time_point last_frame_time =
        std::chrono::steady_clock::now();
    j = 0;
    int maxy = (cam->ROI.h + cam->ROI.y);
    int maxx = (cam->ROI.x + cam->ROI.w);
    int fc = cam->framecounter;
    int ROIx = cam->ROI.x;
    int ix;

    // Scalar version (standard c++ platform independent). Fairly
    // resource-demanding and slow
    /*for (int iy = cam->ROI.y; iy < maxy; iy++) {
            int y_f = iy + fc;
            for (ix = ROIx; ix < maxx; ix++) {
                    //tempbuffer[j] = ((ix + iy + fc) % 512);
                    tempbuffer[j] = ((ix + y_f) & 511);
                    j++;
            }
    }*/

    // SSE2 intrinsics (Single Instruction Multiple Data vectorized) version.
    // Only uses intrinsics provided by SSE and SSE2, which are supported on all
    // 64 bit Intel and all modern AMD processors. Significantly faster than
    // scalar version above. Phil Brooks 7-2022

    __m128i mask_511 = _mm_set1_epi16(511); //Mask of 7 LSB (mod 512 operation)
    __m128i increments = _mm_set_epi16(7, 6, 5, 4, 3, 2, 1, 0);
    int maxx_adjusted =
        maxx -
        7; // make sure vectorized operations stop before they run out of room.
    //iterate through rows:
    for (int iy = cam->ROI.y; iy < maxy; iy++) {
      __m128i y_f = _mm_set1_epi16(iy + fc);
      //Iterate through groups of 8 pixels
      for (ix = ROIx; ix < maxx_adjusted; ix += 8) {
        // Add row and column together, take mod 512 (using 7 bit mask), then
        // store in output buffer.
        _mm_store_si128(
            (__m128i *)&tempbuffer[j],
            _mm_and_si128(mask_511,
                          _mm_add_epi16(y_f, _mm_add_epi16(_mm_set1_epi16(ix),
                                                           increments))));
        j += 8;
      }
      // Handle remaining units (too few for a full SSE register) as scalars.
      for (; ix < maxx; ix++) {
        tempbuffer[j] = ((ix + iy + fc) & 511);
        j++;
      }
    }

    // AVX2 intrinsics (same idea as SSE2, but using 256 bit instead of 128 bit
    // registers. Supported by modern Intel and AMD processors, but not as far
    // back as SSE2, so less safe for our lab's old computers. Testing on my
    // laptop (i3-4005u from 2013 with AVX2 support shows non-significant
    // improvement over SSE2, so I left the more compatible SSE2 version live.
    /*__m256i mask_511 = _mm256_set1_epi16(511);
    __m256i increments = _mm256_set_epi16(15,14,13,12,11,10,9,8,7, 6, 5, 4, 3,
    2, 1, 0); int maxx_adjusted = maxx - 15; //make sure vectorized operations
    stop before they run out of room. for (int iy = cam->ROI.y; iy < maxy; iy++)
    {
            __m256i y_f = _mm256_set1_epi16(iy + fc);
            for (ix = ROIx; ix < maxx_adjusted; ix += 16) {
                    _mm256_store_si256((__m256i*) & tempbuffer[j],
    _mm256_and_si256(mask_511, _mm256_add_epi16(y_f,
    _mm256_add_epi16(_mm256_set1_epi16(ix), increments)))); j += 16;
            }
            //Handle remaining units (too few for a full SSE register) as
    scalars. for (; ix < maxx; ix++) { tempbuffer[j] = ((ix + iy + fc) & 511);
                    j++;
            }
    }*/

    cam->framecounter++;
    WaitForSingleObject(cam->Em_Mutex, INFINITE);
    memcpy(cam->middlebuffer, tempbuffer,
           cam->ROI.h * cam->ROI.w * sizeof(uint16_t));
    cam->newframe_avail = true;
    ReleaseMutex(cam->Em_Mutex);
    //wait until next frame is due
    time_to_wake = last_frame_time + exposureTimeMicroseconds_chrono;
    // printf("%d\n",
    // std::chrono::duration_cast<std::chrono::milliseconds>(time_to_wake -
    // last_time_to_wake).count());
    std::this_thread::sleep_until(time_to_wake);
  }
  _endthreadex(0);
  return 0;
}

//copy and return snap frame data
CamFrame *Cam_Emulator::aq_thread_snap() {
  WaitForSingleObject(Em_Mutex, INFINITE);
  if (newframe_avail) {
    memcpy(Em_Data.buf, middlebuffer, ROI.h * ROI.w * sizeof(uint16_t));
    Em_Data.height = ROI.h;
    Em_Data.width = ROI.w;
    Em_Data.left = ROI.x;
    Em_Data.top = ROI.y;
    newframe_avail = false;
    ReleaseMutex(Em_Mutex);
    return &Em_Data;
  } else {
    ReleaseMutex(Em_Mutex);
    return NULL;
  }
}

//Return existing snap frame data
CamFrame *Cam_Emulator::aq_snap() { return &Em_Data; }

//Cleanup and shutdown
bool Cam_Emulator::dc_shutdown() {
  isCapturing = false;
  WaitForSingleObject(tbthread, INFINITE);
  CloseHandle(tbthread);
  free(Em_Data.buf);
  free(middlebuffer);
  return true;
}