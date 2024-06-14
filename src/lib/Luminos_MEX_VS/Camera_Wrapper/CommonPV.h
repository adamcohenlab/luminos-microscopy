/******************************************************************************/
/* Copyright (C) Teledyne Photometrics. All rights reserved.                  */
/******************************************************************************/
#pragma once
#include "Cam_Wrapper.h"
#ifdef KINETIX_CONFIGURED
#ifndef COMMONPV_H_
#define COMMONPV_H_

// System
#include <chrono>
#include <condition_variable>
#include <functional>
#include <mutex>
#include <string>
#include <thread>
#include <vector>

// WriteError
#include <cstring>
#include <fstream>

// PVCAM
#include <master.h>
#include <pvcam.h>

// Application exit code if an error is encountered during the execution
#define APP_EXIT_ERROR 1
#define MAX_MSG_LEN (260 * 8)

// Camera index, used in single-camera code samples, zero-based
constexpr uns16 cSingleCamIndex = 0;
// Number of cameras to use in multi-camera code samples
constexpr uns16 cMultiCamCount = 2;

// Custom value used as a placeholder for an invalid post-processing parameter
// ID
constexpr uns32 cInvalidPpId = (uns32)-1;

/*
 * Common data types
 */

// Name-Value Pair type. Used in various places: when iterating PVCAM enumerable
// parameter types, or for storing GUI selection options.
struct NVP {
  int32 value{0};
  std::string name{};
};
// Name-Value Pair Container type. Holds a list of name-value pairs.
typedef std::vector<NVP> NVPC;

// The camera speed table forms a structure of a tree. Cameras usually have one
// or more 'ports', each port may have one or more 'speeds' (readout rates), and
// each speed may have one or more 'gains'

// This structure holds description of a gain entry.
struct SpdtabGain {
  // In PVCAM, gain indexes are 1-based.
  int32 index{1};
  // Not all cameras support named gains. If not supported, this
  // string stays empty.
  std::string name{};
  // The bit-depth may be different for each gain, therefore it is stored
  // within this structure. For example, the Prime BSI camera has gains
  // with different bit-depths under the same speed.
  int16 bitDepth{0};
};
// This structure holds description of a speed entry.
struct SpdtabSpeed {
  // In PVCAM, speed indexes are 0-based.
  int32 index{0};
  // Pixel time can be used to calculate the overall readout rate. This is less
  // relevant with sCMOS sensors, but the pix time is still reported to provide
  // an approximate readout rate of a particular speed.
  uns16 pixTimeNs{1};
  // List of gains under this particular speed.
  std::vector<SpdtabGain> gains;
};
// This structure holds description of a port entry.
struct SpdtabPort {
  // Please note that the PARAM_READOUT_PORT is an ENUM_TYPE parameter.
  // For this reason, the current port is not reported as an index, but
  // as a generic number. Applications that are written in a generic way
  // to support all Teledyne Photometrics cameras should not rely on a fact
  // that port numbers are usually zero-based.
  int32 value{0};
  // Name of this port, as retrieved by enumerating the PARAM_READOUT_PORT.
  std::string name{};
  // List of speeds under this particular port.
  std::vector<SpdtabSpeed> speeds;
};

// Platform-independent replacement for Windows event
struct Event {
  // Mutex that guards all other members
  std::mutex mutex{};
  // Condition that any thread could wait on
  std::condition_variable cond{};
  // A flag that helps with spurious wakeups
  bool flag{false};
};

// In PVCAM, post-processing parameters are a specific group of camera-reported
// parameters. The list of post processing 'features' and underlying
// 'parameters' needs to be retrieved dynamically after opening the camera. The
// structure of camera post-processing modes forms a tree structure where the
// camera usually provides a list of 'features'. Every 'feature' then contains a
// list of 'parameters'. To navigate in the feature/parameter tree, two
// parameters are used: PARAM_PP_INDEX (for feature traversing) and
// PARAM_PP_PARAM_INDEX (for parameter traversing under a particular feature).
// This is sufficient to display the tree structure in a UI. In order for the
// application to locate a specific PP parameter and set it programmatically,
// two other parameters can be used: PARAM_PP_FEAT_ID and PARAM_PP_PARAM_ID.
// A post-processing parameter itself is then accessed through the
// PARAM_PP_PARAM. This parameter is of an uns32 type, thus, essentially, all PP
// parameters are of the same type. If a boolean switch is reported as a PP
// parameter, it will usually be reported as a generic uns32 type with an
// allowed value range between 0 and 1. The structures below are used to cache
// the post-processing tree structure.

// PVCAM Post-Processing parameter descriptor
struct PvcamPpParameter {
  int16 index{-1};        // PARAM_PP_PARAM_INDEX
  uns32 id{cInvalidPpId}; // PARAM_PP_PARAM_ID
  std::string name{};     // PARAM_PP_PARAM_NAME
  uns32 minValue{0};      // PARAM_PP_PARAM, ATTR_MIN
  uns32 maxValue{0};      // PARAM_PP_PARAM, ATTR_MAX
  uns32 defValue{0};      // PARAM_PP_PARAM, ATTR_DEFAULT
};

// PVCAM Post-Processing feature descriptor
struct PvcamPpFeature {
  int16 index{-1};        // PARAM_PP_INDEX
  uns32 id{cInvalidPpId}; // PARAM_PP_FEAT_ID
  std::string name{};     // PARAM_PP_FEAT_NAME
  std::vector<PvcamPpParameter>
      parameterList{}; // List of underlying parameters
};

// Structure holding camera-related properties, one instance per camera
struct CameraContext {
  // Camera name, the only member valid before opening camera
  char camName[CAM_NAME_LEN]{'\0'};

  // Set to true when PVCAM opens camera
  bool isCamOpen{false};

  // All members below are initialized once the camera is successfully open

  // Camera handle
  int16 hcam{-1};

  // Camera sensor serial size (sensor width)
  uns16 sensorResX{0};
  // Camera sensor parallel size (sensor height)
  uns16 sensorResY{0};
  // Sensor region and binning factors to be used for the acquisition,
  // initialized to full sensor size with 1x1 binning upon opening the camera.
  rgn_type region{0, 0, 0, 0, 0, 0};

  // Vector of camera readout options, commonly referred to as 'speed table'
  std::vector<SpdtabPort> speedTable{};

  // Image format reported after acq. setup, value from PL_IMAGE_FORMATS
  int32 imageFormat{PL_IMAGE_FORMAT_MONO16};
  // Sensor type (if not Frame Transfer CCD then camera is Interline CCD or
  // sCMOS). Not relevant for sCMOS sensors.
  bool isFrameTransfer{false};
  // Flag marking the camera as Smart Streaming capable
  bool isSmartStreaming{false};

  // Event used for communication between acq. loop and EOF callback routine
  Event eofEvent{};
  // Storage for a code sample specific context data if needed for callback
  // acquisition
  void *eofContext{nullptr};
  // Frame info structure used to store data, for example, in EOF callback
  // handlers
  FRAME_INFO eofFrameInfo{};
  // The address of latest frame stored, for example, in EOF callback handlers
  void *eofFrame{nullptr};

  // Used as an acquisition thread or for other independent tasks
  std::thread *thread{nullptr};
  // Flag to be set to abort thread (used, for example, in multi-camera code
  // samples)
  bool threadAbortFlag{false};
};

/*
 * Common function prototypes
 */

// Converts a string to a double precision floating point number
bool StrToDouble(const std::string &str, double &number);

// Converts a string to an unsigned integer number
bool StrToInt(const std::string &str, int &number);

// Returns true together with a value of selected item from the NVPC list.
// When user presses Enter or provides an invalid value, the function returns
// false.
bool GetMenuSelection(const std::string &title, const NVPC &menu,
                      int32 &selection);

// Reads a string from the standard input until Enter/Return key is pressed.
// If ctrl+c is pressed while waiting for the input, the input stream will set
// a fail flag. Use std::cin.fail() check when this function is used together
// with InstallCliTerminationHandler function.
std::string WaitForInput();

// Platform-agnostic version of Windows getch function
int GetCh();
// Platform-agnostic version of Windows getche function
int GetChE();

// Installs custom termination handler function that handles ctrl+c and other
// terminal events. In most cases, the GenericCliTerminationHandler() function
// can be used.
bool InstallCliTerminationHandler(std::function<void()> customHandler);

// Generic handler that sets threadAbortFlag in CameraContext for each open
// camera and uses eofEvent to wake up all possible waiters.
void GenericCliTerminationHandler(const std::vector<CameraContext *> &contexts);

// A helper function that installs the GenericCliTerminationHandler as a deafult
// termination handler.
bool InstallGenericCliTerminationHandler(
    const std::vector<CameraContext *> &contexts);

// Displays application name and version
bool ShowAppInfo(int argc, char *argv[]);

// Retrieves the last PVCAM error code and displays a PVCAM error message
// together with user-provided message.
void PrintErrorMessage(int16 errorCode, const char *message);

// Releases allocated camera contexts and uninitializes the PVCAM library
void UninitPVCAM(std::vector<CameraContext *> &contexts);

// Initializes PVCAM library and allocates camera context for all detected
// cameras
bool InitPVCAM(std::vector<CameraContext *> &contexts);

// Closes given camera if not closed yet
void CloseCamera(CameraContext *ctx);

// Opens given camera if not open yet
bool OpenCamera(CameraContext *ctx);

// Initializes PVCAM library, obtains basic camera availability information,
// opens one camera and retrieves basic camera parameters and characteristics.
bool InitAndOpenOneCamera(std::vector<CameraContext *> &contexts,
                          uns16 camIndex);

// Initializes PVCAM library, gets basic camera availability information,
// opens multiple cameras and retrieves basic camera parameters and
// characteristics. If there are fewer than camCount cameras available, the
// camCount value is updated to the number of currently open cameras.
bool InitAndOpenMultipleCameras(std::vector<CameraContext *> &contexts,
                                uns16 &camCount);

// Closes the camera and uninitializes PVCAM
void CloseAllCamerasAndUninit(std::vector<CameraContext *> &contexts);

// Generic EOF callback handler used in most code samples.
// This is the function registered as a callback function and PVCAM will call it
// every time a new frame arrives.
void PV_DECL GenericEofHandler(FRAME_INFO *pFrameInfo, void *pContext);

// Checks parameter availability
bool IsParamAvailable(int16 hcam, uns32 paramID, const char *paramName);

// Reads name-value pairs for given PVCAM enum-type parameter.
bool ReadEnumeration(int16 hcam, NVPC *pNvpc, uns32 paramID,
                     const char *paramName);

// Builds and returns the camera speed table.
bool GetSpeedTable(const CameraContext *ctx,
                   std::vector<SpdtabPort> &speedTable);

// This function is called after pl_exp_setup_seq and pl_exp_setup_cont
// functions, or after changing value of the selected post-processing
// parameters. The function reads the current image format reported by the
// camera. With most cameras, each pixel is transferred in 2 bytes, up to 16
// bits per pixel. However, selected cameras support 8-bit sensor readouts and
// some post processing features also enable 32-bit image format. The actual bit
// depth, i.e. the number of bits holding pixel values, is still independent and
// reported by PARAM_BIT_DEPTH parameter.
void UpdateCtxImageFormat(CameraContext *ctx);

// Waits for a notification that is usually sent by EOF callback handler.
// Returns false if the event didn't occur before the specified timeout, or when
// user aborted the waiting.
bool WaitForEofEvent(CameraContext *ctx, uns32 timeoutMs, bool &errorOccurred);

// Prints ADU values of the first few pixels in the given buffer
void ShowImage(const CameraContext *ctx, const void *pBuffer, uns32 bufferBytes,
               const char *title = nullptr);

// Saves the image pixels to a file.
// The image is saved as raw data, however it can be imported into ImageJ
// or other applications that allow raw data import.
// For ImageJ, use drag & drop or File->Import->Raw and then specify usually
// 16-bit unsigned type, width & height and Little-endian byte order.
bool SaveImage(const void *pBuffer, uns32 bufferBytes, const char *path);

// Prints the Extended metadata to console output, this function is
// called from PrintMetaFrame() and PrintMetaRoi() as well.
void PrintMetaExtMd(void *pMetaData, uns32 metaDataSize);

// Prints the ROI descriptor to console output, this function is
// called from PrintMetaFrame() as well.
void PrintMetaRoi(const CameraContext *ctx, const md_frame_roi *pRoiDesc);

// Prints the frame descriptor to console output including ROIs
// and Extended metadata structures.
// If printAllRois is false only the first ROI is printed out.
void PrintMetaFrame(const CameraContext *ctx, const md_frame *pFrameDesc,
                    bool printAllRois);

// Reads number from console window
int ConsoleReadNumber(int min, int max, int def);

// If Smart Streaming is supported, enable it and load given exposures to the
// camera.
bool UploadSmartStreamingExposures(const CameraContext *ctx,
                                   const uns32 *pExposures,
                                   uns16 exposuresCount);

// Selects an appropriate exposure mode for use in pl_exp_setup_seq() and
// pl_exp_setup_cont() functions. The function checks whether the camera
// supports the legacy (TIMED_MODE, STROBED_MODE, ...) or extended trigger modes
// (EXT_TRIG_INTERNAL, ...) and returns a correct value together with the first
// expose-out mode option, if applicable. Usually, if an application works with
// one camera model, such dynamic discovery is not required. However, the SDK
// examples are written so that they will function with the older, legacy
// cameras, too.
bool SelectCameraExpMode(const CameraContext *ctx, int16 &expMode,
                         int16 legacyTrigMode, int16 extendedTrigMode);

// This function discovers all camera post-processing features and stores them
// into a list of locally cached descriptors.
std::vector<PvcamPpFeature> DiscoverCameraPostProcessing(CameraContext *ctx);

// This function iterates over the cached PP feature list and returns
// feature index for a given feature ID.
bool FindPpFeatureIndex(const std::vector<PvcamPpFeature> &ppFeatureList,
                        uns32 ppFeatureId, int16 &featIdx);

// This function iterates over the cached PP parameter list and returns
// parameter index for a given parameter ID.
bool FindPpParamIndex(const std::vector<PvcamPpParameter> &ppParameterList,
                      uns32 ppParamId, int16 &paramIdx);

// This function iterates over the cached PP feature list and returns
// feature and parameter indexes for a given parameter ID.
bool FindPpParamIndexes(const std::vector<PvcamPpFeature> &ppFeatureList,
                        uns32 ppParamId, int16 &featIdx, int16 &paramIdx);

// Gets the current value of PP parameter under given feature
bool GetPpParamValue(CameraContext *ctx, int16 featIdx, int16 paramIdx,
                     uns32 &value);

// Sets the new value of PP parameter under given feature
bool SetPpParamValue(CameraContext *ctx, int16 featIdx, int16 paramIdx,
                     uns32 value);

char *rm_dup_slashes(const char *path, char *curr);
#endif // COMMONPV_H_
#endif //KINETIX_CONFIGURED
