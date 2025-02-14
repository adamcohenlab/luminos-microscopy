#include "pch.h"
#include "StreamDisplayHD.h"
#include "InstructionSet.h"
#include <emmintrin.h> //SSE2, SSE, MMX intrinsics
#include <algorithm>
#include <chrono>

#include "SDL2_gfxPrimitives.h"

using namespace std::chrono;
const InstructionSet::InstructionSet_Internal InstructionSet::CPU_Rep;
double StreamDisplayHD::Px_to_um = 1;

/* StreamDisplay class implements a multi-threaded data-streaming, display, and
handoff module. This takes image data from a camera and streams it to a live
display window, which can be interacted with to zoom, change ROI, change
colormap, and select a box from which to calculate sub-roi average and total
counts. When using the Cam_Wrapper class, the StreamDisplay does not need to be
handled directly by the client, but should be handled using the Cam_Wrapper as
an intermediate.*/

StreamDisplayHD::StreamDisplayHD()
    : imgToggleFlag(0x0), MONITOR_INDEX(DEFAULT_MONITOR_INDEX),
      SCREEN_WIDTH(DEFAULT_SCREEN_WIDTH), SCREEN_HEIGHT(DEFAULT_SCREEN_HEIGHT),
      lastImageDataWidth(MAX_IMG_WIDTH), lastImageDataHeight(MAX_IMG_HEIGHT),
      ReadyImgMutex(), ghMutexCapturing(), renderingMutex(), HandoffMutex(),
      window(), lastImageData(), loThresholdCounts(1), hiThresholdCounts(2048),
      myReadyImgSurf(), myWork1ImgSurf(), myWork2ImgSurf(), myImgTex(),
      renderer(), imgSrcRect(), imgDestRect(), ROI_on(false),
      ready_for_render(false), new_frame_available(false),
      new_frame_available_roi(false), new_frame_available_img(false),
      ROI_Active(false), ROI_click_toggle(0), ROI_Rect_mutex(), ROI_Rect(),
      ROI_Buff_Toggle_Flag(), ROITex(), drawrect(), ROImeanvec(),
      roibufferlength(), newframemutex(), newframeroimutex(),
      newframeimgmutex(), contour_click_toggle(), Contour_Active(),
      Contour_Ends(), ROI_Cont_mutex(), numcontavgs(0),
      keydelta(DEFAULT_KEY_DELTA), roi_buff(DEFAULT_ROI_MEAN_VEC_LENGTH),
      roi_sum_buff(DEFAULT_ROI_MEAN_VEC_LENGTH), cleaned_up(false), ROIPoints(),
      ROI_Ready_Surf(), ROImean(), SCREEN_X_POSITION(), SCREEN_Y_POSITION(),
      ScaleX(), ScaleY(), cPalette(), contavgcounter(), contour_numel(),
      contour_points(), ghMutexLims(), ROIthread(), calcthread(), dispthread(),
      disp_handoff_thread(), sd_thread(), framecheckthread(), handoffthreadid(),
      mHeight(), mPitch(), mPixels(), mWidth(), pixel_fmt(), sum_rect(),
      workImgSurfBuffer(), interaction_event(), use_sse(), color_fixed(false),
      color_fixed_low(0), color_fixed_high(65536), equalized(), flipped(false),
      rotated(0), histMutex(), lastCalculationTime(std::chrono::steady_clock::now())

{
  cmap_high = 1; // cmap bounds
  cmap_low = 0;
  newcontstore = false;
  cam = NULL;
  keydelta = DEFAULT_KEY_DELTA;
  cam_attached = false;
  lastKeyPressTime = 0;
  histogram.resize(256, 0);
  equalized = false;

  // buffers to hold subroi, contour, and image data.
  Contour_DrawGuides =
      (SDL_Point *)malloc(LINE_THICKNESS * 2 * sizeof(SDL_Point));
  tempROIBufferRGBA =
      (uint32_t *)malloc(MAX_IMG_WIDTH * MAX_IMG_HEIGHT * sizeof(uint32_t));
  lastImageData =
      (uint16_t *)malloc(MAX_IMG_WIDTH * MAX_IMG_HEIGHT * sizeof(uint16_t));
  contour_pixel_index = (int *)malloc(
      ((int)sqrt(pow(MAX_IMG_WIDTH, 2) + pow(MAX_IMG_HEIGHT, 2)) + 1) *
      sizeof(int));
  contour_buff = (double *)malloc(
      ((int)sqrt(pow(MAX_IMG_WIDTH, 2) + pow(MAX_IMG_HEIGHT, 2)) + 1) *
      sizeof(double));
  contour_store = (double *)malloc(
      ((int)sqrt(pow(MAX_IMG_WIDTH, 2) + pow(MAX_IMG_HEIGHT, 2)) + 1) *
      sizeof(double));

  cmap_pointers = (SDL_Color **)malloc(3 * sizeof(SDL_Color *));

  ROImeanvec = (double *)malloc(DEFAULT_ROI_MEAN_VEC_LENGTH * sizeof(double));
  roimeanstore = (double *)malloc(DEFAULT_ROI_MEAN_VEC_LENGTH * sizeof(double));

  roibufferlength = DEFAULT_ROI_MEAN_VEC_LENGTH;

  // Determine supported vector instruction sets.
  printf("MMX: %s\n", (InstructionSet::MMX() ? "Supported" : "Not Supported"));
  printf("SSE: %s\n", (InstructionSet::SSE() ? "Supported" : "Not Supported"));
  printf("SSE2: %s\n",
         (InstructionSet::SSE2() ? "Supported" : "Not Supported"));
  printf("SSE4.1: %s\n",
         (InstructionSet::SSE41() ? "Supported" : "Not Supported"));
  printf("AVX: %s\n", (InstructionSet::AVX() ? "Supported" : "Not Supported"));
  printf("AVX2: %s\n",
         (InstructionSet::AVX2() ? "Supported" : "Not Supported"));
  printf("FMA: %s\n", (InstructionSet::FMA() ? "Supported" : "Not Supported"));
  printf("AVX-512F: %s\n",
         (InstructionSet::AVX512F() ? "Supported" : "Not Supported"));
  // Is SSE4.1 supported (necessary for vectorized optimization of streaming and
  // conversion)
  use_sse = InstructionSet::SSE41(); // Set flag whether to use SSE or scalar.

  // check for successful memory allocation.
  if (lastImageData == NULL) {
    printf("Failed to allocate memory");
  }
  continueRunningAllThreads = true; // when false, stop all threads.

  // Create 'jet' colormap by mixing rgb colors.
  int blue_checks[5] = {0x7F, 0xFF, 0x7F, 0x00, 0x00};
  int green_checks[5] = {0x00, 0x7F, 0xFF, 0x7F, 0x00};
  int red_checks[5] = {0x00, 0x00, 0x7F, 0xFF, 0x7F};
  for (int j = 0; j < 4; j++) {
    for (int i = 0; i < 64; i++) {
      jet_colors[i + j * 64].r =
          (Uint8)(red_checks[j] * (((float)(64 - i)) / 64.0) +
                  red_checks[j + 1] * (((float)i) / 64.0));
      jet_colors[i + j * 64].g =
          (Uint8)(green_checks[j] * (((float)(64 - i)) / 64.0) +
                  green_checks[j + 1] * (((float)i) / 64.0));
      jet_colors[i + j * 64].b =
          (Uint8)(blue_checks[j] * (((float)(64 - i)) / 64.0) +
                  blue_checks[j + 1] * (((float)i) / 64.0));
      jet_colors[i + j * 64].a = 0xFF;
    }
  }
  // Create greyscale colormap
  int gr_blue_checks[5] = {0x00, 0x40, 0x80, 0xBF, 0xFF};
  int gr_green_checks[5] = {0x00, 0x40, 0x80, 0xBF, 0xFF};
  int gr_red_checks[5] = {0x00, 0x40, 0x80, 0xBF, 0xFF};
  for (int j = 0; j < 4; j++) {
    for (int i = 0; i < 64; i++) {
      grey_colors[i + j * 64].r =
          (Uint8)(gr_red_checks[j] * (((float)(64 - i)) / 64.0) +
                  gr_red_checks[j + 1] * (((float)i) / 64.0));
      grey_colors[i + j * 64].g =
          (Uint8)(gr_green_checks[j] * (((float)(64 - i)) / 64.0) +
                  gr_green_checks[j + 1] * (((float)i) / 64.0));
      grey_colors[i + j * 64].b =
          (Uint8)(gr_blue_checks[j] * (((float)(64 - i)) / 64.0) +
                  gr_blue_checks[j + 1] * (((float)i) / 64.0));
      grey_colors[i + j * 64].a = 0xFF;
    }
  }
  // Create inverted greyscale colormap
  int gr_inverted_blue_checks[5] = {0xFF, 0xBF, 0x80, 0x40, 0x00};
  int gr_inverted_green_checks[5] = {0xFF, 0xBF, 0x80, 0x40, 0x00};
  int gr_inverted_red_checks[5] = {0xFF, 0xBF, 0x80, 0x40, 0x00};
  for (int j = 0; j < 4; j++) {
    for (int i = 0; i < 64; i++) {
      grey_inverted_colors[i + j * 64].r =
          (Uint8)(gr_inverted_red_checks[j] * (((float)(64 - i)) / 64.0) +
                  gr_inverted_red_checks[j + 1] * (((float)i) / 64.0));
      grey_inverted_colors[i + j * 64].g =
          (Uint8)(gr_inverted_green_checks[j] * (((float)(64 - i)) / 64.0) +
                  gr_inverted_green_checks[j + 1] * (((float)i) / 64.0));
      grey_inverted_colors[i + j * 64].b =
          (Uint8)(gr_inverted_blue_checks[j] * (((float)(64 - i)) / 64.0) +
                  gr_inverted_blue_checks[j + 1] * (((float)i) / 64.0));
      grey_inverted_colors[i + j * 64].a = 0xFF;
    }
  }
  // Create 'hot' colormap
  int hot_blue_checks[5] = {0x00, 0x00, 0x00, 0x80, 0xFF};
  int hot_green_checks[5] = {0x00, 0x00, 0xFF, 0xFF, 0xFF};
  int hot_red_checks[5] = {0x00, 0xFF, 0xFF, 0xFF, 0xFF};
  for (int j = 0; j < 4; j++) {
    for (int i = 0; i < 64; i++) {
      hot_colors[i + j * 64].r =
          (Uint8)(hot_red_checks[j] * (((float)(64 - i)) / 64.0) +
                  hot_red_checks[j + 1] * (((float)i) / 64.0));
      hot_colors[i + j * 64].g =
          (Uint8)(hot_green_checks[j] * (((float)(64 - i)) / 64.0) +
                  hot_green_checks[j + 1] * (((float)i) / 64.0));
      hot_colors[i + j * 64].b =
          (Uint8)(hot_blue_checks[j] * (((float)(64 - i)) / 64.0) +
                  hot_blue_checks[j + 1] * (((float)i) / 64.0));
      hot_colors[i + j * 64].a = 0xFF;
    }
  }

  cmap_pointers[0] = grey_colors;
  cmap_pointers[1] = grey_inverted_colors;
  cmap_pointers[2] = hot_colors;
  cmap_pointers[3] = jet_colors;
  cmap_index = 0; // default is greyscale colormap (0)

  StreamDisplayHD::Px_to_um = 1;

  // Create unowned mutexes. Mutexes are objects that allow synchronization
  // between threads. A mutex can be 'owned'
  //  by up to one thread. Another thread can request ownership. If owned by
  //  another thread, the requesting thread will wait (suspend execution) until
  //  the mutex is released by the current owner.
  ReadyImgMutex = CreateMutex(NULL, FALSE, NULL); // for SDL readyimg surface
  HandoffMutex = CreateMutex(
      NULL, FALSE, NULL); // For lastimagedata internal copy of last frame
  ROI_Rect_mutex = CreateMutex(NULL, FALSE, NULL); // For SDL rectangle overlay
  newframemutex = CreateMutex(NULL, FALSE, NULL);
  newframeroimutex = CreateMutex(NULL, FALSE, NULL);
  newframeimgmutex = CreateMutex(NULL, FALSE, NULL);
  ROI_Cont_mutex = CreateMutex(NULL, FALSE, NULL);
  roidatamutex = CreateMutex(NULL, FALSE, NULL);
  contourstoremutex = CreateMutex(NULL, FALSE, NULL);
  renderingMutex = CreateMutex(NULL, FALSE, NULL);
  histMutex = CreateMutex(NULL, FALSE, NULL);


  // Create events that will be used to signal between threads. Events are
  // configured by second argument (True) to be manual-resettable.
  //
  newframeavailable_event = CreateEvent(
      NULL, TRUE, FALSE, TEXT("NewFrameEvent")); // Manual reset win32 event.
  newframeroi_event = CreateEvent(NULL, TRUE, FALSE, TEXT("NewFrameROIEvent"));
  newframeimg_event = CreateEvent(NULL, TRUE, FALSE, TEXT("NewFrameImgEvent"));
  readyforrender_event =
      CreateEvent(NULL, TRUE, FALSE, TEXT("ReadyForRenderEvent"));
}

// Destructor.
StreamDisplayHD::~StreamDisplayHD() {
  if (cleaned_up == false) {
    cleanup();
  }
}

// Cleanup method. Signal all threads to stop and set all events so that threads
// exit any wait states. Then wait for threads to exit, close all threads, free
// allocated memory, and quit SDL subsystem. Thorough cleanup is important to
// allow relaunching without errors and to avoid hangups or orphaned threads.
void StreamDisplayHD::cleanup() {
  if (cleaned_up ==
      false) { // The caller shouldn't be solely responsible for this check
    continueRunningAllThreads = false;
    // trigger all events to release waitforsingleevent(). All will exit upon
    // seeing continuerunningallthreads=false
    SetEvent(newframeavailable_event);
    SetEvent(newframeroi_event);
    SetEvent(newframeimg_event);
    SetEvent(readyforrender_event);
    // Wait for threads to exit:
    WaitForSingleObject(calcthread, INFINITE);
    CloseHandle(calcthread);
    WaitForSingleObject(ROIthread, INFINITE);
    CloseHandle(ROIthread);
    WaitForSingleObject(dispthread, INFINITE);
    CloseHandle(dispthread);
    WaitForSingleObject(disp_handoff_thread, INFINITE);
    CloseHandle(disp_handoff_thread);
    WaitForSingleObject(sd_thread,
                        1000); // cleanup itself may be called by sd_thread, in
                               // which case sd_thread can't exit until cleanup
                               // is done. Therefore we can't wait infinite.
    CloseHandle(sd_thread);
    WaitForSingleObject(framecheckthread, INFINITE);
    CloseHandle(framecheckthread);
    // free allocated memory
    free(lastImageData);
    free(tempROIBufferRGBA);
    free(ROImeanvec);
    free(roimeanstore);
    free(contour_store);
    free(contour_buff);
    free(contour_pixel_index);
    free(Contour_DrawGuides);
    // Clear and Quit SDL (if all running SDL subsystems are unititialized)
    SDL_RenderClear(renderer);
    printf("Quitting SDL video subsystem\n");
    // This checks the init counter, incremented each time SDL_Init is called on
    // the subsystem and only quits it if the counter==0.
    SDL_QuitSubSystem(SDL_INIT_VIDEO);
    if (SDL_WasInit(SDL_INIT_VIDEO) ==
        0) { // manually check whether init counter is 0
      printf("SDL Quit\n");
      SDL_Quit(); // Do final cleanup and quit of SDL. If we call this without
                  // checking first, we kill all of SDL every time
                  // we want to clean up a single StreamDisplay instance, even
                  // if others are still running.
    }
    cleaned_up = true;
  }
}

// Attach Camera instance to StreamDisplayHD instance. Call this first.
void StreamDisplayHD::attach_camera(Streaming_Device *cam_in) {
  cam = cam_in;
  if (cam != NULL) {
    cam_attached = true;
  }
}

// Launch display threads (actual launch happens in separate thread so client is
// not blocked during thread launching). Call this Second.
void StreamDisplayHD::launch_disp_threads() {
  unsigned sdthreadid;
  sd_thread =
      (HANDLE)_beginthreadex(NULL, (unsigned int)1e8, &SDL_Event_wrapper,
                             (void *)this, 0, &sdthreadid);
}

// Launch main loop that handles camera-StreamDisplay communication. Call this
// Third.
void StreamDisplayHD::Launch_Handoff_Thread() {
  disp_handoff_thread =
      (HANDLE)_beginthreadex(NULL, (unsigned int)5e8, &disphandoffThreadFcn,
                             (void *)this, (unsigned int)3e9, &handoffthreadid);
}

// Master display thread for starting subthreads and for monitoring user GUI
// interactions.
unsigned __stdcall SDL_Event_wrapper(void *pArguments) {
  unsigned calcthreadid, dispthreadid, ROIthreadid, fcheckthreadid;
  StreamDisplayHD *disp_ptr = (StreamDisplayHD *)pArguments;
  disp_ptr->start_SDL_window(NULL); // start display window
  disp_ptr->update_rendering();
  int flags;
  // Start subthreads:
  // calculation
  disp_ptr->calcthread =
      (HANDLE)_beginthreadex(NULL, (unsigned int)5e8, &calc_wrapper,
                             (void *)disp_ptr, 0, &calcthreadid);
  // display
  disp_ptr->dispthread =
      (HANDLE)_beginthreadex(NULL, (unsigned int)5e8, &disp_wrapper,
                             (void *)disp_ptr, 0, &dispthreadid);
  // ROI processing
  disp_ptr->ROIthread =
      (HANDLE)_beginthreadex(NULL, (unsigned int)5e8, &roi_calc_wrapper,
                             (void *)disp_ptr, 0, &ROIthreadid);
  // Check frame status
  disp_ptr->framecheckthread =
      (HANDLE)_beginthreadex(NULL, (unsigned int)5e8, &framecheck,
                             (void *)disp_ptr, 0, &fcheckthreadid);

  // Main UI loop:
  while (disp_ptr->continueRunningAllThreads == true) {
    SDL_Event interaction_event;
    // While there's an event to handle
    SDL_PumpEvents();
    flags = SDL_GetWindowFlags(disp_ptr->window);
    if (SDL_PollEvent(&interaction_event) &&
        (interaction_event.window.windowID ==
         SDL_GetWindowID(disp_ptr->window))) {
      // If the user has Xed out the window
      if (interaction_event.window.event == SDL_WINDOWEVENT_CLOSE) {
        // Quit the program
        disp_ptr->cam->isCapturing = false;
        disp_ptr->cam->aq_live_stop();
        disp_ptr->continueRunningAllThreads = false;
        disp_ptr->cleanup();
      }
      // User Mouse click
      if (interaction_event.type == SDL_MOUSEBUTTONDOWN) {
        int x, y, width, height;
        SDL_GetMouseState(&x, &y);
        SDL_GetWindowSize(disp_ptr->window, &width, &height);

        // Check if the click is in the rightmost 150 pixels of the window.
        // These are part of the colormap and histogram.

        if (x < width - 150) {
          printf("Widow h,w %d , %d", width, height);
          disp_ptr->ScaleX = (float)disp_ptr->imgDestRect.w /
                             (float)disp_ptr->lastImageDataWidth;
          disp_ptr->ScaleY = (float)disp_ptr->imgDestRect.h /
                             (float)disp_ptr->lastImageDataHeight;
          printf("clicked on %f , %f ",
                 ((float)(x)) / ((float)disp_ptr->ScaleX),
                 ((float)(y)) / ((float)disp_ptr->ScaleY));
          x = (int)((x - disp_ptr->imgDestRect.x) / (disp_ptr->ScaleX));
          y = (int)((y - disp_ptr->imgDestRect.y) / (disp_ptr->ScaleY));
          printf("rounded to %d , %d \n", x, y);
          if (interaction_event.button.button == SDL_BUTTON_LEFT) {
            disp_ptr->ROI_Update(x, y);
          } else if (interaction_event.button.button == SDL_BUTTON_RIGHT) {
            disp_ptr->Contour_Update(x, y);
          }
        }
      }
      // keyboard press
      if (interaction_event.type == SDL_KEYDOWN) {
        Uint32 currentTime = SDL_GetTicks();
        //        if (interaction_event.key.repeat == 0 &&
        if (currentTime - disp_ptr->lastKeyPressTime >= 500) {
          // Check if the keypress is not a repeat and at least 500
          // milliseconds have passed since the last key press
          disp_ptr->keyresponse(interaction_event.key.keysym.sym);
          disp_ptr->lastKeyPressTime =
              currentTime; // Update the last key press time
        }
      }
      if (interaction_event.type == SDL_MOUSEWHEEL) {
        WaitForSingleObject(disp_ptr->renderingMutex, INFINITE);
        if (disp_ptr->color_fixed == true) {
          int x, y, width, height;
          SDL_GetMouseState(&x, &y);
          SDL_GetWindowSize(disp_ptr->window, &width, &height);
          if (x > width - 150 && y < height / 3) {
            disp_ptr->color_fixed_high += interaction_event.wheel.y * 100;
            if (disp_ptr->color_fixed_high > 65535) {
              disp_ptr->color_fixed_high = 65535;
            } else if (disp_ptr->color_fixed_high < disp_ptr->color_fixed_low) {
              disp_ptr->color_fixed_high = disp_ptr->color_fixed_low;
            }

          } else if (x > width - 150 && y > height * 2 / 3) {
            disp_ptr->color_fixed_low += interaction_event.wheel.y * 100;
            if (disp_ptr->color_fixed_low < 0) {
              disp_ptr->color_fixed_low = 0;
            } else if (disp_ptr->color_fixed_low > disp_ptr->color_fixed_high) {
              disp_ptr->color_fixed_low = disp_ptr->color_fixed_high;
            }
          }
        }
        ReleaseMutex(disp_ptr->renderingMutex);
      }

    } else {     // If the event wasn't for this window, it may have been for
                 // another instance (another camera)
      Sleep(10); // Sleep the event thread to make sure other window gets the
                 // event.
    }
  }
  _endthreadex(0);
  return 0;
}

// Main thread for camera data handling.
unsigned __stdcall disphandoffThreadFcn(void *pArguments) {
  StreamDisplayHD *disp = (StreamDisplayHD *)pArguments;
  Streaming_Device *cam = disp->cam;
  CamFrame *newFrame = NULL;
  uint16_t myImageData[MAX_IMG_WIDTH * MAX_IMG_HEIGHT];
  int myImageDataWidth = MAX_IMG_WIDTH;
  int myImageDataHeight = MAX_IMG_HEIGHT;

  // Set up timing throttle: There's no point in streaming images to the display
  // faster than monitor refresh rates. It just needlessly uses CPU resources.
  const int MAX_REFRESH =
      60; // max refresh rate in Hz (beyond which there is no point sampling
          // for live display due to monitor rates)
  Uint64 min_refresh_interval = (Uint64)floor(
      1000 /
      MAX_REFRESH); // in ms. Minimum elapsed time between image refreshes.
  Uint64 base_time = 0;
  Uint64 time = 0;

  // Main Loop:
  while (disp->continueRunningAllThreads) {
    time = SDL_GetTicks();
    if (time - base_time < min_refresh_interval) {
      continue; // Ignore new frames that won't be seen due to screen refresh
                // limits
    }
    base_time = time;
    SDL_Delay(5); // REMOVE?

    // Frame data transfer split into two parts so that the transfer out of the
    // camera can be dependent on one mutex (ghMutexCapturing) to avoid
    // simultaneous access with upstream camera, while the transfer into the
    // lastImageData property can be dependent on another mutex (HandoffMutex)
    // to avoid simultaneous access with a downstream processing thread.

    // PART 1: From Camera
    WaitForSingleObject(cam->ghMutexCapturing, INFINITE);
    // read outside image only when not being modified
    if (cam->isCapturing &&
        !(cam->isRecording)) { // Don't livestream during recording.
      ReleaseMutex(cam->ghMutexCapturing);
      newFrame = cam->aq_thread_snap(); // get new frame data
      // copy frame into myImageData location.
      if (newFrame) {
        memcpy(myImageData, newFrame->buf,
               newFrame->width * newFrame->height * sizeof(uint16_t));
        myImageDataWidth = newFrame->width;
        myImageDataHeight = newFrame->height;
      }
    } else {
      ReleaseMutex(cam->ghMutexCapturing);
      newFrame = NULL;
    }

    // PART 2: Into lastImageData property.
    //  broadcast live image from local copy if updated. PERFORMANCE BOTTLENECK
    //  FROM EXTRA COPY?
    if (newFrame) {
      // write outside copy only if not being read
      WaitForSingleObject(disp->HandoffMutex, INFINITE);
      memcpy(disp->lastImageData, myImageData,
             myImageDataWidth * myImageDataHeight * sizeof(uint16_t));
      disp->lastImageDataWidth = myImageDataWidth;
      disp->lastImageDataHeight = myImageDataHeight;
      disp->new_frame_available = true;
      // Tell other threads that new frame is available.
      if (!SetEvent(disp->newframeavailable_event)) {
        printf("SetEvent failed (%d)\n", GetLastError());
        return 1;
      }
      ReleaseMutex(disp->HandoffMutex);
    }
  }
  _endthreadex(0);
  return 0;
}

// Update live display rendering with new image data.
void StreamDisplayHD::update_rendering() {
  SDL_RenderClear(renderer); // blank the rendering
  if (myReadyImgSurf) {      // in case these pointers are NULL
    // ensure myReadyImgSurf read while not writing elsewhere
    WaitForSingleObject(ReadyImgMutex, INFINITE);
    WaitForSingleObject(renderingMutex, INFINITE);

    WaitForSingleObject(histMutex, INFINITE);
    auto cdf = calculate_cdf(histogram);
    Histogram();
    if (equalized == true) {
      if (cmap_index == 0) {
        SDL_Color adjusted_grey_colors[256];
        adjust_colormap_with_cdf(adjusted_grey_colors, grey_colors, cdf, 256);
        SDL_SetPaletteColors(myReadyImgSurf->format->palette,
                             adjusted_grey_colors, 0, 256);
      } else if (cmap_index == 1) {
        SDL_Color adjusted_grey_inverted_colors[256];
        adjust_colormap_with_cdf(adjusted_grey_inverted_colors,
                                 grey_inverted_colors, cdf, 256);
        SDL_SetPaletteColors(myReadyImgSurf->format->palette,
                             adjusted_grey_inverted_colors, 0, 256);
      } else if (cmap_index == 2) {
        SDL_Color adjusted_hot_colors[256];
        adjust_colormap_with_cdf(adjusted_hot_colors, hot_colors, cdf, 256);
        SDL_SetPaletteColors(myReadyImgSurf->format->palette,
                             adjusted_hot_colors, 0, 256);
      } else if (cmap_index = 3) {
        SDL_Color adjusted_jet_colors[256];
        adjust_colormap_with_cdf(adjusted_jet_colors, jet_colors, cdf, 256);
        SDL_SetPaletteColors(myReadyImgSurf->format->palette,
                             adjusted_jet_colors, 0, 256);
      }
    }
    ReleaseMutex(histMutex);

    if (equalized == false) {
      if (cmap_index == 0) {
        SDL_SetPaletteColors(myReadyImgSurf->format->palette, grey_colors, 0,
                             256);
      } else if (cmap_index == 1) {
        SDL_SetPaletteColors(myReadyImgSurf->format->palette,
                             grey_inverted_colors, 0, 256);
      } else if (cmap_index == 2) {
        SDL_SetPaletteColors(myReadyImgSurf->format->palette, hot_colors, 0,
                             256);
      } else if (cmap_index = 3) {
        SDL_SetPaletteColors(myReadyImgSurf->format->palette, jet_colors, 0,
                             256);
      }
    }

    Colorbar();

    // Check for flipping and rotation
    SDL_RendererFlip flip = SDL_FLIP_NONE;
    if (flipped) {
      flip = SDL_FLIP_HORIZONTAL; // Set flip to horizontal
    }

    int angle = 0;
    if (rotated != 0) {
      angle = (rotated % 4) * 90; // Calculate angle based on rotated value
    }

    SDL_Texture *myImgTex =
        SDL_CreateTextureFromSurface(renderer, myReadyImgSurf);
    if (!myImgTex) {
      SDL_Log("Failed to create texture: %s", SDL_GetError());
    } else {
      // Render the texture with rotation and flipping
      if (SDL_RenderCopyEx(renderer, myImgTex, &imgSrcRect, &imgDestRect, angle,
                           NULL, flip) != 0) {
        SDL_Log("Failed to render with transformations: %s", SDL_GetError());
      }
    }

    SDL_DestroyTexture(myImgTex); // free texture
    ready_for_render = false;
    ResetEvent(readyforrender_event);

    SDL_RenderCopy(renderer, myImgTex, &imgSrcRect, &imgDestRect);

    // Draw sub-roi rectangle or contour on top of image:
    if (ROI_Active) {
      int code;
      WaitForSingleObject(ROI_Rect_mutex, INFINITE);
      SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255);
      code = SDL_RenderDrawRects(renderer, drawrect, 5);
      ReleaseMutex(ROI_Rect_mutex);
    } else if (Contour_Active) {
      int code;
      WaitForSingleObject(ROI_Cont_mutex, INFINITE);
      SDL_SetRenderDrawColor(renderer, 255, 0, 0, 255);
      code =
          SDL_RenderDrawLines(renderer, Contour_DrawGuides, LINE_THICKNESS * 2);

      // Print pixel distance between contour ends
      stringRGBA(renderer, SCREEN_WIDTH - 210, SCREEN_HEIGHT - 30, distText,
                 255, 0, 0, 255);
      stringRGBA(renderer, SCREEN_WIDTH - 130, SCREEN_HEIGHT - 15, UmDistText,
                 255, 0, 0, 255);
      printf("%s \n", UmDistText);

      ReleaseMutex(ROI_Cont_mutex);
    }
    //SDL_DestroyTexture(myImgTex); // free texture
    ReleaseMutex(ReadyImgMutex);
    ReleaseMutex(renderingMutex);
  }
  SDL_SetRenderDrawColor(renderer, 200, 200, 200, 255);
  SDL_RenderPresent(renderer); // put the rendering to screen
};

// Draw Colorbar
void StreamDisplayHD::Colorbar() {
  const int colormap_width = 30;
  const int colormap_height = floor(SCREEN_HEIGHT / 256);
  const int colormap_x = SCREEN_WIDTH + 10;
  const int colormap_y = round((SCREEN_HEIGHT - colormap_height * 256) / 2);

  // Constants for the border around the colormap
  const int border_width = colormap_width + 2;
  const int border_height = colormap_height * 256 + 2;
  const int border_x = colormap_x - 1;
  const int border_y = colormap_y - 1;

  // Draw the black border around the colormap
  SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
  SDL_Rect borderRect = {border_x, border_y, border_width, border_height};
  SDL_RenderFillRect(renderer, &borderRect);

  SDL_SetRenderDrawColor(renderer, 122, 122, 122, 255);
  SDL_Rect insideRect = {colormap_x, colormap_y, colormap_width, 256};
  SDL_RenderFillRect(renderer, &insideRect);

  // Define current_cmap based on cmap_index
  SDL_Color *current_cmap = cmap_pointers[cmap_index];

  for (int i = 0; i < 256; i++) {
    // Set the color for the current colormap
    SDL_SetRenderDrawColor(renderer, current_cmap[255 - i].r,
                           current_cmap[255 - i].g, current_cmap[255 - i].b,
                           current_cmap[255 - i].a);

    SDL_Rect colorStripe = {colormap_x, colormap_y + colormap_height * i, 30,
                            colormap_height};
    SDL_RenderFillRect(renderer, &colorStripe);
  }

  // Display threshold values
  char hiThresholdText[64];
  char loThresholdText[64];
  sprintf(hiThresholdText, "%d", hiThresholdCounts);
  sprintf(loThresholdText, "%d", loThresholdCounts);

  // Render the text
  stringRGBA(renderer, SCREEN_WIDTH + 5, colormap_y - 12, hiThresholdText, 0, 0,
             0, 255);
  stringRGBA(renderer, SCREEN_WIDTH + 5, colormap_y + border_height + 5,
             loThresholdText, 0, 0, 0, 255);
};

void StreamDisplayHD::Histogram() {
  const int numDisplayBins = 256; // Display histogram with 256 bins
  const int edge_x = SCREEN_WIDTH + 50;
  const int bar_width_def = floor(SCREEN_HEIGHT / 256.0);
  const int target_height = bar_width_def * 256;
  int current_y = round((SCREEN_HEIGHT - (bar_width_def * 256)) / 2.0) + 1;

  // Draw the thin vertical line
  SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
  SDL_RenderDrawLine(renderer, edge_x, current_y, edge_x,
                     current_y + target_height);

  // Calculate CDF from histogram
  std::vector<float> cdf(numDisplayBins, 0.0f);
  float total_pixels = 0.0f;
  for (int i = 0; i < numDisplayBins; ++i) {
    total_pixels += histogram[i];
  }

  if (total_pixels > 0) {
    cdf[0] = histogram[0] / total_pixels;
    for (int i = 1; i < numDisplayBins; ++i) {
      cdf[i] = cdf[i - 1] + (histogram[i] / total_pixels);
    }
  }

  uint64_t maxBinValue = *std::max_element(histogram.begin(), histogram.end());

  // Step 1: Calculate bar widths based on high-precision CDF only for non-zero
  // bins
  std::vector<int> bar_widths(numDisplayBins, 0); // Initialize with 0 width
  int unscaled_total_width = 0;

  // if (equalized && total_pixels > 0) {
  if (false) {
    for (int i = 0; i < numDisplayBins - 1; ++i) {
      float cdf_diff = cdf[i + 1] - cdf[i];
      if (histogram[255 - i] > 0) { // Only consider non-zero bins
        bar_widths[i] = static_cast<int>(cdf_diff * target_height);
        if (bar_widths[i] < 1)
          bar_widths[i] = 1;
        unscaled_total_width += bar_widths[i];
      }
    }
  } else {
    // If not equalized, use default width for non-zero bins
    for (int i = 0; i < numDisplayBins - 1; ++i) {
      bar_widths[i] = bar_width_def;
      unscaled_total_width += bar_width_def;
    }
  }

  // Normalize bar widths to fit into target height
  double scale_factor =
      static_cast<double>(target_height) / unscaled_total_width;

  for (int i = 0; i < numDisplayBins - 1; ++i) {
    bar_widths[i] = static_cast<int>(bar_widths[i] * scale_factor);
  }

  // Calculate cumulative positions for drawing, skipping zero-width
  // bars
  std::vector<int> cumulative_positions(numDisplayBins, current_y);
  for (int i = 1; i < numDisplayBins; ++i) {
    cumulative_positions[i] = cumulative_positions[i - 1] +
                              (bar_widths[i - 1] > 0 ? bar_widths[i - 1] : 0);
  }

  // Draw the histogram bars
  for (int i = 0; i < numDisplayBins - 1; ++i) {
    int bar_length =
        (maxBinValue > 0) ? (histogram[255 - i] * 100 / maxBinValue) : 0;
    int bar_width = bar_widths[i];

    if (bar_length > 1 && bar_width > 0) { // Only draw non-zero width bars
      thickLineRGBA(renderer, edge_x, cumulative_positions[i],
                    edge_x + bar_length, cumulative_positions[i], bar_width, 0,
                    0, 0, 255);
    }
  }
};

// Respond to Key presses:
void StreamDisplayHD::keyresponse(SDL_Keycode key) {
  SDL_Rect ROItry = cam->ROI;
  bool res;
  int current_binning = cam->bin;

  if (cam_attached) {
    double sensorsize;
    switch (key) {

    // Arrow keys increment or decrement sub-roi dimensions
    case SDLK_UP:
      ROItry.y = ROItry.y - keydelta;
      res = cam->aq_live_restart(ROItry, cam->bin, cam->exposureTimeSeconds);
      break;
    case SDLK_DOWN:
      ROItry.y = ROItry.y + keydelta;
      res = cam->aq_live_restart(ROItry, cam->bin, cam->exposureTimeSeconds);
      break;
    case SDLK_LEFT:
      ROItry.x = ROItry.x - keydelta;
      res = cam->aq_live_restart(ROItry, cam->bin, cam->exposureTimeSeconds);
      break;
    case SDLK_RIGHT:
      ROItry.x = ROItry.x + keydelta;
      res = cam->aq_live_restart(ROItry, cam->bin, cam->exposureTimeSeconds);
      break;

      //+- change binning
    case SDLK_KP_PLUS:
      if (current_binning == 4) {
        break;
      } else {
        sensorsize = cam->find_sensor_size();
        res = cam->aq_live_restart(cam->ROI, cam->bin * 2,
                                   cam->exposureTimeSeconds);
        break;
      }
    case SDLK_KP_MINUS:
      if (current_binning == 1) {
        break;
      } else {
        sensorsize = cam->find_sensor_size();
        res = cam->aq_live_restart(cam->ROI, cam->bin / 2,
                                   cam->exposureTimeSeconds);
        break;
      }

    // z Zooms camera ROI to current liveview subroi (sum_rect)
    case SDLK_z:
      if (ROI_Active) {
        ROItry = sum_rect;
        printf("x %d y %d w  %d h %d\n", ROItry.x, ROItry.y, ROItry.w,
               ROItry.h);
        ROItry.x = ROItry.x * cam->bin;
        ROItry.y = ROItry.y * cam->bin;
        ROItry.w = ROItry.w * cam->bin;
        ROItry.h = ROItry.h * cam->bin;
        ROItry.x += cam->ROI.x;
        ROItry.y += cam->ROI.y;
        ROItry.w++;
        ROItry.h++;
        res = cam->aq_live_restart(ROItry, cam->bin, cam->exposureTimeSeconds);
      }
      break;

    // x exits the camera ROI to the full sensor size.
    case SDLK_x:
      cam->framereset_switch = true;
      sensorsize = cam->find_sensor_size();
      ROItry.w = (int)sensorsize;
      ROItry.h = (int)sensorsize;
      ROItry.x = 0;
      ROItry.y = 0;
      res = cam->aq_live_restart(ROItry, cam->bin, cam->exposureTimeSeconds);
      break;

    // r refreshes the streaming display.
    case SDLK_r:
      cam->framereset_switch = true;
      ROItry.w = cam->ROI.w;
      ROItry.h = cam->ROI.h;
      ROItry.x = cam->ROI.x;
      ROItry.y = cam->ROI.y;
      res = cam->aq_live_restart(ROItry, cam->bin, cam->exposureTimeSeconds);
      break;

    case SDLK_s:
      // Swtich from fixed scale to auto scale
      color_fixed = !color_fixed;
      if (color_fixed) {
        color_fixed_high = hiThresholdCounts;
        color_fixed_low = loThresholdCounts;
      }
      break;

    // For debugging
    case SDLK_m:
      WaitForSingleObject(ReadyImgMutex, INFINITE);
      WaitForSingleObject(renderingMutex, INFINITE);
      color_fixed_high = ceil(color_fixed_high / 2);

      printf("Color Fixed High: %d\n", color_fixed_high);
      ReleaseMutex(ReadyImgMutex);
      ReleaseMutex(renderingMutex);
      break;

    // For debugging
    case SDLK_n:
      WaitForSingleObject(ReadyImgMutex, INFINITE);
      WaitForSingleObject(renderingMutex, INFINITE);
      color_fixed_high =
          min(static_cast<int>(ceil(color_fixed_high * 2.0)), 65535);
      printf("Color Fixed High: %d\n", color_fixed_high);
      ReleaseMutex(ReadyImgMutex);
      ReleaseMutex(renderingMutex);
      break;

    // c cycles through available colormaps
    case SDLK_c:
      cmap_index = (cmap_index + 1) % 4;
      WaitForSingleObject(ReadyImgMutex, INFINITE);
      SDL_SetPaletteColors(myWork1ImgSurf->format->palette,
                           cmap_pointers[cmap_index], 0, 256);
      SDL_SetPaletteColors(myWork2ImgSurf->format->palette,
                           cmap_pointers[cmap_index], 0, 256);
      ReleaseMutex(ReadyImgMutex);
      break;

    // h toggles histogram equalization
    case SDLK_h:
      printf("Toggled equalization\n");
      WaitForSingleObject(ReadyImgMutex, INFINITE);
      equalized = !equalized;
      ReleaseMutex(ReadyImgMutex);
      break;
    }
  }
}

// Thread wrapper for image data processing calculations before display.
unsigned __stdcall calc_wrapper(void *pArguments) {
  StreamDisplayHD *disp_ptr = (StreamDisplayHD *)pArguments;
  while (disp_ptr->continueRunningAllThreads) {
    WaitForSingleObject(disp_ptr->newframeimg_event, INFINITE);
    if (!disp_ptr->continueRunningAllThreads) {
      break;
    }
    // If new frame available:
    if (disp_ptr->new_frame_available_img) {
      disp_ptr->calc_and_update_image();
    }
    WaitForSingleObject(disp_ptr->newframeimgmutex, INFINITE);
    disp_ptr->new_frame_available_img = false;
    ResetEvent(disp_ptr->newframeimg_event);
    ReleaseMutex(disp_ptr->newframeimgmutex);
  }
  _endthreadex(0);
  return 0;
}

// Wait for new frame to be available from camera. Then set flags for other
// threads
unsigned __stdcall framecheck(void *pArguments) {
  StreamDisplayHD *disp_ptr = (StreamDisplayHD *)pArguments;
  while (disp_ptr->continueRunningAllThreads) {
    // Phil Brooks rewrote using event to eliminate unnecessary CPU usage 6/2022
    WaitForSingleObject(disp_ptr->newframeavailable_event,
                        INFINITE);              // wait for event
    if (!disp_ptr->continueRunningAllThreads) { // If stop has been signalled
                                                // during wait, then go to loop
                                                // condition, which will exit.
      break;
    }
    if (disp_ptr->new_frame_available) { // make sure event is valid (optional.
                                         // Could remove)
      WaitForSingleObject(disp_ptr->newframeimgmutex, INFINITE);
      disp_ptr->new_frame_available_img = true; // set downstream flag.
      SetEvent(disp_ptr->newframeimg_event);    // trigger event
      ReleaseMutex(disp_ptr->newframeimgmutex);
      // Set roi processing flags and events if applicable.
      if (disp_ptr->ROI_Active || disp_ptr->Contour_Active) {
        WaitForSingleObject(disp_ptr->newframeroimutex, INFINITE);
        disp_ptr->new_frame_available_roi = true;
        SetEvent(disp_ptr->newframeroi_event);
        ReleaseMutex(disp_ptr->newframeroimutex);
      }
    }
    disp_ptr->new_frame_available = false;
    ResetEvent(disp_ptr->newframeavailable_event);
  }
  _endthreadex(0);
  return 0;
}

// When new frame is ready for rendering, call update_rendering()
unsigned __stdcall disp_wrapper(void *pArguments) {
  StreamDisplayHD *disp_ptr = (StreamDisplayHD *)pArguments;
  // Phil Brooks rewrote using event to eliminate unnecessary CPU usage 6/2022
  while (disp_ptr->continueRunningAllThreads) {
    WaitForSingleObject(disp_ptr->readyforrender_event, INFINITE);
    if (!disp_ptr->continueRunningAllThreads) {
      break;
    }
    if (disp_ptr->ready_for_render) {
      disp_ptr->update_rendering();
    }
  }
  _endthreadex(0);
  return 0;
}

// Handle ROI mean and sum calculations
unsigned __stdcall roi_calc_wrapper(void *pArguments) {
  StreamDisplayHD *disp_ptr = (StreamDisplayHD *)pArguments;
  // Phil Brooks rewrote using event to eliminate unnecessary CPU usage 6/2022
  while (disp_ptr->continueRunningAllThreads) {
    WaitForSingleObject(disp_ptr->newframeroi_event, INFINITE);
    if (!disp_ptr->continueRunningAllThreads) {
      break;
    }
    WaitForSingleObject(disp_ptr->newframeroimutex, INFINITE);
    if (disp_ptr->new_frame_available_roi) {
      ReleaseMutex(disp_ptr->newframeroimutex);
      if (disp_ptr->ROI_Active) {
        disp_ptr->calcROImean();
      }
      if (disp_ptr->Contour_Active) {
        disp_ptr->update_cont_vals();
      }
    } else {
      ReleaseMutex(disp_ptr->newframeroimutex);
    }
    WaitForSingleObject(disp_ptr->newframeroimutex, INFINITE);
    disp_ptr->new_frame_available_roi = false;
    ResetEvent(disp_ptr->newframeroi_event);
    ReleaseMutex(disp_ptr->newframeroimutex);
  }
  _endthreadex(0);
  return 0;
}

// Update contour position based on input coordinates x,y
void StreamDisplayHD::Contour_Update(int x, int y) {
  ROI_Active = false;
  ROI_click_toggle = 0x0;
  if (!contour_click_toggle) {
    Contour_Active = false;
    contour_click_toggle = 0x1;
    Contour_Ends[0].x = x;
    Contour_Ends[0].y = y;
  } else {
    contour_click_toggle = 0x0;
    Contour_Ends[1].x = x;
    Contour_Ends[1].y = y;
    if (!((Contour_Ends[1].x == Contour_Ends[0].x) &&
          (Contour_Ends[1].y == Contour_Ends[0].y))) {
      WaitForSingleObject(ROI_Cont_mutex, INFINITE);
      scale_line(Contour_Ends, Contour_DrawGuides, ScaleX, ScaleY,
                 imgDestRect.x, imgDestRect.y, LINE_THICKNESS);
      refresh_cont_points();

      // Calculate Pythagorean distance
      int dx = Contour_Ends[1].x - Contour_Ends[0].x;
      int dy = Contour_Ends[1].y - Contour_Ends[0].y;
      float distance = sqrt(dx * dx + dy * dy);
      // Convert the distance to a string
      sprintf(distText, "Distance: %.2f pixel", distance);
      double UmDistance = Px_to_um * distance;
      if (UmDistance < 1000) {
        sprintf(UmDistText, "%.2f microns", UmDistance);
      } else if (UmDistance < 10000) {
        sprintf(UmDistText, "%.2f mm", (UmDistance) / 1000);
      } else {
        sprintf(UmDistText, "%.2f cm", (UmDistance) / 10000);
      }

      // const char *debugText = "Debug Text";
      // SDL_Color textColor = {255, 255, 255, 255}; // Yellow color for
      // visibility

      // // Get the width and height of the renderer or window
      // int windowWidth, windowHeight;
      // SDL_GetRendererOutputSize(renderer, &windowWidth, &windowHeight);

      // // Calculate position near the top right corner with a small margin
      // int textX =
      //     windowWidth - 150; // Adjust '150' based on the length of your text
      // int textY = 20;        // Margin from the top

      // // Render the text
      // stringRGBA(renderer, textX, textY, distText, textColor.r, textColor.g,
      //            textColor.b, textColor.a);
    }

    Contour_Active = true;
    ReleaseMutex(ROI_Cont_mutex);
  }
}

// Handle contour line scaling and finite thickness calculations:
void scale_line(SDL_Point *pts_in, SDL_Point *pts_out, float scaleX,
                float scaleY, int ox, int oy, int thickness) {
  SDL_Point scaledin[2];

  scaledin[0].x = (int)((((float)pts_in[0].x) + .5) * scaleX) + ox;
  scaledin[0].y = (int)((((float)pts_in[0].y) + .5) * scaleY) + oy;
  scaledin[1].x = (int)((((float)pts_in[1].x) + .5) * scaleX) + ox;
  scaledin[1].y = (int)((((float)pts_in[1].y) + .5) * scaleY) + oy;

  float lin_dx = (float)pts_in[1].x - pts_in[0].x;
  float lin_dy = (float)pts_in[1].y - pts_in[0].y;
  pts_out[0] = scaledin[0];
  pts_out[1] = scaledin[1];

  float h = (float)sqrt((pow(lin_dx, 2) + pow(lin_dy, 2)));
  float yrat = lin_dy / h;
  float xrat = lin_dx / h;
  if (DEBUG) {
    printf("\n %d %d %d %d \n", pts_out[0].x, pts_out[0].y, pts_out[1].x,
           pts_out[1].y);
  }
  for (int ii = 1; ii < thickness; ii++) {
    pts_out[2 * ii].x = scaledin[0].x + lround(((float)ii) * yrat);
    pts_out[2 * ii].y = scaledin[0].y - lround(((float)ii) * xrat);
    pts_out[2 * ii + 1].x = scaledin[1].x + lround(((float)ii) * yrat);
    pts_out[2 * ii + 1].y = scaledin[1].y - lround(((float)ii) * xrat);
    if (DEBUG) {
      printf("%d %d %d %d \n", pts_out[2 * ii].x, pts_out[2 * ii].y,
             pts_out[2 * ii + 1].x, pts_out[2 * ii + 1].y);
    }
  }
}

// Refresh contour metadata properties.
void StreamDisplayHD::refresh_cont_points() {
  int cpx, cpy;
  float dx = (float)(Contour_Ends[1].x - Contour_Ends[0].x);
  float dy = (float)(Contour_Ends[1].y - Contour_Ends[0].y);
  float length = (float)sqrt(pow(dx, 2) + pow(dy, 2));
  contour_numel = (int)length + 1;
  contavgcounter = 0;
  float x_rat = dx / dy;
  for (int i = 0; i < contour_numel; i++) {
    cpx = Contour_Ends[0].x + lround(((float)i) * dx / length);
    cpy = Contour_Ends[0].y + lround(((float)i) * dy / length);
    contour_pixel_index[i] = (lastImageDataWidth * cpy + cpx);
  }
}

// Calculate average counts along contour
void StreamDisplayHD::update_cont_vals() {
  uint16_t myImageData[MAX_IMG_WIDTH * MAX_IMG_HEIGHT];
  int myImageDataWidth = MAX_IMG_WIDTH;
  int myImageDataHeight = MAX_IMG_HEIGHT;

  WaitForSingleObject(HandoffMutex, INFINITE);
  memcpy(myImageData, lastImageData,
         ((uint64_t)lastImageDataWidth) * ((uint64_t)lastImageDataHeight) *
             sizeof(uint16_t));
  ReleaseMutex(HandoffMutex);

  for (int i = 0; i < contour_numel; i++) {
    if (contavgcounter == 0) {
      contour_buff[i] = (double)myImageData[contour_pixel_index[i]];
    } else {
      contour_buff[i] =
          (double)myImageData[contour_pixel_index[i]] + contour_buff[i];
    }
  }
  if (contavgcounter < numcontavgs) {
    contavgcounter++;
  } else {
    WaitForSingleObject(contourstoremutex, INFINITE);
    memcpy(contour_store, contour_buff, contour_numel * sizeof(double));
    newcontstore = true;
    ReleaseMutex(contourstoremutex);
    contavgcounter = 0;
    if (DEBUG) {
      printf("Contour Vals: \t");
      for (int i = 0; i < contour_numel; i++) {
        printf("%15f \t", contour_store[i]);
      }
      printf("\n");
    }
  }
}

// Update subROI coordinates based on mouse click coordinates.
void StreamDisplayHD::ROI_Update(int x, int y) {
  Contour_Active = false;
  printf("ROI click toggle %d \n", ROI_click_toggle);
  contour_click_toggle = 0x0;

  if (ROI_click_toggle == 0) {
    ROI_Active = false;
    ROI_click_toggle = 1;
    ROIPoints[0].x = x;
    ROIPoints[0].y = y;
  } else if (ROI_click_toggle == 1) {
    ROI_click_toggle = 2;
    ROIPoints[1].x = x;
    ROIPoints[1].y = y;

    // Set ROI_Rect based on ROIPoints[0] and ROIPoints[1]
    if (ROIPoints[0].x < ROIPoints[1].x) {
      ROI_Rect.x = ROIPoints[0].x;
      ROI_Rect.w = ROIPoints[1].x - ROIPoints[0].x;
    } else {
      ROI_Rect.x = ROIPoints[1].x;
      ROI_Rect.w = ROIPoints[0].x - ROIPoints[1].x;
    }
    if (ROIPoints[0].y < ROIPoints[1].y) {
      ROI_Rect.y = ROIPoints[0].y;
      ROI_Rect.h = ROIPoints[1].y - ROIPoints[0].y;
    } else {
      ROI_Rect.y = ROIPoints[1].y;
      ROI_Rect.h = ROIPoints[0].y - ROIPoints[1].y;
    }

    int real_x = ROI_Rect.x, real_y = ROI_Rect.y, real_w = ROI_Rect.w,
        real_h = ROI_Rect.h;

    // ROI should draw where clicked, but account for possible rotations for
    // zooming and ROI means calculation. In stream, flip is applied first,
    // then rotation. To reverse this, first account for rotation, then for
    // flip.

    // Undo rotation
    int temp_x = real_x, temp_y = real_y;
    switch (rotated) {
    case 1: // 90 degrees counterclockwise
      real_x = (temp_y * ScaleY + imgDestRect.y - imgDestRect.x) / ScaleX;
      temp_x = (temp_x * ScaleX + imgDestRect.x - imgDestRect.y) / ScaleY;
      std::swap(real_w, real_h);
      real_y = lastImageDataHeight - 1 - temp_x - real_h;
      break;
    case 2: // 180 degrees
      real_x = lastImageDataWidth - 1 - temp_x - real_w;
      real_y = lastImageDataHeight - 1 - temp_y - real_h;
      break;
    case 3: // 270 degrees counterclockwise (90 degrees clockwise)
      temp_y = (temp_y * ScaleY + imgDestRect.y - imgDestRect.x) / ScaleX;
      real_y = (temp_x * ScaleX + imgDestRect.x - imgDestRect.y) / ScaleY;
      std::swap(real_w, real_h);
      real_x = lastImageDataWidth - 1 - temp_y - real_w;
      break;
    }

    // Undo flip if flipped is true
    if (flipped) {
      real_x = lastImageDataWidth - 1 - real_x - real_w;
    }

    // Set sum_rect to real (untransformed) coordinates
    WaitForSingleObject(ROI_Rect_mutex, INFINITE);
    sum_rect.x = real_x;
    sum_rect.y = real_y;
    sum_rect.w = real_w;
    sum_rect.h = real_h;
    ROI_Active = true;
    ReleaseMutex(ROI_Rect_mutex);

    // Scale and set drawrect based on the transformed ROI_Rect for display
    scale_rect(ROI_Rect, drawrect, ScaleX, ScaleY, imgDestRect.x, imgDestRect.y,
               5);
  } else {
    ROI_Active = false;
    ROI_click_toggle = 0;
  }
}

// Calculate ROI average and sum counts:
void StreamDisplayHD::calcROImean() {
  int i, j;
  double adder = 0;

  uint16_t myImageData[MAX_IMG_WIDTH * MAX_IMG_HEIGHT];

  int myImageDataWidth = MAX_IMG_WIDTH;
  int myImageDataHeight = MAX_IMG_HEIGHT;

  // Copy image data into local variable so that calculations can be performed
  // without image data being changed externally.
  WaitForSingleObject(HandoffMutex, INFINITE);
  memcpy(myImageData, lastImageData,
         ((uint64_t)lastImageDataWidth) * ((uint64_t)lastImageDataHeight) *
             sizeof(uint16_t));
  myImageDataWidth = lastImageDataWidth;
  myImageDataHeight = lastImageDataHeight;
  ReleaseMutex(HandoffMutex);
  // Sum over ROI
  for (i = sum_rect.x; i < sum_rect.x + sum_rect.w + 1; i++) {
    for (j = sum_rect.y; j < sum_rect.y + sum_rect.h + 1; j++) {
      adder += myImageData[i + j * myImageDataWidth];
    }
  }
  // Mean over ROI
  ROImean = adder / (((double)sum_rect.w + 1) * ((double)sum_rect.h + 1));
  // WaitForSingleObject(roidatamutex, INFINITE); //Why commented out?
  roi_buff.put(ROImean);
  roi_sum_buff.put(adder);
  // ReleaseMutex(roidatamutex);
}

// Calculate ROI median:
void StreamDisplayHD::calcROImedian() {
  // Implement later.
}

// Copy Contour or subROI data into *dataout location. Caution. Make sure
// dataout is large enough for entire data transfer.
void StreamDisplayHD::getROIdata(double *dataout) {
  if (ROI_Active) {
    WaitForSingleObject(roidatamutex, INFINITE);
    memcpy(dataout, roimeanstore, roibufferlength * sizeof(double));
    ReleaseMutex(roidatamutex);
  } else {
    WaitForSingleObject(contourstoremutex, INFINITE);
    memcpy(dataout, contour_store, contour_numel * sizeof(double));
    ReleaseMutex(contourstoremutex);
  }
}

// Start SDL window
void StreamDisplayHD::start_SDL_window(uint16_t *windowLocationParams) {
  // Try to initialize SDL Video subsystem
  if (SDL_Init(SDL_INIT_VIDEO) < 0)
    return;
  // Initialize lastImageData with known values
  for (int iy = 0; iy < MAX_IMG_HEIGHT; iy++) {
    for (int ix = 0; ix < MAX_IMG_WIDTH; ix++) {
      lastImageData[iy * MAX_IMG_WIDTH + ix] = 16384; // 0x4000
    }
  }

  if (windowLocationParams) {
    MONITOR_INDEX = windowLocationParams[0];
    SCREEN_WIDTH = windowLocationParams[1];
    SCREEN_HEIGHT = windowLocationParams[2];
    SCREEN_X_POSITION = windowLocationParams[3];
    SCREEN_Y_POSITION = windowLocationParams[4];
  } else {
    SDL_DisplayMode DM;
    SDL_GetCurrentDisplayMode(DEFAULT_MONITOR_INDEX, &DM);
    int MonWidth = DM.w;
    int MonHeight = DM.h;
    MONITOR_INDEX = DEFAULT_MONITOR_INDEX;
    SCREEN_WIDTH = MonWidth / 2;
    SCREEN_HEIGHT = MonWidth / 2;
    SCREEN_X_POSITION = DEFAULT_SCREEN_X_POSITION;
    SCREEN_Y_POSITION = DEFAULT_SCREEN_Y_POSITION;
  }
  SDL_Rect displayBounds;
  SDL_GetDisplayBounds(MONITOR_INDEX, &displayBounds);
  printf("window position set to %d %d %d %d on monitor %d\n",
         displayBounds.x + SCREEN_X_POSITION,
         displayBounds.y + SCREEN_Y_POSITION, SCREEN_WIDTH, SCREEN_HEIGHT,
         MONITOR_INDEX);

  /* Create the window where we will draw. */
  window =
      SDL_CreateWindow("live image", displayBounds.x + SCREEN_X_POSITION,
                       displayBounds.y + SCREEN_Y_POSITION, SCREEN_WIDTH + 160,
                       SCREEN_HEIGHT, SDL_WINDOW_SHOWN);

  /* We must call SDL_CreateRenderer in order for draw calls to affect this
   * window. */
  renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);

  SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, RENDER_SCALE_QUALITY);

  // Set Canvas background to dark gray
  SDL_SetRenderDrawColor(renderer, 64, 64, 64, 255);

  myWork1ImgSurf =
      SDL_CreateRGBSurface(0, MAX_IMG_WIDTH, MAX_IMG_HEIGHT, 8, 0, 0, 0, 0);
  if (myWork1ImgSurf == NULL) {
    SDL_Log("SDL_CreateRGBSurface() failed: %s", SDL_GetError());
    exit(1);
  }
  myWork2ImgSurf =
      SDL_CreateRGBSurface(0, MAX_IMG_WIDTH, MAX_IMG_HEIGHT, 8, 0, 0, 0, 0);
  if (myWork2ImgSurf == NULL) {
    SDL_Log("SDL_CreateRGBSurface() failed: %s", SDL_GetError());
    exit(1);
  }
  SDL_SetPaletteColors(myWork1ImgSurf->format->palette, cmap_pointers[0], 0,
                       256);
  SDL_SetPaletteColors(myWork2ImgSurf->format->palette, cmap_pointers[0], 0,
                       256);

  imgSrcRect.x = 0;
  imgSrcRect.y = 0;
  imgSrcRect.w = MAX_IMG_WIDTH;
  imgSrcRect.h = MAX_IMG_HEIGHT;

  imgDestRect.x = 0;
  imgDestRect.y = 0;
  imgDestRect.w = SCREEN_WIDTH;
  imgDestRect.h =
      SCREEN_WIDTH; // make a square inside of the rectangular screen

  // here to try once and debug with printfs, but they will be run from the
  // threads
  calc_and_update_image();
  printf("display ok\n");
}

// For auto-scaling colormap to intensity max and min of data, we need to
// calculate the max and min over the frames.
void StreamDisplayHD::extractmaxmin(uint16_t *data, uint64_t length) {
  uint16_t max_val = *data;
  uint16_t min_val = *data;
  uint16_t cmap_max;
  uint16_t cmap_min;
  // auto start = high_resolution_clock::now();
  // Iterate along data, update max and min if applicable.
  for (uint64_t x = 0; x < length; x++) {
    if (*data > max_val) {
      max_val = *data;
    } else if (*data < min_val) {
      min_val = *data;
    }
    data++;
  }
  /*auto stop = high_resolution_clock::now();
  auto duration = duration_cast<milliseconds>(stop - start);
  printf("%d\n", duration.count());*/

  // calculate colormap scaling limits
  cmap_max = (uint16_t)lround(max_val * cmap_high);
  cmap_min = (uint16_t)lround(min_val + (max_val - min_val) * cmap_low);
  hiThresholdCounts = cmap_max - 1;
  if (cmap_min == 0) {
    loThresholdCounts = cmap_min;
  } else {
    loThresholdCounts = cmap_min - 1;
  }

  if (cmap_max == cmap_min) {
    cmap_max = cmap_min + 1;
  }
}

// Perform image scaling based on colormap and limits:
// SSE4.1 implementation by F. Phil Brooks III
void StreamDisplayHD::calc_and_update_image() {
  int ix, iy;

  // local data copies to lock only during copy
  // Aligning makes loading into SSE registers easier. Not necessary (use
  // unaligned load and store if not), but since it's easy here, we might as
  // well do it.
  uint16_t __declspec(align(16)) myImageData[MAX_IMG_WIDTH * MAX_IMG_HEIGHT];
  int myImageDataWidth = MAX_IMG_WIDTH;
  int myImageDataHeight = MAX_IMG_HEIGHT;

  // ensure lastImageData read while not writing elsewhere
  WaitForSingleObject(HandoffMutex, INFINITE);
  // make local copy of latest image
  memcpy(myImageData, lastImageData,
         ((uint64_t)lastImageDataWidth) * ((uint64_t)lastImageDataHeight) *
             sizeof(uint16_t));
  myImageDataWidth = lastImageDataWidth;
  myImageDataHeight = lastImageDataHeight;
  // new_frame_available_img = false;
  ReleaseMutex(HandoffMutex);

  // switch between color fixed and auto scale - DI 7/24
  WaitForSingleObject(ReadyImgMutex, INFINITE);
  if (color_fixed) {
    loThresholdCounts = color_fixed_low;
    hiThresholdCounts = color_fixed_high;
  } else {
    extractmaxmin(myImageData,
                  (uint64_t)myImageDataWidth * (uint64_t)myImageDataHeight);
  }
  ReleaseMutex(ReadyImgMutex);

  // toggle and select which buffer to work on (alternate buffers so SDL can
  // display the other one while we load into one).
  imgToggleFlag = !imgToggleFlag;
  // Here, it would be a bit harder to enforce alignment since the array is
  // allocated by SDL, so we'll just use unaligned store when we need to write
  // here.
  workImgSurfBuffer =
      (uint8_t *)(imgToggleFlag ? myWork1ImgSurf : myWork2ImgSurf)->pixels;

  // offsets due to image resizing
  int tox = MAX_IMG_WIDTH / 2 - myImageDataWidth / 2;   // target offset x
  int toy = MAX_IMG_HEIGHT / 2 - myImageDataHeight / 2; // target offset y

  // Constant scaling factor precalculation.
  float constant_factor =
      (float)255 / ((float)hiThresholdCounts - (float)loThresholdCounts);

  // auto start = high_resolution_clock::now();
  // SSE vector intrinsics allow use of SSE vector instructions in c++. These
  // vector instructions allow the CPU to operate on multiple elements of data
  // at once. This can vastly improve efficiency (in this case, 16 pixel
  // operations in the time of 1). Actually, the vectorized instruction flow is
  // a bit more complicated than the scalar version (more separate instructions
  // needed per operation), so it isn't actually a 16x speedup, but it is a
  // ~order of magnitude speedup anyway.
  if (use_sse) {
    // SSE version should work on any processor supporting SSE4.1 (Intel after
    // Penryn (2007/8) and AMD after Bulldozer ('11)).
    int myImageWidth_adjusted =
        myImageDataWidth - 15; // operate on 16 elements at a time
    // Set up arrays of threshold constants in correct format (32 bit signed
    // int).
    __m128i loThresholdCounts_epi32 = _mm_set1_epi32(loThresholdCounts);
    __m128i hiThresholdCounts_epi32 = _mm_set1_epi32(hiThresholdCounts);
    __m128 constantFactor_ps = _mm_set1_ps(constant_factor);
    // For every row:
    for (iy = 0; iy < myImageDataHeight; iy++) {
      int iy_times_width = iy * myImageDataWidth;
      int final_x_baseline =
          (iy + toy) * MAX_IMG_WIDTH +
          tox; // index offset for row in final surface buffer
      // surface buffer is always of max sensor size, and doesn't scale with
      // ROI, so we need to be careful where in that large buffer we place our
      // frame data that comes from a subroi. It is easier to handle if we
      // iterate by row and column separately.

      // iterate over sets of 16 pixels:
      for (ix = 0; ix < myImageWidth_adjusted; ix += 16) {
        // Load sixteen 16-bit int values four at a time into the lower 64 bits
        // of four SSE registers
        __m128i int_data1 =
            _mm_loadl_epi64((__m128i *)&myImageData[iy_times_width + ix]);
        __m128i int_data2 =
            _mm_loadl_epi64((__m128i *)&myImageData[iy_times_width + ix + 4]);
        __m128i int_data3 =
            _mm_loadl_epi64((__m128i *)&myImageData[iy_times_width + ix + 8]);
        __m128i int_data4 =
            _mm_loadl_epi64((__m128i *)&myImageData[iy_times_width + ix + 12]);
        // Zero extend each of the four 16-bit unsigned integers into a 32-bit
        // signed integer in the same register. SSE 4.1. SSE2 version uses __m64
        // type, which is deprecated/unsupported on modern x64 systems.
        int_data1 = _mm_cvtepu16_epi32(int_data1);
        int_data2 = _mm_cvtepu16_epi32(int_data2);
        int_data3 = _mm_cvtepu16_epi32(int_data3);
        int_data4 = _mm_cvtepu16_epi32(int_data4);
        // Do max/min on epi32s as it is significantly faster than for floats
        // Threshold pixel values:
        int_data1 =
            _mm_max_epi32(_mm_min_epi32(int_data1, hiThresholdCounts_epi32),
                          loThresholdCounts_epi32);
        int_data2 =
            _mm_max_epi32(_mm_min_epi32(int_data2, hiThresholdCounts_epi32),
                          loThresholdCounts_epi32);
        int_data3 =
            _mm_max_epi32(_mm_min_epi32(int_data3, hiThresholdCounts_epi32),
                          loThresholdCounts_epi32);
        int_data4 =
            _mm_max_epi32(_mm_min_epi32(int_data4, hiThresholdCounts_epi32),
                          loThresholdCounts_epi32);
        // Subtraction is also faster for ints
        // Subtract lower threshold to 0.
        int_data1 = _mm_sub_epi32(int_data1, loThresholdCounts_epi32);
        int_data2 = _mm_sub_epi32(int_data2, loThresholdCounts_epi32);
        int_data3 = _mm_sub_epi32(int_data3, loThresholdCounts_epi32);
        int_data4 = _mm_sub_epi32(int_data4, loThresholdCounts_epi32);
        // Convert to float (SSE/AVX don't support integer division). Try using
        // SVML divide?
        __m128 f_data1 = _mm_cvtepi32_ps(int_data1);
        __m128 f_data2 = _mm_cvtepi32_ps(int_data2);
        __m128 f_data3 = _mm_cvtepi32_ps(int_data3);
        __m128 f_data4 = _mm_cvtepi32_ps(int_data4);
        // Scale by scaling factor:
        f_data1 = _mm_mul_ps(f_data1, constantFactor_ps);
        f_data2 = _mm_mul_ps(f_data2, constantFactor_ps);
        f_data3 = _mm_mul_ps(f_data3, constantFactor_ps);
        f_data4 = _mm_mul_ps(f_data4, constantFactor_ps);
        // Convert back to int and pack down to 8-bit (we don't need more
        // precision as SDL uses 8-bit precision)
        int_data1 = _mm_cvtps_epi32(f_data1);
        int_data2 = _mm_cvtps_epi32(f_data2);
        int_data3 = _mm_cvtps_epi32(f_data3);
        int_data4 = _mm_cvtps_epi32(f_data4);
        // Pack to two registers of 8 16-bit unsigned ints each.
        int_data1 = _mm_packus_epi32(int_data1, int_data2);
        int_data2 = _mm_packus_epi32(int_data3, int_data4);
        // Pack to one register full of 16 8-bit unsigned ints.
        int_data1 = _mm_packus_epi16(int_data1, int_data2);
        // Store (unaligned this time)
        _mm_storeu_si128((__m128i *)&(workImgSurfBuffer[final_x_baseline + ix]),
                         int_data1);
      }
      // Take care of remaining items in row using scalar instructions.
      for (; ix < myImageDataWidth; ix++) {
        // mind bit-endian-ness here
        float fval = (float)myImageData[iy_times_width + ix];
        fval =
            min(max(fval, loThresholdCounts), hiThresholdCounts); // threshold
        uint8_t val = (uint8_t)((fval - (float)loThresholdCounts) *
                                constant_factor); // subtract and scale
        workImgSurfBuffer[final_x_baseline + ix] = val;
      }
    }
    // If SSE4.1 not supported:
  } else {
    // Scalar version (standard c++ should work on any processor that supports
    // c++)
    for (iy = 0; iy < myImageDataHeight; iy++) {
      // precalculate these to avoid recomputation every inner loop.
      int iy_times_width = iy * myImageDataWidth;
      int final_x_baseline = (iy + toy) * MAX_IMG_WIDTH + tox;
      for (ix = 0; ix < myImageDataWidth; ix++) {
        // mind bit-endian-ness here
        float fval = (float)myImageData[iy_times_width + ix];
        fval = min(max(fval, loThresholdCounts), hiThresholdCounts);
        uint8_t val =
            (uint8_t)((fval - (float)loThresholdCounts) * constant_factor);
        workImgSurfBuffer[final_x_baseline + ix] = val;
      }
    }
  }

  // adjust drawing areas to reflect changes in image size
  imgSrcRect.x = tox;
  imgSrcRect.y = toy;
  imgSrcRect.w = myImageDataWidth;
  imgSrcRect.h = myImageDataHeight;
  float whr = (float)myImageDataWidth / myImageDataHeight; // aspect ratio
  float hwr = (float)1. / whr;
  if (hwr < 1) {
    imgDestRect.x = 0;
    imgDestRect.y = (int)(SCREEN_WIDTH * (1 - hwr) / 2);
    imgDestRect.w = SCREEN_WIDTH;
    imgDestRect.h = (int)(SCREEN_WIDTH * hwr);
  } else {
    imgDestRect.x = (int)(SCREEN_WIDTH * (1 - whr) / 2);
    imgDestRect.y = 0;
    imgDestRect.w = (int)(SCREEN_WIDTH * whr);
    imgDestRect.h = SCREEN_WIDTH;
  }

  // ensure myReadyImgSurf write while not reading elsewhere
  WaitForSingleObject(ReadyImgMutex, INFINITE);
  // set surface pointer to the buffer we just worked on
  myReadyImgSurf = imgToggleFlag ? myWork1ImgSurf : myWork2ImgSurf;
  ready_for_render = true;
  SetEvent(readyforrender_event);
  ReleaseMutex(ReadyImgMutex);

  auto currentTime = std::chrono::steady_clock::now();
  auto timeElapsed = std::chrono::duration_cast<std::chrono::seconds>(
      currentTime - lastCalculationTime);
  if (timeElapsed.count() >= 0.5) {
    WaitForSingleObject(histMutex, INFINITE);
    std::vector<float> histogram;
    calculateHistogram(myImageData, myImageDataWidth, myImageDataHeight,
                       loThresholdCounts, hiThresholdCounts);
    ReleaseMutex(histMutex);
    // Update the timer to the current time after calculation
    lastCalculationTime = currentTime;
  }
}

// Copy subROI coordinates into coordsout (CAUTION: ensure that coordsout is
// large enough)
void StreamDisplayHD::getROIcoords(int coordsout[]) {
  coordsout[0] = ROI_Rect.x;
  coordsout[1] = ROI_Rect.y;
  coordsout[2] = ROI_Rect.w;
  coordsout[3] = ROI_Rect.h;
}

// Helper for checking whether point is in a given box.
bool in_box(int left, int width, int top, int height, int pointx, int pointy) {
  return ((pointx < (left + width + 1)) && (pointx > left) &&
          (pointy < (top + height + 1)) && (pointy > top));
}

// Helper for rectangle coordinate scaling (scale and offset). numrects controls
// how many rectangles are overlayed
//  (each 1 pixel larger than the previous) to give finite thickness of
//  displayed rectangle.
void scale_rect(SDL_Rect rectin, SDL_Rect *rectout, float scaleX, float scaleY,
                int ox, int oy, int numrects) {
  for (int i = 0; i < numrects; i++) {
    rectout[i].x = (int)(rectin.x * scaleX) - i + ox;
    rectout[i].y = (int)(rectin.y * scaleY) - i + oy;
    rectout[i].w = (int)((rectin.w + 1) * scaleX) + 2 * i;
    rectout[i].h = (int)((rectin.h + 1) * scaleY) + 2 * i;
  }
}

void StreamDisplayHD::calculateHistogram(const uint16_t *imageData, int width,
                                         int height, int loThresholdCounts,
                                         int hiThresholdCounts) {
  std::vector<float> temp_histogram;
  temp_histogram.resize(256, 0);
  std::fill(temp_histogram.begin(), temp_histogram.end(), 0);

  // Check for division by zero
  if (hiThresholdCounts == loThresholdCounts) {
    printf(
        "Error: hiThresholdCounts and loThresholdCounts cannot be the same.\n");
    return;
  }
  int sampling = 1;
  int max_samples = 20000;
  if (width * height > max_samples) {
    sampling = std::sqrt((width * height / max_samples));
  };

  // Calculate the histogram
  for (int y = 0; y < height; y = y + sampling) {
    for (int x = 0; x < width; x = x + sampling) {
      uint16_t pixelValue = imageData[y * width + x];

      if (pixelValue < loThresholdCounts || pixelValue > hiThresholdCounts) {
        continue;
      }

      // Calculate the bin position as a floating-point number
      double binPosition = (pixelValue - loThresholdCounts) * 255.0 /
                           (hiThresholdCounts - loThresholdCounts);

      // Calculate the lower and upper bin indices
      int lowerBin = static_cast<int>(floor(binPosition));
      int upperBin = lowerBin + 1;

      // Calculate the fractional part
      double fractionalPart = binPosition - lowerBin;

      // Distribute the counts to lower and upper bins
      if (lowerBin >= 0 && lowerBin < temp_histogram.size()) {
        temp_histogram[lowerBin] += (1.0 - fractionalPart);
      }
      if (upperBin >= 0 && upperBin < temp_histogram.size()) {
        temp_histogram[upperBin] += fractionalPart;
      }
    }
  }

  histogram = temp_histogram;
}

std::vector<uint8_t>
StreamDisplayHD::calculate_cdf(const std::vector<float> &histogram) {
  int num_bins = histogram.size();
  std::vector<uint8_t> cdf(num_bins, 0);

  double total_pixels = 0.0;
  for (const auto &value : histogram) {
    total_pixels += value;
  }

  if (total_pixels == 0) {
    std::fill(cdf.begin(), cdf.end(), 0);
    return cdf;
  }

  // Calculate the cumulative sum of the histogram
  double cumulative = 0.0;
  for (int i = 0; i < num_bins; ++i) {
    cumulative += histogram[i];
    cdf[i] = static_cast<uint8_t>((cumulative / total_pixels) * 255.0);
    // printf("%d", cdf[i]);
  }

  return cdf;
}

void StreamDisplayHD::adjust_colormap_with_cdf(SDL_Color *adjusted_colors,
                                               const SDL_Color *original_colors,
                                               const std::vector<uint8_t> &cdf,
                                               int num_colors) {
  for (int i = 0; i < num_colors; ++i) {
    adjusted_colors[i].r = cdf[original_colors[i].r];
    adjusted_colors[i].g = cdf[original_colors[i].g];
    adjusted_colors[i].b = cdf[original_colors[i].b];
    adjusted_colors[i].a = original_colors[i].a;
  }
}
