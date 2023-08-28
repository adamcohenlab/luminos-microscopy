#include "mex.hpp"
#include "mexAdapter.hpp"
#include "class_handle.h"
#include "ALP_DMD.h"
#include <cstdlib>
#include <cstdio>
#include <iostream>
#include <cstring>
#include <string>

#define STREQ(x, y) !(std::strcmp(x.c_str(), y))
#define MPRINT(eng, fac, x)                                                    \
  eng->feval(u"display", 0, std::vector<Array>({fac.createScalar(x)}))
#define MERROR(eng, fac, x)                                                    \
  eng->feval(u"error", 0, std::vector<Array>({fac.createScalar(x)}))
using namespace matlab::data;
using matlab::mex::ArgumentList;

//! Extracts the pointer to underlying data from the non-const iterator
//! (`TypedIterator<T>`).
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

class MexFunction : public matlab::mex::Function {
private:
  ArrayFactory factory;
  std::shared_ptr<matlab::engine::MATLABEngine> matlabPtr;

  void validateArguments(ArgumentList outputs, ArgumentList inputs) {
    if (inputs.size() > 2)
      MERROR(matlabPtr, factory, "Require at most 2 inputs");
    if (inputs[0].getType() != ArrayType::CHAR)
      MERROR(matlabPtr, factory, "First input has to be a CHAR array");
    if (inputs.size() > 1) {
      if (inputs[1].getType() != ArrayType::UINT64) {
        MERROR(matlabPtr, factory,
               "Second input has to be type uint64. Should be the coded handle "
               "for the camera instance.");
      }
    }
  }

  void foo(int n, const double *a, const double *b, double *c) {
    int i;
    for (i = 0; i < n; i++)
      c[i] = a[i] * b[i];
  }
  void displayOnMATLAB(std::ostringstream &stream) {
    // Pass stream content to MATLAB fprintf function
    matlabPtr->feval(u"fprintf", 0,
                     std::vector<Array>({factory.createScalar(stream.str())}));
    // Clear stream buffer
    stream.str("");
  }

  std::ostringstream stream;

public:
  MexFunction() : matlabPtr(getEngine()) {}
  ~MexFunction() {}
  void operator()(ArgumentList outputs, ArgumentList inputs) {
    int n = inputs[0].getNumberOfElements();
    std::string cmd = CharArray(inputs[0]).toAscii();
    if (inputs.size() > 0) {
      if (STREQ(cmd, "new")) {
        mexLock();
        uint64_t instance_handle = convertPtr2Mat<ALP_DMD>(new ALP_DMD());
        outputs[0] = factory.createScalar<uint64_t>(instance_handle);
        return;
      }
      const TypedArray<uint64_t> B = std::move(inputs[1]);
      uint64_t handl = B[0];
      ALP_DMD *instance = convertMat2Ptr<ALP_DMD>(handl);

      if (STREQ(cmd, "Project_Image")) {
        TypedArray<unsigned char> newimage = std::move(inputs[2]);
        auto new_image_pointer = getPointer(newimage);
        instance->Project(new_image_pointer);
        return;
      }

      if (STREQ(cmd, "Get_Dimensions")) {
        outputs[0] = factory.createScalar<int32_t>(instance->nSizeX);
        outputs[1] = factory.createScalar<int32_t>(instance->nSizeY);
        return;
      }

      if (STREQ(cmd, "Project_White")) {
        instance->Project_White();
        return;
      }

      if (STREQ(cmd, "Project_Black")) {
        instance->Project_Black();
        return;
      }

      if (STREQ(cmd, "Project_Checkerboard")) {
        instance->Project_Checkerboard();
        return;
      }

      if (STREQ(cmd, "Reset_Image")) {
        instance->Reset_Image();
        return;
      }

      if (STREQ(cmd, "delete")) {
        mexUnlock();
        delete instance;
        return;
      }
    }
    return;
  }
};