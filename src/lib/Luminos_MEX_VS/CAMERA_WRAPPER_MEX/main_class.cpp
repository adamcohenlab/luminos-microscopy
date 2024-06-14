/*MEX interface for Camera_wrapper C++ class.
 MEX interfaces expose a MEX function to MATLAB that allows Matlab to call
 low-level code. The official way to generate MEX files (from within Matlab) is
 inflexible and not fully-functioned. This is an example of how to generate MEX
 files externally that can be called from MATLAB.*/
#include "mex.hpp"
#include "mexAdapter.hpp"
#include "class_handle.h"
#include "Cam_Wrapper.h"
#include <cstdlib>
#include <cstdio>
#include <iostream>
#include <cstring>
#include <string>

// Helper Macros
#define STREQ(x, y) !(std::strcmp(x.c_str(), y))
#define MPRINT(eng, fac, x)                                                    \
  eng->feval(u"display", 0,                                                    \
             std::vector<Array>(                                               \
                 {fac.createScalar(x)})) // Print to Matlab command line
#define MERROR(eng, fac, x)                                                    \
  eng->feval(                                                                  \
      u"error", 0,                                                             \
      std::vector<Array>({fac.createScalar(x)})) // Raise Error in Matlab.
using namespace matlab::data;
using matlab::mex::ArgumentList;

//! Extracts the pointer to underlying data from the non-const iterator
//! (`TypedIterator<T>`). TypedIterators are defined in Matlab's 'extern'
//! library for interfacing to Matlab objects.
/*! This function does not throw any exceptions. */
template <typename T>
inline T *toPointer(const matlab::data::TypedIterator<T> &it) MW_NOEXCEPT {
  static_assert(
      std::is_arithmetic<T>::value && !std::is_const<T>::value,
      "Template argument T must be a std::is_arithmetic and non-const type.");
  return it.operator->();
}

template <typename T>
inline T *getPointer(matlab::data::TypedArray<T> &arr) MW_NOEXCEPT {
  static_assert(std::is_arithmetic<T>::value,
                "Template argument T must be a std::is_arithmetic type.");
  return toPointer(arr.begin());
}
template <typename T>
inline const T *getPointer(const matlab::data::TypedArray<T> &arr) MW_NOEXCEPT {
  return getPointer(const_cast<matlab::data::TypedArray<T> &>(arr));
}

// The Main MEXFunction class that all MEX calls will be to (subfunctionality is
// specified by arguments to the MEX call)
class MexFunction : public matlab::mex::Function {
private:
  ArrayFactory factory;
  std::shared_ptr<matlab::engine::MATLABEngine> matlabPtr;

  // void foo(int n, const double* a, const double* b, double* c) {
  //     int i;
  //     for (i = 0; i < n; i++)
  //         c[i] = a[i] * b[i];
  // }
  void displayOnMATLAB(std::ostringstream &stream) {
    // Pass stream content to MATLAB fprintf function
    matlabPtr->feval(u"fprintf", 0,
                     std::vector<Array>({factory.createScalar(stream.str())}));
    // Clear stream buffer
    stream.str("");
  }
  std::ostringstream stream;

public:
  MexFunction()
      : matlabPtr(getEngine()) {} // constructor: get Matlab engine handle
  ~MexFunction() {}               // destructor
  void operator()(
      ArgumentList outputs,
      ArgumentList inputs) { // Main MexFunction operator (this gets called when
                             // the MEX library is called from Matlab)
    int n = (int)inputs[0].getNumberOfElements();
    std::string cmd = CharArray(inputs[0]).toAscii();

    // Check for at least two inputs. Otherwise, the call is ignored.
    // First input is command string
    if (inputs.size() > 1) {
      if (STREQ(cmd, "new")) {
        // Second input is camera type string (0,1,2,...)
        const TypedArray<uint16_t> camtypearr = std::move(inputs[1]);
        uint16_t camtype = camtypearr[0];
        // Optional third input is cam_id string (serial number)
        std::string cam_id;
        if (inputs.size() > 2) {
          cam_id = CharArray(inputs[2]).toAscii();

        } else {
          cam_id = "\0";
        }

        mexLock();
        // create new Cam_Wrapper and convert to Matlab-compatible handle.
        uint64_t instance_handle = convertPtr2Mat<Cam_Wrapper>(
            new Cam_Wrapper((int)camtype, cam_id.c_str()));
        outputs[0] = factory.createScalar<uint64_t>(
            instance_handle); // return Matlab handle to new Cam_Wrapper
        return;
      }

      // For all other commands (except "new"), second argument should be the
      // handle of the Cam_Wrapper object that was returned by "new"
      const TypedArray<uint64_t> B = std::move(inputs[1]);
      uint64_t handl = B[0];
      Cam_Wrapper *instance = convertMat2Ptr<Cam_Wrapper>(handl);

      // Return pointer to contents of liveDisplay subROI mean buffer.
      if (STREQ(cmd, "Get_ROI_Buffer")) {
        auto len = instance->ROI_Buff_Avail();
        auto nn = factory.createArray<double>({1, (uint64_t)len});
        auto roiptr = getPointer(nn);
        instance->Get_ROI_Buffer(roiptr, len);
        outputs[0] = nn;
        return;
      }

      // Return pointer to contents of liveDisplay subROI sum buffer.
      if (STREQ(cmd, "Get_ROI_Sum_Buffer")) {
        auto len = instance->ROI_Sum_Buff_Avail();
        auto nn = factory.createArray<double>({1, (uint64_t)len});
        auto roiptr = getPointer(nn);
        instance->Get_ROI_Sum_Buffer(roiptr, len);
        outputs[0] = nn;
        return;
      }

      // Return pointer to snapshot image from camera.
      if (STREQ(cmd, "GetSnap")) {
        int32 *roiptr = (int32 *)malloc(4 * sizeof(int32));
        instance->GetROI(roiptr);
        if (roiptr) {
          int numpixels = roiptr[1] * roiptr[3];
          auto nn = factory.createArray<uint16_t>(
              {(uint64_t)roiptr[1], (uint64_t)roiptr[3]});
          auto dataptr = getPointer(nn);
          instance->GetSnap(dataptr, numpixels);
          outputs[0] = nn;
        } else {
          MERROR(matlabPtr, factory,
                 "Error: CAMERA_WRAPPER_MEX GetSnap: Null pointer returned by "
                 "GetROI");
        }
        return;
      }

      // Return pointer to array containing camera ROI position.
      if (STREQ(cmd, "Get_ROI")) {
        auto nn = factory.createArray<int32_t>({1, 4});
        auto roiptr = getPointer(nn);
        instance->GetROI((int32 *)roiptr);
        outputs[0] = nn;
        return;
      }

      // Return pointer to array containing live Display sub-ROI rectangle
      // position.
      if (STREQ(cmd, "Get_SumRect")) {
        auto nn = factory.createArray<int32_t>({1, 4});
        auto roiptr = getPointer(nn);
        instance->GetSumRect((int32 *)roiptr);
        outputs[0] = nn;
        return;
      }

      // Prepare synchronous acquisition.
      // Third argument is exposure time (s)
      // Fourth is desired ROI
      // Fifth is desired pixel binning
      if (STREQ(cmd, "Prepare_Sync_Aq")) {
        const TypedArray<double> expArray = std::move(inputs[2]);
        double exposuretime = expArray[0];
        const TypedArray<int32_t> ROIin = std::move(inputs[3]);
        auto roiptr = getPointer(ROIin);
        const TypedArray<uint32_t> binArray = std::move(inputs[4]);
        uint32_t binning = binArray[0];
        instance->Prepare_Sync_Acquisition(exposuretime, (int32 *)roiptr,
                                           binning);
        return;
      }

      // Set exposure time (seconds)
      if (STREQ(cmd, "Set_Exposure")) {
        const TypedArray<double> expArray = std::move(inputs[2]);
        double exposuretime = expArray[0];
        auto nn =
            factory.createScalar<double>(instance->Set_Exposure(exposuretime));
        outputs[0] = nn;
        return;
      }

      // Set Rdrive mode (boolean). True= save image to R: drive. False=save
      // image to file on disk.
      if (STREQ(cmd, "RDArray")) {
        const TypedArray<bool> RDArray = std::move(inputs[2]);
        bool RD = RDArray[0];
        instance->Set_RDrive_Mode(RD);
        return;
      }

      // Return exposure time (s)
      if (STREQ(cmd, "Get_Exposure")) {
        auto nn = factory.createScalar<double>(instance->Get_Exposure());
        outputs[0] = nn;
        return;
      }

      // Set camera ROI position (third argument is pointer to array of ROI
      // position (x, w, y, h). Returns pointer to resulting ROI position (may
      // be different depending on camera constraints)
      if (STREQ(cmd, "Set_ROI")) {
        const TypedArray<int32_t> ROIin = std::move(inputs[2]);
        auto roiptr = getPointer(ROIin);
        instance->Set_ROI((int32 *)roiptr);
        auto nn = factory.createArray<int32_t>({1, 4});
        auto roiptro = getPointer(nn);
        instance->GetROI((int32 *)roiptro);
        outputs[0] = nn;
        return;
      }

      // Set specified binning level
      if (STREQ(cmd, "Set_Binning")) {
        const TypedArray<uint32_t> binArray = std::move(inputs[2]);
        uint32_t binning = binArray[0];
        instance->Set_Binning(binning);
        return;
      }

      // Get current binning level
      if (STREQ(cmd, "Get_Binning")) {
        auto nn = factory.createScalar<double>(instance->Get_Binning());
        outputs[0] = nn;
        return;
      }

      // Is camera recording (T/F)
      if (STREQ(cmd, "Is_Cam_Recording")) {
        auto nn = factory.createScalar<bool>(instance->Is_Cam_Recording());
        outputs[0] = nn;
        return;
      }

      // Start synchronous acquisition.
      // Third argument is number of desired frames.
      // Fourth argument is path of file into which to save recording.
      if (STREQ(cmd, "Start_Acquisition")) {
        std::string fpath = CharArray(inputs[3]).toAscii();
        const TypedArray<uint32_t> numframesa = std::move(inputs[2]);
        int32 numframes = (int32)numframesa[0];
        auto nn = factory.createScalar<bool>(
            instance->Start_Acquisition(numframes, fpath.c_str()));
        return;
      }

      // Check if frames were dropped during acquisition (T/F)
      if (STREQ(cmd, "Check_Dropped_Frames")) {
        auto nn = factory.createScalar<int>(instance->Dropped_Frame_Check());
        outputs[0] = nn;
        return;
      }

      // Check if prior acquisition has finished (T/F)
      if (STREQ(cmd, "Check_Acq_Done")) {
        auto nn = factory.createScalar<int>(instance->Acq_Done_Check());
        outputs[0] = nn;
        return;
      }

      // Set fractional colormap limits of live display (0 to 1).
      // Third argument is low threshold
      // Fourth is high threshold
      if (STREQ(cmd, "Set_Cmap_Limits")) {
        const TypedArray<double> clow_array = std::move(inputs[2]);
        double clow = clow_array[0];
        const TypedArray<double> chigh_array = std::move(inputs[3]);
        double chigh = chigh_array[0];
        instance->Set_Cmap_Thresholds(clow, chigh);
        return;
      }

      // Set camera readout mode (third argument is numeric mode selection)
      if (STREQ(cmd, "Set_Read_Mode")) {
        const TypedArray<int32_t> read_mode_array = std::move(inputs[2]);
        int read_mode = read_mode_array[0];
        instance->Set_Read_Mode(read_mode);
        return;
      }

      // Delete underlying Cam_Wrapper instance.
      if (STREQ(cmd, "delete")) {
        mexUnlock();
        destroyObject<Cam_Wrapper>(handl);
        return;
      }
    }
    return;
  }
};