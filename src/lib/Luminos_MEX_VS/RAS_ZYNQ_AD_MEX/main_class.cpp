#include "mex.hpp"
#include "mexAdapter.hpp"
#include "class_handle.h"
#include "RAS_Zynq_AD.h"
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
    if (inputs.size() > 1) {
      if (STREQ(cmd, "new")) {
        mexLock();
        matlab::data::Array init_struct(inputs[1]);
        std::string ip_address =
            CharArray(matlabPtr->getProperty(init_struct, u"ip_address"))
                .toAscii();

        TypedArray<uint32_t> port_array =
            matlabPtr->getProperty(init_struct, u"port");
        uint32_t port = port_array[0];

        uint64_t instance_handle =
            convertPtr2Mat<RAS_Zynq_AD>(new RAS_Zynq_AD(ip_address, port));
        outputs[0] = factory.createScalar<uint64_t>(instance_handle);
        return;
      }
      const TypedArray<uint64_t> B = std::move(inputs[1]);
      uint64_t handl = B[0];
      RAS_Zynq_AD *instance = convertMat2Ptr<RAS_Zynq_AD>(handl);

      if (STREQ(cmd, "Connect_to_Zynq")) {
        instance->Connect_to_Zynq();
        return;
      }

      if (STREQ(cmd, "Configure_Task")) {
        TypedArray<uint64_t> numpulsesarray = std::move(inputs[2]);
        instance->Configure_Task(numpulsesarray[0]);
        return;
      }
      if (STREQ(cmd, "Start_Task")) {
        instance->Start_Task();
        return;
      }
      if (STREQ(cmd, "SetAutotriggerMode")) {
        TypedArray<uint8_t> AutoTrigArray = std::move(inputs[2]);
        instance->SetAutoTriggerMode((char)AutoTrigArray[0]);
        return;
      }
      if (STREQ(cmd, "SetTestRampMode")) {
        TypedArray<uint8_t> TestRampArray = std::move(inputs[2]);
        instance->SetTestRampMode((char)TestRampArray[0]);
        return;
      }
      if (STREQ(cmd, "SetAmplifierGain")) {
        TypedArray<int8_t> GainArray = std::move(inputs[2]);
        instance->SetAmplifierGain(GainArray[0]);
        return;
      }
      if (STREQ(cmd, "TaskDone?")) {
        outputs[0] = factory.createScalar<uint8_t>(instance->taskdone);
        return;
      }
      if (STREQ(cmd, "Read_Data")) {
        auto HS_Out_Array = factory.createArray<int16_t>(
            {1, HS_SAMPLES_PER_PULSE * MAX_PULSES_PER_PACKET *
                    (uint64_t)instance->numbursts});
        int16_t *HS_dataptr = getPointer(HS_Out_Array);
        memcpy(HS_dataptr, (int16_t *)instance->HS_Buffer,
               HS_SAMPLES_PER_PULSE * MAX_PULSES_PER_PACKET *
                   (uint64_t)instance->numbursts * sizeof(int16_t));

        auto AuxA_Out_Array = factory.createArray<int16_t>(
            {1, AUX_SAMPLES_PER_PULSE * MAX_PULSES_PER_PACKET *
                    (uint64_t)instance->numbursts});
        int16_t *AuxA_dataptr = getPointer(AuxA_Out_Array);
        memcpy(AuxA_dataptr, (int16_t *)instance->Aux_DataA,
               AUX_SAMPLES_PER_PULSE * MAX_PULSES_PER_PACKET *
                   (uint64_t)instance->numbursts * sizeof(int16_t));

        auto AuxB_Out_Array = factory.createArray<int16_t>(
            {1, AUX_SAMPLES_PER_PULSE * MAX_PULSES_PER_PACKET *
                    (uint64_t)instance->numbursts});
        int16_t *AuxB_dataptr = getPointer(AuxB_Out_Array);
        memcpy(AuxB_dataptr, (int16_t *)instance->Aux_DataB,
               AUX_SAMPLES_PER_PULSE * MAX_PULSES_PER_PACKET *
                   (uint64_t)instance->numbursts * sizeof(int16_t));

        outputs[0] = HS_Out_Array;
        outputs[1] = AuxA_Out_Array;
        outputs[2] = AuxB_Out_Array;

        return;
      }

      if (STREQ(cmd, "Set_HS_Delay")) {
        TypedArray<uint8_t> HS_Delay_Array = std::move(inputs[2]);
        instance->Set_HS_Delay(HS_Delay_Array[0]);
        return;
      }

      if (STREQ(cmd, "Set_AUX_Delay")) {
        TypedArray<uint8_t> AUX_Delay_Array = std::move(inputs[2]);
        instance->Set_AUX_Delay(AUX_Delay_Array[0]);
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