#pragma once

#include "Cam_Control.h"
#include <cmath>
#include <vector>
#include <algorithm>
#include "Circular_Buffer.h"

// for std::string
#include <string>
#include <cstring>
#include <fstream>

unsigned __stdcall framecheck(void *pArguments);
unsigned __stdcall disp_wrapper(void *pArguments);
unsigned __stdcall calc_wrapper(void *pArguments);
unsigned __stdcall SDL_Event_wrapper(void *pArguments);
unsigned __stdcall roi_calc_wrapper(void *pArguments);
unsigned __stdcall DispCalcHD(void *pArguments);
unsigned __stdcall disphandoffThreadFcn(void *pArguments);
void scale_rect(SDL_Rect rectin, SDL_Rect *rectout, float scaleX, float scaleY,
                int ox, int oy, int numrects);
bool in_box(int left, int width, int top, int height, int pointx, int pointy);
void scale_line(SDL_Point *pts_in, SDL_Point *pts_out, float scaleX,
                float scaleY, int ox, int oy, int thickness);

// The following ifdef block is the standard way of creating macros which make
// exporting from a DLL simpler. All files within this DLL are compiled with the
// LUMINOSCAMERA_EXPORTS symbol defined on the command line. This symbol should
// not be defined on any project that uses this DLL. This way any other project
// whose source files include this file see LUMINOSCAMERA_API functions as being
// imported from a DLL, whereas this DLL sees symbols defined with this macro as
// being exported.
#ifdef LUMINOSCAMERA_EXPORTS
#define LUMINOSCAMERA_API __declspec(dllexport)
#else
#define LUMINOSCAMERA_API __declspec(dllimport)
#endif

class LUMINOSCAMERA_API StreamDisplayHD {
public:
  // Initializes variables
  StreamDisplayHD();
  // Deallocates memory
  ~StreamDisplayHD();
  void refresh_cont_points(void);
  void attach_camera(Streaming_Device *cam_in);
  void update_rendering(void);
  void extractmaxmin(uint16_t *data, uint64_t length);
  void cleanup(void);
  void start_SDL_window(uint16_t *windowLocationParams);
  void calc_and_update_image();
  void ROI_Update(int x, int y);
  void launch_disp_threads(void);
  void calcROImean(void);
  void calcROImedian(void);
  void Contour_Update(int x, int y);
  void Colorbar();
  void Histogram();
  void update_cont_vals();
  void getROIdata(double *dataout);
  void getROIcoords(int coordsout[]);
  void keyresponse(SDL_Keycode key);
  void Launch_Handoff_Thread();
  void calculateHistogram(const uint16_t *imageData, int width, int height,
                          int loThresholdCounts, int hiThresholdCounts);
  std::vector<uint8_t> calculate_cdf(const std::vector<float> &histogram);
  void adjust_colormap_with_cdf(SDL_Color *adjusted_colors,
                                const SDL_Color *original_colors,
                                const std::vector<uint8_t> &cdf,
                                int num_colors);
  // Deallocates texture
  void free_all();
  // threads
  float ScaleX, ScaleY;
  bool continueRunningAllThreads;

  HANDLE ROI_Rect_mutex;
  HANDLE readyforrender_event;
  HANDLE ReadyImgMutex;
  HANDLE ghMutexLims;
  HANDLE HandoffMutex;
  HANDLE ghMutexCapturing;
  HANDLE renderingMutex;
  HANDLE calcthread;
  HANDLE dispthread;
  HANDLE ROIthread;
  HANDLE framecheckthread;
  HANDLE newframeavailable_event;
  HANDLE newframemutex;
  HANDLE newframeroi_event;
  HANDLE newframeroimutex;
  HANDLE newframeimg_event;
  HANDLE newframeimgmutex;
  HANDLE ROI_Cont_mutex;
  HANDLE roidatamutex;
  HANDLE contourstoremutex;
  HANDLE disp_handoff_thread;
  SDL_Window *window;
  uint16_t *lastImageData;
  int lastImageDataWidth;
  int lastImageDataHeight;
  uint32_t loThresholdCounts;
  uint32_t hiThresholdCounts;
  bool imgToggleFlag;
  SDL_Surface *myReadyImgSurf;
  SDL_Surface *myWork1ImgSurf;
  SDL_Surface *myWork2ImgSurf;
  SDL_Surface *ROI_Ready_Surf;
  SDL_PixelFormat *pixel_fmt;
  // uint32_t* tempImgBufferRGBA;
  uint32_t *tempROIBufferRGBA;
  bool ROI_on;
  SDL_Point ROIPoints[2];
  SDL_Event interaction_event;
  HANDLE sd_thread;
  bool ready_for_render;
  bool new_frame_available;
  bool new_frame_available_roi;
  bool new_frame_available_img;
  bool ROI_Active;
  SDL_Rect ROI_Rect;
  SDL_Rect drawrect[5];
  SDL_Rect sum_rect;
  bool ROI_Buff_Toggle_Flag;
  int ROI_click_toggle;
  double ROImean;
  double *roimeanstore;
  double *ROImeanvec;
  // double* roibuffptr;
  uint16_t roibufferlength;
  SDL_Point Contour_Ends[2];
  SDL_Point *Contour_DrawGuides;
  SDL_FPoint *contour_points;
  int contour_numel;
  int *contour_pixel_index;
  bool Contour_Active;
  bool contour_click_toggle;
  double *contour_store;
  double *contour_buff;
  int numcontavgs;
  int contavgcounter;
  Streaming_Device *cam;
  bool cam_attached;
  int keydelta;
  uint16_t MONITOR_INDEX;
  uint16_t SCREEN_WIDTH;
  uint16_t SCREEN_HEIGHT;
  uint16_t SCREEN_X_POSITION;
  uint16_t SCREEN_Y_POSITION;
  SDL_Rect imgDestRect;
  // double* roibufftail;
  double cmap_high;
  double cmap_low;
  // bool roibuff_full;
  // bool roibuff_empty;
  Circular_Buffer<double> roi_buff;
  Circular_Buffer<double> roi_sum_buff;
  bool newcontstore;
  SDL_Palette *cPalette;
  SDL_Color jet_colors[256];
  SDL_Color grey_colors[256];
  SDL_Color grey_inverted_colors[256];
  SDL_Color hot_colors[256];
  SDL_Color **cmap_pointers;
  int cmap_index;
  std::vector<float> histogram;
  HANDLE histMutex;
  // Timer for histogram plotting, update once every 500ms
  std::chrono::steady_clock::time_point lastCalculationTime;

  // Time since last keyboard press for stability
  uint32_t lastKeyPressTime;

  static double Px_to_um;
  bool color_fixed;
  int color_fixed_low;
  int color_fixed_high;
  bool equalized;

  bool flipped;
  int rotated;


private:
  // The actual hardware texture
  SDL_Texture *myImgTex;
  SDL_Texture *ROITex;
  SDL_Renderer *renderer;
  void *mPixels;
  int mPitch;
  SDL_Rect imgSrcRect;

  uint8_t *workImgSurfBuffer;

  bool cleaned_up;
  unsigned handoffthreadid;

  // Image dimensions
  int mWidth;
  int mHeight;

  // Supports SSE4.1?
  bool use_sse;

  // Text for distance measurements
  char distText[64];
  char UmDistText[64];

};
