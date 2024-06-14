/******************************************************************************/
/* Copyright (C) Teledyne Photometrics. All rights reserved.                  */
/******************************************************************************/
#include "pch.h"
#include "Cam_Wrapper.h"
#ifdef KINETIX_CONFIGURED
#include "CommonPV.h"

// System
#include <algorithm> // std::min
#include <cstring>   // strlen
#include <fstream>
#include <iostream>
#include <limits>
#include <sstream>

#ifdef _WIN32
#include <conio.h>
#include <Windows.h>
#else
#include <signal.h>
#include <termios.h>
#include <unistd.h> // STDIN_FILENO
#endif

// Local
#include "version.h"

/*
 * Module local variables
 */

// A flag that stores the current state of PVCAM library initialization.
static bool s_isPvcamInitialized = false;

// Global variable that holds the OS-native ctrl+c termination handler.
std::function<void()> g_cliTerminationHandler = []() {};

/*
 * Common function implementations
 */

bool StrToDouble(const std::string &str, double &number) {
  try {
    size_t idx;
    number = std::stod(str, &idx);
    if (idx == str.length())
      return true;
  } catch (...) {
  };
  return false;
}

bool StrToInt(const std::string &str, int &number) {
  try {
    size_t idx;
    long nr = std::stoul(str, &idx);
    if (idx == str.length() && nr >= (std::numeric_limits<int>::min)() &&
        nr <= (std::numeric_limits<int>::max)()) {
      number = (int)nr;
      return true;
    }
  } catch (...) {
  };
  return false;
}

// bool GetMenuSelection(const std::string& title, const NVPC& menu, int32&
// selection)
//{
//     const std::string underline(title.length() + 1, '-');
//     printf("\n%s:\n%s\n", title.c_str(), underline.c_str());
//     for (size_t n = 0; n < menu.size(); n++)
//     {
//         printf("%d) %s\n", menu[n].value, menu[n].name.c_str());
//     }
//     printf("Type your choice and press <Enter>: ");
//     const std::string input = WaitForInput();
//     printf("\n");
//
//     if (!StrToInt(input, selection))
//         return false;
//     for (size_t n = 0; n < menu.size(); n++)
//     {
//         if (menu[n].value == selection)
//             return true;
//     }
//     return false;
// }

std::string WaitForInput() {
  std::string str;
  std::cin.clear();
  getline(std::cin, str);
  return str;
}

int GetCh() {
#ifdef _WIN32
  return _getch();
#else
  struct termios oldt;
  tcgetattr(STDIN_FILENO, &oldt); // Grab old terminal I/O settings
  struct termios newt = oldt;     // Make new settings same as old settings
  newt.c_lflag &= ~ICANON;        // Disable buffered I/O
  newt.c_lflag &= ~ECHO;          // Set no echo mode
  tcsetattr(STDIN_FILENO, TCSANOW,
            &newt); // Use these new terminal I/O settings now
  int ch = getchar();
  tcsetattr(STDIN_FILENO, TCSANOW, &oldt);
  return ch;
#endif
}
int GetChE() {
#ifdef _WIN32
  return _getche();
#else
  struct termios oldt;
  tcgetattr(STDIN_FILENO, &oldt); // Grab old terminal I/O settings
  struct termios newt = oldt;     // Make new settings same as old settings
  newt.c_lflag &= ~ICANON;        // Disable buffered I/O
  newt.c_lflag |= ECHO;           // Set echo mode
  tcsetattr(STDIN_FILENO, TCSANOW,
            &newt); // Use these new terminal I/O settings now
  int ch = getchar();
  tcsetattr(STDIN_FILENO, TCSANOW, &oldt);
  return ch;
#endif
}

#if defined(_WIN32)
static BOOL WINAPI ConsoleCtrlHandler(DWORD dwCtrlType) {
  // Return TRUE if handled this message, further handler functions won't be
  // called. Return FALSE to pass this message to further handlers until default
  // handler calls ExitProcess().

  switch (dwCtrlType) {
  case CTRL_C_EVENT:        // Ctrl+C
  case CTRL_BREAK_EVENT:    // Ctrl+Break
  case CTRL_CLOSE_EVENT:    // Closing the console window
  case CTRL_LOGOFF_EVENT:   // User logs off. Passed only to services!
  case CTRL_SHUTDOWN_EVENT: // System is shutting down. Passed only to services!
    break;
  default:
    return FALSE;
  }

  g_cliTerminationHandler();
  return TRUE;
}
#else
static void TerminalSignalHandler(int /*sigNum*/) { g_cliTerminationHandler(); }
#endif
bool InstallCliTerminationHandler(std::function<void()> customHandler) {
  bool retVal;
#if defined(_WIN32)
  retVal = (TRUE == SetConsoleCtrlHandler(ConsoleCtrlHandler, TRUE));
#else
  struct sigaction newAction;
  memset(&newAction, 0, sizeof(newAction));
  newAction.sa_handler = TerminalSignalHandler;
  retVal = true;
  if (0 != sigaction(SIGINT, &newAction, NULL) ||
      0 != sigaction(SIGHUP, &newAction, NULL) ||
      0 != sigaction(SIGTERM, &newAction, NULL)) {
    retVal = false;
  }
#endif
  if (retVal) {
    g_cliTerminationHandler = customHandler;
  }
  return retVal;
}

void GenericCliTerminationHandler(
    const std::vector<CameraContext *> &contexts) {
  for (CameraContext *ctx : contexts) {
    if (!ctx || !ctx->isCamOpen)
      continue;

    {
      std::unique_lock<std::mutex> lock(ctx->eofEvent.mutex);
      if (ctx->threadAbortFlag)
        continue;
      ctx->threadAbortFlag = true;
      printf(">>> Requesting ABORT on camera %d\n", ctx->hcam);
    }
    ctx->eofEvent.cond.notify_all();
  }
  printf(">>>\n\n");
}

bool InstallGenericCliTerminationHandler(
    const std::vector<CameraContext *> &contexts) {
  return InstallCliTerminationHandler(
      std::bind(GenericCliTerminationHandler, std::cref(contexts)));
}

bool ShowAppInfo(int argc, char *argv[]) {
  const char *appName = "<unable to get app name>";
  if (argc > 0 && argv && argv[0]) {
    appName = argv[0];
  }

  // Read PVCAM library version
  uns16 pvcamVersion;
  if (PV_OK != pl_pvcam_get_ver(&pvcamVersion)) {
    PrintErrorMessage(pl_error_code(), "pl_pvcam_get_ver() error");
    return false;
  }

  printf("************************************************************\n");
  printf("Application  : %s\n", appName);
  printf("App. version : %d.%d.%d\n", VERSION_MAJOR, VERSION_MINOR,
         VERSION_BUILD);
  printf("PVCAM version: %d.%d.%d\n", (pvcamVersion >> 8) & 0xFF,
         (pvcamVersion >> 4) & 0x0F, (pvcamVersion >> 0) & 0x0F);
  printf("************************************************************\n\n");

  return true;
}

void PrintErrorMessage(int16 errorCode, const char *message) {
  char pvcamErrMsg[ERROR_MSG_LEN];
  pl_error_message(errorCode, pvcamErrMsg);
  printf("%s\n  Error code: %d\n  Error message: %s\n", message, errorCode,
         pvcamErrMsg);
}

void UninitPVCAM(std::vector<CameraContext *> &contexts) {
  if (!s_isPvcamInitialized)
    return;

  // Release allocated memory
  for (CameraContext *ctx : contexts) {
    delete ctx;
  }
  contexts.clear();

  // Uninitialize the PVCAM library
  if (PV_OK != pl_pvcam_uninit()) {
    PrintErrorMessage(pl_error_code(), "pl_pvcam_uninit() error");
  } 
  s_isPvcamInitialized = false;
}

bool InitPVCAM(std::vector<CameraContext *> &contexts) {
  if (s_isPvcamInitialized)
    return true;

  // Initialize PVCAM library
  if (PV_OK != pl_pvcam_init()) {
    PrintErrorMessage(pl_error_code(), "pl_pvcam_init() error");
    return false;
  }
  s_isPvcamInitialized = true;

  contexts.clear();
  int16 nrOfCameras;

  // Read the number of cameras in the system.
  // This will return total number of PVCAM cameras regardless of interface.
  if (PV_OK != pl_cam_get_total(&nrOfCameras)) {
    PrintErrorMessage(pl_error_code(), "pl_cam_get_total() error");
    UninitPVCAM(contexts);
    return false;
  }

  // Exit if no cameras have been found
  if (nrOfCameras <= 0) {
    UninitPVCAM(contexts);
    return false;
  }

  // Create context structure for all cameras and fill in the PVCAM camera
  // names
  contexts.reserve(nrOfCameras);
  for (int16 i = 0; i < nrOfCameras; i++) {
    CameraContext *ctx = new (std::nothrow) CameraContext();
    if (!ctx) {
      UninitPVCAM(contexts);
      return false;
    }

    // Obtain PVCAM-name for this particular camera
    if (PV_OK != pl_cam_get_name(i, ctx->camName)) {
      PrintErrorMessage(pl_error_code(), "pl_cam_get_name() error");
      UninitPVCAM(contexts);
      return false;
    }

    contexts.push_back(ctx);
  }

  return true;
}

void CloseCamera(CameraContext *ctx) {
  if (!ctx->isCamOpen)
    return;

  if (PV_OK != pl_cam_close(ctx->hcam)) {
    PrintErrorMessage(pl_error_code(), "pl_cam_close() error");
  } else {
    printf("Camera %d '%s' closed\n", ctx->hcam, ctx->camName);
  }
  ctx->isCamOpen = false;
}

bool OpenCamera(CameraContext *ctx) {
  if (ctx->isCamOpen)
    return true;

  // Open a camera with a given name and retrieve its handle. From now on,
  // only the handle will be used when referring to this particular camera.
  // The name is obtained in InitPVCAM() function when listing all cameras
  // in the system.
  if (PV_OK != pl_cam_open(ctx->camName, &ctx->hcam, OPEN_EXCLUSIVE)) {
    return false;
  }
  ctx->isCamOpen = true;
  printf("Camera %d '%s' opened\n", ctx->hcam, ctx->camName);
  // Read the version of the Device Driver
  if (!IsParamAvailable(ctx->hcam, PARAM_DD_VERSION, "PARAM_DD_VERSION")) {
    return false;
  }
  uns16 ddVersion;
  if (PV_OK != pl_get_param(ctx->hcam, PARAM_DD_VERSION, ATTR_CURRENT,
                            (void *)&ddVersion)) {
    PrintErrorMessage(pl_error_code(), "pl_get_param(PARAM_DD_VERSION) error");
    return false;
  }
  printf("  Device driver version: %d.%d.%d\n", (ddVersion >> 8) & 0xFF,
         (ddVersion >> 4) & 0x0F, (ddVersion >> 0) & 0x0F);

  // Historically, the chip name also included camera model name and it was
  // commonly used as camera identifier. On recent cameras, the camera model
  // name should be read from PARAM_PRODUCT_NAME.
  if (!IsParamAvailable(ctx->hcam, PARAM_CHIP_NAME, "PARAM_CHIP_NAME"))
    return false;
  char chipName[CCD_NAME_LEN];
  if (PV_OK != pl_get_param(ctx->hcam, PARAM_CHIP_NAME, ATTR_CURRENT,
                            (void *)chipName)) {
    PrintErrorMessage(pl_error_code(), "pl_get_param(PARAM_CHIP_NAME) error");
    return false;
  }
  printf("  Sensor chip name: %s\n", chipName);

  // Read the camera firmware version
  if (!IsParamAvailable(ctx->hcam, PARAM_CAM_FW_VERSION,
                        "PARAM_CAM_FW_VERSION"))
    return false;
  uns16 fwVersion;
  if (PV_OK != pl_get_param(ctx->hcam, PARAM_CAM_FW_VERSION, ATTR_CURRENT,
                            (void *)&fwVersion)) {
    PrintErrorMessage(pl_error_code(),
                      "pl_get_param(PARAM_CAM_FW_VERSION) error");
    return false;
  }

  // Initialize the acquisition region to the full sensor size
  ctx->region.s1 = 0;
  ctx->region.s2 = ctx->sensorResX - 1;
  ctx->region.sbin = 1;
  ctx->region.p1 = 0;
  ctx->region.p2 = ctx->sensorResY - 1;
  ctx->region.pbin = 1;

  // Reset PP features to their default values.
  // Ignore errors, this call could fail if the camera does not
  // support post-processing.
  pl_pp_reset(ctx->hcam);

  // Build and cache the camera speed table
  if (!GetSpeedTable(ctx, ctx->speedTable))
    return false;

  // Speed table has been created, print it out
  printf("  Speed table:\n");
  for (const auto &port : ctx->speedTable) {
    printf("  - port '%s', value %d\n", port.name.c_str(), port.value);
    for (const auto &speed : port.speeds) {
      printf("    - speed index %d, running at %f MHz\n", speed.index,
             1000 / (float)speed.pixTimeNs);
      for (const auto &gain : speed.gains) {
        printf("      - gain index %d, %sbit-depth %d bpp\n", gain.index,
               (gain.name.empty()) ? "" : ("'" + gain.name + "', ").c_str(),
               gain.bitDepth);
      }
    }
  }
  printf("\n");

  // Initialize the camera to the first port, first speed and first gain

  if (PV_OK != pl_set_param(ctx->hcam, PARAM_READOUT_PORT,
                            (void *)&ctx->speedTable[0].value)) {
    PrintErrorMessage(pl_error_code(), "Readout port could not be set");
    return false;
  }
  printf("  Setting readout port to '%s'\n", ctx->speedTable[0].name.c_str());

  if (PV_OK != pl_set_param(ctx->hcam, PARAM_SPDTAB_INDEX,
                            (void *)&ctx->speedTable[0].speeds[0].index)) {
    PrintErrorMessage(pl_error_code(), "Readout port could not be set");
    return false;
  }
  printf("  Setting readout speed index to %d\n",
         ctx->speedTable[0].speeds[0].index);

  if (PV_OK !=
      pl_set_param(ctx->hcam, PARAM_GAIN_INDEX,
                   (void *)&ctx->speedTable[0].speeds[0].gains[0].index)) {
    PrintErrorMessage(pl_error_code(), "Gain index could not be set");
    return false;
  }
  printf("  Setting gain index to %d\n",
         ctx->speedTable[0].speeds[0].gains[0].index);

  printf("\n");

  // Set the number of sensor clear cycles to 2 (default).
  // This is mostly relevant to CCD cameras only and it has
  // no effect with CLEAR_NEVER or CLEAR_AUTO clearing modes
  // typically used with sCMOS cameras.
  if (!IsParamAvailable(ctx->hcam, PARAM_CLEAR_CYCLES, "PARAM_CLEAR_CYCLES"))
    return false;
  uns16 clearCycles = 2;
  if (PV_OK !=
      pl_set_param(ctx->hcam, PARAM_CLEAR_CYCLES, (void *)&clearCycles)) {
    PrintErrorMessage(pl_error_code(),
                      "pl_set_param(PARAM_CLEAR_CYCLES) error");
    return false;
  }

  // Find out if the sensor is a frame transfer or other (typically interline)
  // type. This process is relevant for CCD cameras only.
  ctx->isFrameTransfer = false;
  rs_bool isFrameTransfer;
  if (PV_OK != pl_get_param(ctx->hcam, PARAM_FRAME_CAPABLE, ATTR_AVAIL,
                            (void *)&isFrameTransfer)) {
    isFrameTransfer = FALSE;
    PrintErrorMessage(pl_error_code(),
                      "pl_get_param(PARAM_FRAME_CAPABLE) error");
    return false;
  }
  if (isFrameTransfer) {
    if (PV_OK != pl_get_param(ctx->hcam, PARAM_FRAME_CAPABLE, ATTR_CURRENT,
                              (void *)&isFrameTransfer)) {
      isFrameTransfer = FALSE;
      PrintErrorMessage(pl_error_code(),
                        "pl_get_param(PARAM_FRAME_CAPABLE) error");
      return false;
    }
    ctx->isFrameTransfer = isFrameTransfer == TRUE;
  }
  if (ctx->isFrameTransfer) {
    printf("  Camera with Frame Transfer capability sensor\n");
  } else {
    printf("  Camera without Frame Transfer capability sensor\n");
  }

  // If this is a Frame Transfer sensor set PARAM_PMODE to PMODE_FT.
  // The other common mode for these sensors is PMODE_ALT_FT.
  if (!IsParamAvailable(ctx->hcam, PARAM_PMODE, "PARAM_PMODE"))
    return false;
  if (ctx->isFrameTransfer) {
    int32 PMode = PMODE_FT;
    if (PV_OK != pl_set_param(ctx->hcam, PARAM_PMODE, (void *)&PMode)) {
      PrintErrorMessage(pl_error_code(), "pl_set_param(PARAM_PMODE) error");
      return false;
    }
  }
  // If not a Frame Transfer sensor (i.e. Interline), set PARAM_PMODE to
  // PMODE_NORMAL, or PMODE_ALT_NORMAL.
  else {
    int32 PMode = PMODE_NORMAL;
    if (PV_OK != pl_set_param(ctx->hcam, PARAM_PMODE, (void *)&PMode)) {
      PrintErrorMessage(pl_error_code(), "pl_set_param(PARAM_PMODE) error");
      return false;
    }
  }

  // Check if the camera supports Smart Streaming feature.
  if (!IsParamAvailable(ctx->hcam, PARAM_SMART_STREAM_MODE,
                        "PARAM_SMART_STREAM_MODE")) {
    printf("  Smart Streaming is not available\n");
    ctx->isSmartStreaming = false;
  } else {
    printf("  Smart Streaming is available\n");
    ctx->isSmartStreaming = true;
  }

  printf("\n");
  return true;
}

bool InitAndOpenOneCamera(std::vector<CameraContext *> &contexts,
                          uns16 camIndex) {
  if (!InitPVCAM(contexts)) {
    if (contexts.size() > 0 && contexts[0] != nullptr) {
      std::string cameraName(contexts[0]->camName);
    }
    return false;
  }

  if (camIndex >= contexts.size()) {
    printf("Camera index #%u is invalid\n", camIndex);
    UninitPVCAM(contexts);
    return false;
  }

  CameraContext *ctx = contexts[camIndex];
  if (!OpenCamera(ctx)) {
    CloseCamera(ctx);
    UninitPVCAM(contexts);
    return false;
  }
  return true;
}

bool InitAndOpenMultipleCameras(std::vector<CameraContext *> &contexts,
                                uns16 &camCount) {
  if (!InitPVCAM(contexts))
    return false;

  const uns16 nrOfCameras = std::min<uns16>((uns16)contexts.size(), camCount);
  if (contexts.size() > camCount) {
    printf("Detected more cameras than configured for this sample. Only %u "
           "cameras will be used.\n\n",
           nrOfCameras);
  } else if (contexts.size() < camCount) {
    printf("Detected fewer cameras than configured for this sample. Only %u "
           "cameras will be used.\n\n",
           nrOfCameras);
  }
  camCount = nrOfCameras;

  for (uns16 i = 0; i < camCount; i++) {
    CameraContext *ctx = contexts[i];
    if (!OpenCamera(ctx)) {
      for (uns16 j = 0; j <= i; j++) {
        CameraContext *ctx2 = contexts[j];
        CloseCamera(ctx2);
      }
      UninitPVCAM(contexts);
      camCount = 0;
      return false;
    }
  }

  return true;
}

void CloseAllCamerasAndUninit(std::vector<CameraContext *> &contexts) {
  printf("\n");

  for (CameraContext *ctx : contexts) {
    CloseCamera(ctx);
  }

  UninitPVCAM(contexts);

  printf("\nPress <Enter> to exit");
  WaitForInput();
}

void PV_DECL GenericEofHandler(FRAME_INFO *pFrameInfo, void *pContext) {
  if (!pContext)
    return;
  auto ctx = static_cast<CameraContext *>(pContext);

  // Store the frame information for later use
  ctx->eofFrameInfo = *pFrameInfo;

  // Obtain a pointer to the last acquired frame
  if (PV_OK != pl_exp_get_latest_frame(ctx->hcam, &ctx->eofFrame)) {
    PrintErrorMessage(pl_error_code(), "pl_exp_get_latest_frame() error");
    ctx->eofFrame = nullptr;
  }

  // Unblock the acquisition thread
  {
    std::lock_guard<std::mutex> lock(ctx->eofEvent.mutex);
    ctx->eofEvent.flag = true;
  }
  ctx->eofEvent.cond.notify_all();
}

bool IsParamAvailable(int16 hcam, uns32 paramID, const char *paramName) {
  if (!paramName)
    return false;

  rs_bool isAvailable;
  if (PV_OK != pl_get_param(hcam, paramID, ATTR_AVAIL, (void *)&isAvailable)) {
    printf("Error reading ATTR_AVAIL of %s\n", paramName);
    return false;
  }
  if (isAvailable == FALSE) {
    printf("Parameter %s is not available\n", paramName);
    return false;
  }

  return true;
}

bool ReadEnumeration(int16 hcam, NVPC *pNvpc, uns32 paramID,
                     const char *paramName) {
  if (!pNvpc || !paramName)
    return false;

  if (!IsParamAvailable(hcam, paramID, paramName))
    return false;

  uns32 count;
  if (PV_OK != pl_get_param(hcam, paramID, ATTR_COUNT, (void *)&count)) {
    const std::string msg =
        "pl_get_param(" + std::string(paramName) + ") error";
    PrintErrorMessage(pl_error_code(), msg.c_str());
    return false;
  }

  NVPC nvpc;
  for (uns32 i = 0; i < count; ++i) {
    // Retrieve the enum string length
    uns32 strLength;
    if (PV_OK != pl_enum_str_length(hcam, paramID, i, &strLength)) {
      const std::string msg =
          "pl_enum_str_length(" + std::string(paramName) + ") error";
      PrintErrorMessage(pl_error_code(), msg.c_str());
      return false;
    }

    // Allocate the destination string
    char *name = new (std::nothrow) char[strLength];
    if (!name) {
      printf("Unable to allocate memory for %s enum item name\n", paramName);
      return false;
    }

    // Get the string and value
    int32 value;
    if (PV_OK != pl_get_enum_param(hcam, paramID, i, &value, name, strLength)) {
      const std::string msg =
          "pl_get_enum_param(" + std::string(paramName) + ") error";
      PrintErrorMessage(pl_error_code(), msg.c_str());
      delete[] name;
      return false;
    }

    NVP nvp;
    nvp.value = value;
    nvp.name = name;
    nvpc.push_back(nvp);

    delete[] name;
  }
  pNvpc->swap(nvpc);

  return !pNvpc->empty();
}

bool GetSpeedTable(const CameraContext *ctx,
                   std::vector<SpdtabPort> &speedTable) {
  std::vector<SpdtabPort> table;

  NVPC ports;
  if (!ReadEnumeration(ctx->hcam, &ports, PARAM_READOUT_PORT,
                       "PARAM_READOUT_PORT"))
    return false;

  if (!IsParamAvailable(ctx->hcam, PARAM_SPDTAB_INDEX, "PARAM_SPDTAB_INDEX"))
    return false;
  if (!IsParamAvailable(ctx->hcam, PARAM_PIX_TIME, "PARAM_PIX_TIME"))
    return false;
  if (!IsParamAvailable(ctx->hcam, PARAM_GAIN_INDEX, "PARAM_GAIN_INDEX"))
    return false;
  if (!IsParamAvailable(ctx->hcam, PARAM_BIT_DEPTH, "PARAM_BIT_DEPTH"))
    return false;

  rs_bool isGainNameAvailable;
  if (PV_OK != pl_get_param(ctx->hcam, PARAM_GAIN_NAME, ATTR_AVAIL,
                            (void *)&isGainNameAvailable)) {
    printf("Error reading ATTR_AVAIL of PARAM_GAIN_NAME\n");
    return false;
  }
  const bool isGainNameSupported = isGainNameAvailable != FALSE;

  // Iterate through available ports and their speeds
  for (size_t pi = 0; pi < ports.size(); pi++) {
    // Set readout port
    if (PV_OK !=
        pl_set_param(ctx->hcam, PARAM_READOUT_PORT, (void *)&ports[pi].value)) {
      PrintErrorMessage(pl_error_code(),
                        "pl_set_param(PARAM_READOUT_PORT) error");
      return false;
    }

    // Get number of available speeds for this port
    uns32 speedCount;
    if (PV_OK != pl_get_param(ctx->hcam, PARAM_SPDTAB_INDEX, ATTR_COUNT,
                              (void *)&speedCount)) {
      PrintErrorMessage(pl_error_code(),
                        "pl_get_param(PARAM_SPDTAB_INDEX) error");
      return false;
    }

    SpdtabPort port;
    port.value = ports[pi].value;
    port.name = ports[pi].name;

    // Iterate through all the speeds
    for (int16 si = 0; si < (int16)speedCount; si++) {
      // Set camera to new speed index
      if (PV_OK != pl_set_param(ctx->hcam, PARAM_SPDTAB_INDEX, (void *)&si)) {
        PrintErrorMessage(pl_error_code(),
                          "pl_set_param(PARAM_SPDTAB_INDEX) error");
        return false;
      }

      // Get pixel time (readout time of one pixel in nanoseconds) for the
      // current port/speed pair. This can be used to calculate readout
      // frequency of the port/speed pair.
      uns16 pixTime;
      if (PV_OK != pl_get_param(ctx->hcam, PARAM_PIX_TIME, ATTR_CURRENT,
                                (void *)&pixTime)) {
        PrintErrorMessage(pl_error_code(),
                          "pl_get_param(PARAM_PIX_TIME) error");
        return false;
      }

      uns32 gainCount;
      if (PV_OK != pl_get_param(ctx->hcam, PARAM_GAIN_INDEX, ATTR_COUNT,
                                (void *)&gainCount)) {
        PrintErrorMessage(pl_error_code(),
                          "pl_get_param(PARAM_GAIN_INDEX) error");
        return false;
      }

      SpdtabSpeed speed;
      speed.index = si;
      speed.pixTimeNs = pixTime;

      // Iterate through all the gains, notice it starts at value 1!
      for (int16 gi = 1; gi <= (int16)gainCount; gi++) {
        // Set camera to new gain index
        if (PV_OK != pl_set_param(ctx->hcam, PARAM_GAIN_INDEX, (void *)&gi)) {
          PrintErrorMessage(pl_error_code(),
                            "pl_set_param(PARAM_GAIN_INDEX) error");
          return false;
        }

        // Get bit depth for the current gain
        int16 bitDepth;
        if (PV_OK != pl_get_param(ctx->hcam, PARAM_BIT_DEPTH, ATTR_CURRENT,
                                  (void *)&bitDepth)) {
          PrintErrorMessage(pl_error_code(),
                            "pl_get_param(PARAM_BIT_DEPTH) error");
          return false;
        }

        SpdtabGain gain;
        gain.index = gi;
        gain.bitDepth = bitDepth;

        if (isGainNameSupported) {
          char gainName[MAX_GAIN_NAME_LEN];
          if (PV_OK != pl_get_param(ctx->hcam, PARAM_GAIN_NAME, ATTR_CURRENT,
                                    (void *)gainName)) {
            PrintErrorMessage(pl_error_code(),
                              "pl_get_param(PARAM_GAIN_NAME) error");
            return false;
          }

          gain.name = gainName;
        }

        speed.gains.push_back(gain);
      }

      port.speeds.push_back(speed);
    }

    table.push_back(port);
  }

  speedTable.swap(table);
  return true;
}

void UpdateCtxImageFormat(CameraContext *ctx) {
  ctx->imageFormat = PL_IMAGE_FORMAT_MONO16;

  rs_bool isAvailable;
  if (PV_OK != pl_get_param(ctx->hcam, PARAM_IMAGE_FORMAT, ATTR_AVAIL,
                            (void *)&isAvailable))
    return;
  if (isAvailable == FALSE)
    return;

  int32 imageFormat;
  if (PV_OK != pl_get_param(ctx->hcam, PARAM_IMAGE_FORMAT, ATTR_CURRENT,
                            (void *)&imageFormat))
    return;

  ctx->imageFormat = imageFormat;
}

bool WaitForEofEvent(CameraContext *ctx, uns32 timeoutMs, bool &errorOccurred) {
  std::unique_lock<std::mutex> lock(ctx->eofEvent.mutex);

  errorOccurred = false;
  ctx->eofEvent.cond.wait_for(
      lock, std::chrono::milliseconds(timeoutMs),
      [ctx]() { return ctx->eofEvent.flag || ctx->threadAbortFlag; });
  if (ctx->threadAbortFlag) {
    printf("Processing aborted on camera %d\n", ctx->hcam);
    return false;
  }
  if (!ctx->eofEvent.flag) {
    printf("Camera %d timed out waiting for a frame\n", ctx->hcam);
    errorOccurred = true;
    return false;
  }
  ctx->eofEvent.flag = false; // Reset flag

  if (!ctx->eofFrame) {
    errorOccurred = true;
    return false;
  }

  return true;
}

template <typename T>
std::string BufferToStrT(const T *pBuffer, uns32 bufferBytes, uns32 maxItems) {
  const uns32 itemCount = std::min<uns32>(maxItems, bufferBytes / sizeof(T));

  std::ostringstream ss;
  for (uns32 n = 0; n < itemCount; ++n) {
    // The unary plus operator is necessary to print also uns8 as number, not as
    // char
    ss << " " << +pBuffer[n];
  }
  return ss.str();
}

std::string BufferToStr(const CameraContext *ctx, const void *pBuffer,
                        uns32 bufferBytes, uns32 maxItems = 5) {
  switch (ctx->imageFormat) {
  case PL_IMAGE_FORMAT_MONO8:
  case PL_IMAGE_FORMAT_BAYER8:
    return BufferToStrT(reinterpret_cast<const uns8 *>(pBuffer), bufferBytes,
                        maxItems);
  case PL_IMAGE_FORMAT_MONO16:
  case PL_IMAGE_FORMAT_BAYER16:
    return BufferToStrT(reinterpret_cast<const uns16 *>(pBuffer), bufferBytes,
                        maxItems);
  case PL_IMAGE_FORMAT_MONO32:
  case PL_IMAGE_FORMAT_BAYER32:
    return BufferToStrT(reinterpret_cast<const uns32 *>(pBuffer), bufferBytes,
                        maxItems);
  default:
    return " <unsupported image format>";
  }
}

void ShowImage(const CameraContext *ctx, const void *pBuffer, uns32 bufferBytes,
               const char *title) {
  std::string subTitle;
  if (title && strlen(title) > 0) {
    subTitle += std::string(", ") + title;
  }

  const auto values = BufferToStr(ctx, pBuffer, bufferBytes);
  printf("  First few pixel values of the frame%s:%s\n", subTitle.c_str(),
         values.c_str());
}

bool SaveImage(const void *pBuffer, uns32 bufferBytes, const char *path) {
  std::ofstream stream(path, std::ios::binary);
  if (!stream.is_open()) {
    printf("Unable to open '%s' for writing\n", path);
    return false;
  }
  try {
    stream.write(reinterpret_cast<const char *>(pBuffer), bufferBytes);
  } catch (const std::exception &e) {
    printf("Failed to write data to file:\n  %s\n", e.what());
    return false;
  }
  return true;
}

void PrintMetaExtMd(void *pMetaData, uns32 metaDataSize) {
  printf("============================= EXTENDED ROI METADATA "
         "===========================\n");
  md_ext_item_collection extMdCol;
  if (PV_OK != pl_md_read_extended(&extMdCol, pMetaData, metaDataSize)) {
    PrintErrorMessage(pl_error_code(), "pl_md_read_extended() error");
    return;
  }

  for (int i = 0; i < extMdCol.count; ++i) {
    std::stringstream str;
    str << " TAG " << extMdCol.list[i].tagInfo->tag << ": "
        << "'" << extMdCol.list[i].tagInfo->name << "': ";
    switch (extMdCol.list[i].tagInfo->type) {
    case TYPE_UNS32:
      str << *(uns32 *)extMdCol.list[i].value;
      break;
    case TYPE_UNS8:
      str << (int)*(uns8 *)extMdCol.list[i].value;
      break;
    case TYPE_UNS16:
      str << *(uns16 *)extMdCol.list[i].value;
      break;
    case TYPE_FLT64:
      str << *(flt64 *)extMdCol.list[i].value;
      break;
    default:
      str << "Unsupported value type (" << extMdCol.list[i].tagInfo->type
          << ")";
      break;
    }
    str << std::endl;

    printf("%s", str.str().c_str());
  }
}

void PrintMetaRoi(const CameraContext *ctx, const md_frame_roi *pRoiDesc) {
  printf("================================ ROI DESCRIPTOR "
         "===============================\n");
  printf(" DataSize:%u, ExtMdDataSize:%u\n", pRoiDesc->dataSize,
         pRoiDesc->extMdDataSize);
  printf("================================== ROI HEADER "
         "=================================\n");
  md_frame_roi_header *pRoiHdr = pRoiDesc->header;
  const rgn_type &roi = pRoiHdr->roi;
  printf(
      " RoiNr:%u, Roi:[%u,%u,%u,%u,%u,%u], ExtendedMdSize:%u, Flags:0x%02x\n",
      pRoiHdr->roiNr, roi.s1, roi.s2, roi.sbin, roi.p1, roi.p2, roi.pbin,
      pRoiHdr->extendedMdSize, pRoiHdr->flags);
  printf("TimestampBOR:%u, TimestampEOR:%u\n", pRoiHdr->timestampBOR,
         pRoiHdr->timestampEOR);
  if (pRoiDesc->extMdDataSize > 0) {
    PrintMetaExtMd(pRoiDesc->extMdData, pRoiDesc->extMdDataSize);
  }
  printf("=================================== ROI DATA "
         "==================================\n");
  const auto values = BufferToStr(ctx, pRoiDesc->data, pRoiDesc->dataSize, 10);
  printf("  %s\n", values.c_str());
}

void PrintMetaFrame(const CameraContext *ctx, const md_frame *pFrameDesc,
                    bool printAllRois) {
  const rgn_type &impRoi = pFrameDesc->impliedRoi;
  const md_frame_header *pFrameHdr = pFrameDesc->header;
  printf("=============================== FRAME DESCRIPTOR "
         "==============================\n");
  printf(" RoiCount:%u, Implied ROI:[%u,%u,%u,%u,%u,%u]\n",
         pFrameDesc->roiCount, impRoi.s1, impRoi.s2, impRoi.sbin, impRoi.p1,
         impRoi.p2, impRoi.pbin);
  printf("================================= FRAME HEADER "
         "================================\n");
  printf(" FrameNr:%u, RoiCount:%u, BitDepth:%u, Version:%u, Flags:0x%02x\n",
         pFrameHdr->frameNr, pFrameHdr->roiCount, pFrameHdr->bitDepth,
         pFrameHdr->version, pFrameHdr->flags);
  printf(" ExpTime:%u, ExpTimeResNs:%u, TimestampBOF:%u, TimestampEOF:%u\n",
         pFrameHdr->exposureTime, pFrameHdr->exposureTimeResNs,
         pFrameHdr->timestampBOF, pFrameHdr->timestampEOF);
  printf(" TimestampResNs:%u, RoiTimestampResNs:%u, ExtendedMdSz:%u\n",
         pFrameHdr->timestampResNs, pFrameHdr->roiTimestampResNs,
         pFrameHdr->extendedMdSize);
  if (pFrameDesc->extMdDataSize > 0) {
    PrintMetaExtMd(pFrameDesc->extMdData, pFrameDesc->extMdDataSize);
  }
  if (printAllRois) {
    for (uns32 i = 0; i < pFrameDesc->roiCount; ++i) {
      PrintMetaRoi(ctx, &pFrameDesc->roiArray[i]);
    }
  } else {
    PrintMetaRoi(ctx, &pFrameDesc->roiArray[0]);
  }
  printf("====================================================================="
         "==========\n");
}

int ConsoleReadNumber(int min, int max, int def) {
  int number;
  printf("\n");
  for (;;) {
    printf("Enter number [%d - %d] or hit <Enter> for default (%d): ", min, max,
           def);
    const std::string numStr = WaitForInput();

    // If zero length is received the user simply pressed <Enter>
    if (numStr.length() == 0) {
      number = def;
      break;
    }

    if (!StrToInt(numStr, number)) {
      printf("  Not a number. Please retry.\n");
      continue;
    }
    if (number < min || number > max) {
      printf("  Number out of range. Please retry.\n");
      continue;
    }
    break;
  }
  printf("\n");
  return number;
}

bool UploadSmartStreamingExposures(const CameraContext *ctx,
                                   const uns32 *pExposures,
                                   uns16 exposuresCount) {
  if (!ctx->isSmartStreaming) {
    printf("Camera %d does not support Smart Streaming\n", ctx->hcam);
    return false;
  }

  if (!pExposures || exposuresCount == 0) {
    printf("No Smart Streaming exposures given for camera %d\n", ctx->hcam);
    return false;
  }

  if (!IsParamAvailable(ctx->hcam, PARAM_SMART_STREAM_MODE_ENABLED,
                        "PARAM_SMART_STREAM_MODE_ENABLED"))
    return false;
  if (!IsParamAvailable(ctx->hcam, PARAM_SMART_STREAM_EXP_PARAMS,
                        "PARAM_SMART_STREAM_EXP_PARAMS"))
    return false;

  // Enable Smart Streaming in the camera
  rs_bool enableSS = TRUE;
  if (PV_OK != pl_set_param(ctx->hcam, PARAM_SMART_STREAM_MODE_ENABLED,
                            (void *)&enableSS)) {
    PrintErrorMessage(pl_error_code(),
                      "pl_set_param(PARAM_SMART_STREAM_MODE_ENABLED) error");
    return false;
  }
  printf("Smart Streaming enabled successfully on camera %d\n", ctx->hcam);

  // The application should check the total number of supported exposures
  // the smart streaming feature supports. Each camera may support different
  // number of exposures.
  // The maximum number of exposures is retrieved from the 'entries' field in
  // the smart streaming structure when querying the camera for the ATTR_MAX
  // attribute.
  smart_stream_type maxExposuresStruct;
  if (PV_OK != pl_get_param(ctx->hcam, PARAM_SMART_STREAM_EXP_PARAMS, ATTR_MAX,
                            (void *)&maxExposuresStruct)) {
    PrintErrorMessage(
        pl_error_code(),
        "pl_get_param(PARAM_SMART_STREAM_EXP_PARAMS, ATTR_MAX) error");
    return false;
  }

  // Limit the number of exposures if needed
  const uns16 maxExposures =
      std::min<uns16>(maxExposuresStruct.entries, exposuresCount);

  // Prepare the structure and fill in the values
  smart_stream_type exposuresStruct;
  exposuresStruct.entries = maxExposures;
  exposuresStruct.params = (uns32 *)pExposures;
  // Send the data to the camera
  if (PV_OK != pl_set_param(ctx->hcam, PARAM_SMART_STREAM_EXP_PARAMS,
                            (void *)&exposuresStruct)) {
    PrintErrorMessage(pl_error_code(),
                      "pl_set_param(PARAM_SMART_STREAM_EXP_PARAMS) error");
    return false;
  }

  printf("Smart Streaming parameters loaded correctly on camera %d\n",
         ctx->hcam);
  return true;
}

bool SelectCameraExpMode(const CameraContext *ctx, int16 &expMode,
                         int16 legacyTrigMode, int16 extendedTrigMode) {
  NVPC triggerModes;
  if (!ReadEnumeration(ctx->hcam, &triggerModes, PARAM_EXPOSURE_MODE,
                       "PARAM_EXPOSURE_MODE")) {
    return false;
  }
  // Try to find the legacy mode first
  for (const NVP &nvp : triggerModes) {
    if (nvp.value == legacyTrigMode) {
      // If this is a legacy (mostly CCD) camera, return the legacy mode
      expMode = legacyTrigMode;
      return true;
    }
  }

  // If not, select the extended mode and choose the first expose-out mode.
  for (const NVP &nvp : triggerModes) {
    if (nvp.value == extendedTrigMode) {
      // Modern cameras should all support the expose-out mode, but let's make
      // sure.
      if (!IsParamAvailable(ctx->hcam, PARAM_EXPOSE_OUT_MODE,
                            "PARAM_EXPOSE_OUT_MODE")) {
        expMode = extendedTrigMode;
        return true;
      }
      // Select the first available expose-out mode. For the SDK example
      // purposes, the expose-out mode is not crucial as it controls the
      // expose-out hardware signal.
      NVPC expOutModes;
      if (!ReadEnumeration(ctx->hcam, &expOutModes, PARAM_EXPOSE_OUT_MODE,
                           "PARAM_EXPOSE_OUT_MODE")) {
        return false;
      }
      // Select the first one
      const int16 expOutMode = static_cast<int16>(expOutModes[0].value);
      // And return our final 'exp' mode that can be used in pl_exp_setup
      // functions. The final mode is an 'or-ed' value of exposure (trigger)
      // mode and expose-out mode.
      expMode = extendedTrigMode | expOutMode;
      return true;
    }
  }

  // If nothing was selected in the previous loop, then something had to fail.
  // This is a serious and unlikely error. The camera must support either
  // the legacy mode or the new extended trigger mode.
  printf("ERROR: Failed to select camera exposure mode!\n");
  return false;
}

std::vector<PvcamPpFeature> DiscoverCameraPostProcessing(CameraContext *ctx) {
  std::vector<PvcamPpFeature> ppFeatureList; // This is our feature list

  // Determine the number of post processing features that are available
  uns32 ppFeatureCount;
  if (PV_OK !=
      pl_get_param(ctx->hcam, PARAM_PP_INDEX, ATTR_COUNT, &ppFeatureCount)) {
    PrintErrorMessage(pl_error_code(),
                      "pl_get_param(PARAM_PP_INDEX, ATTR_COUNT) error");
    return std::vector<PvcamPpFeature>(); // return empty list
  }

  // Iterate over all the camera PP features
  for (int16 ppFeatureIndex = 0; ppFeatureIndex < (int16)ppFeatureCount;
       ppFeatureIndex++) {
    PvcamPpFeature
        ppFeature; // Store all the information about this feature here

    // Set index to a particular feature
    if (PV_OK != pl_set_param(ctx->hcam, PARAM_PP_INDEX, &ppFeatureIndex)) {
      PrintErrorMessage(pl_error_code(), "pl_set_param(PARAM_PP_INDEX) error");
      return std::vector<PvcamPpFeature>();
    }
    // Now we can identify this feature, get the name, ID, and its parameters.
    char ppFeatureName[MAX_PP_NAME_LEN];
    if (PV_OK != pl_get_param(ctx->hcam, PARAM_PP_FEAT_NAME, ATTR_CURRENT,
                              ppFeatureName)) {
      PrintErrorMessage(pl_error_code(),
                        "pl_get_param(PARAM_PP_FEAT_NAME, ATTR_CURRENT) error");
      return std::vector<PvcamPpFeature>();
    }
    uns32 ppFeatureID;
    if (PV_OK !=
        pl_get_param(ctx->hcam, PARAM_PP_FEAT_ID, ATTR_CURRENT, &ppFeatureID)) {
      // Some features might not report the ID
      printf("PP feature '%s' doesn't report its ID\n", ppFeatureName);
      ppFeatureID = cInvalidPpId;
    }

    // Store the information for future reference
    ppFeature.index = ppFeatureIndex;
    ppFeature.id = ppFeatureID;
    ppFeature.name = ppFeatureName;

    // Now discover how many parameters this particular feature provides
    uns32 ppParamCount;
    if (PV_OK != pl_get_param(ctx->hcam, PARAM_PP_PARAM_INDEX, ATTR_COUNT,
                              &ppParamCount)) {
      PrintErrorMessage(pl_error_code(),
                        "pl_get_param(PARAM_PP_PARAM_INDEX, ATTR_COUNT) error");
      return std::vector<PvcamPpFeature>();
    }

    for (int16 ppParamIndex = 0; ppParamIndex < (int16)ppParamCount;
         ppParamIndex++) {
      PvcamPpParameter
          ppParam; // Store all the information about this parameter here

      // Set index to a particular post processing parameter
      if (PV_OK !=
          pl_set_param(ctx->hcam, PARAM_PP_PARAM_INDEX, &ppParamIndex)) {
        PrintErrorMessage(pl_error_code(),
                          "pl_set_param(PARAM_PP_PARAM_INDEX) error");
        return std::vector<PvcamPpFeature>();
      }

      // Get the parameter Name
      char ppParamName[MAX_PP_NAME_LEN];
      if (PV_OK != pl_get_param(ctx->hcam, PARAM_PP_PARAM_NAME, ATTR_CURRENT,
                                ppParamName)) {
        PrintErrorMessage(
            pl_error_code(),
            "pl_get_param(PARAM_PP_PARAM_NAME, ATTR_CURRENT) error");
        return std::vector<PvcamPpFeature>();
      }
      // Get the parameter ID
      uns32 ppParamID;
      if (PV_OK != pl_get_param(ctx->hcam, PARAM_PP_PARAM_ID, ATTR_CURRENT,
                                &ppParamID)) {
        // Some features might not report the ID
        printf("PP parameter '%s' under '%s' feature doesn't report its ID\n",
               ppParamName, ppFeatureName);
        ppParamID = cInvalidPpId;
      }
      // The minimum value of the parameter
      uns32 minValue;
      if (PV_OK !=
          pl_get_param(ctx->hcam, PARAM_PP_PARAM, ATTR_MIN, &minValue)) {
        PrintErrorMessage(pl_error_code(),
                          "pl_get_param(PARAM_PP_PARAM, ATTR_MIN) error");
        return std::vector<PvcamPpFeature>();
      }
      // The maximum value of the parameter
      uns32 maxValue;
      if (PV_OK !=
          pl_get_param(ctx->hcam, PARAM_PP_PARAM, ATTR_MAX, &maxValue)) {
        PrintErrorMessage(pl_error_code(),
                          "pl_get_param(PARAM_PP_PARAM, ATTR_MAX) error");
        return std::vector<PvcamPpFeature>();
      }
      // The default value of the parameter
      uns32 defValue;
      if (PV_OK !=
          pl_get_param(ctx->hcam, PARAM_PP_PARAM, ATTR_DEFAULT, &defValue)) {
        PrintErrorMessage(pl_error_code(),
                          "pl_get_param(PARAM_PP_PARAM, ATTR_DEFAULT) error");
        return std::vector<PvcamPpFeature>();
      }

      ppParam.index = ppParamIndex;
      ppParam.id = ppParamID;
      ppParam.name = ppParamName;
      ppParam.minValue = minValue;
      ppParam.maxValue = maxValue;
      ppParam.defValue = defValue;

      ppFeature.parameterList.push_back(ppParam);
    }

    ppFeatureList.push_back(ppFeature);
  }
  return ppFeatureList;
}

bool FindPpFeatureIndex(const std::vector<PvcamPpFeature> &ppFeatureList,
                        uns32 ppFeatureId, int16 &featIdx) {
  for (const PvcamPpFeature &ppFeature : ppFeatureList) {
    if (ppFeature.id != cInvalidPpId && ppFeature.id == ppFeatureId) {
      featIdx = ppFeature.index;
      return true;
    }
  }
  return false;
}

bool FindPpParamIndex(const std::vector<PvcamPpParameter> &ppParameterList,
                      uns32 ppParamId, int16 &paramIdx) {
  for (const PvcamPpParameter &ppParam : ppParameterList) {
    if (ppParam.id != cInvalidPpId && ppParam.id == ppParamId) {
      paramIdx = ppParam.index;
      return true;
    }
  }
  return false;
}

bool FindPpParamIndexes(const std::vector<PvcamPpFeature> &ppFeatureList,
                        uns32 ppParamId, int16 &featIdx, int16 &paramIdx) {
  for (const PvcamPpFeature &ppFeature : ppFeatureList) {
    for (const PvcamPpParameter &ppParam : ppFeature.parameterList) {
      if (ppParam.id != cInvalidPpId && ppParam.id == ppParamId) {
        featIdx = ppFeature.index;
        paramIdx = ppParam.index;
        return true;
      }
    }
  }
  return false;
}

bool GetPpParamValue(CameraContext *ctx, int16 featIdx, int16 paramIdx,
                     uns32 &value) {
  // Tell the camera we want to work with the feature and parameter on given
  // index Set the feature index first
  if (PV_OK != pl_set_param(ctx->hcam, PARAM_PP_INDEX, &featIdx)) {
    PrintErrorMessage(pl_error_code(), "pl_set_param(PARAM_PP_INDEX) error");
    return false;
  }
  // Then set the param index
  if (PV_OK != pl_set_param(ctx->hcam, PARAM_PP_PARAM_INDEX, &paramIdx)) {
    PrintErrorMessage(pl_error_code(),
                      "pl_set_param(PARAM_PP_PARAM_INDEX) error");
    return false;
  }
  // Now we can access the parameter
  if (PV_OK != pl_get_param(ctx->hcam, PARAM_PP_PARAM, ATTR_CURRENT, &value)) {
    PrintErrorMessage(pl_error_code(), "pl_get_param(PARAM_PP_PARAM) error");
    return false;
  }
  return true;
}

bool SetPpParamValue(CameraContext *ctx, int16 featIdx, int16 paramIdx,
                     uns32 value) {
  // Tell the camera we want to work with the feature and parameter on given
  // index Set the feature index first
  if (PV_OK != pl_set_param(ctx->hcam, PARAM_PP_INDEX, &featIdx)) {
    PrintErrorMessage(pl_error_code(), "pl_set_param(PARAM_PP_INDEX) error");
    return false;
  }
  // Then set the param index
  if (PV_OK != pl_set_param(ctx->hcam, PARAM_PP_PARAM_INDEX, &paramIdx)) {
    PrintErrorMessage(pl_error_code(),
                      "pl_set_param(PARAM_PP_PARAM_INDEX) error");
    return false;
  }
  // Now we can access the parameter
  if (PV_OK != pl_set_param(ctx->hcam, PARAM_PP_PARAM, &value)) {
    PrintErrorMessage(pl_error_code(), "pl_set_param(PARAM_PP_PARAM) error");
    return false;
  }
  return true;
}

char *rm_dup_slashes(const char *path, char *curr) {
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

#endif //KINETIX_CONFIGURED
