#include "mex.hpp"
#include "mexAdapter.hpp"
#include "class_handle.h"
#include <cstdlib>
#include <cstdio>
#include <iostream>
#include <cstring>
#include <string>

#include "DAQ_Buffered_Task.h"

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
        const TypedArray<uint16_t> task_vendor_array = std::move(inputs[1]);
        uint16_t task_vendor = task_vendor_array[0];
        std::string task_type = CharArray(inputs[2]).toAscii();
        mexLock();
        uint64_t instance_handle = convertPtr2Mat<DAQ_Buffered_Task>(
            new DAQ_Buffered_Task((int)task_vendor, task_type));
        outputs[0] = factory.createScalar<uint64_t>(instance_handle);
        return;
      }

      const TypedArray<uint64_t> B = std::move(inputs[1]);
      uint64_t handl = B[0];
      DAQ_Buffered_Task *instance = convertMat2Ptr<DAQ_Buffered_Task>(handl);

      if (STREQ(cmd, "Generate_taskHandle")) {
        auto error = instance->Generate_taskHandle();
        uint64_t thandle = convertPtr2Mat<void>(instance->taskHandle);
        outputs[0] = factory.createScalar<int32_t>(error);
        outputs[1] = factory.createScalar<uint64_t>(thandle);
        return;
      }

      if (STREQ(cmd, "Add_Analog_Input_Channel")) {
        std::string Phys_Port = CharArray(inputs[2]).toAscii();
        std::string Channel_Name = CharArray(inputs[3]).toAscii();
        const TypedArray<double> minvarray = std::move(inputs[4]);
        const TypedArray<double> maxvarray = std::move(inputs[5]);

        const TypedArray<int32_t> terminal_configarray = std::move(inputs[6]);
        TypedArray<int32_t> numsampsarray = std::move(inputs[7]);
        instance->numsamples = numsampsarray[0];
        double minv = minvarray[0];
        double maxv = maxvarray[0];
        int32_t terminal_config = terminal_configarray[0];
        auto error = instance->Add_Input_Channel(Phys_Port, Channel_Name, minv,
                                                 maxv, terminal_config);
        outputs[0] = factory.createScalar<int32_t>(error);
        return;
      }
      if (STREQ(cmd, "Add_Input_Channel")) {
        std::string Phys_Port = CharArray(inputs[2]).toAscii();
        std::string Channel_Name = CharArray(inputs[3]).toAscii();
        TypedArray<int32_t> numsampsarray = std::move(inputs[4]);
        instance->numsamples = numsampsarray[0];
        auto error = instance->Add_Input_Channel(Phys_Port, Channel_Name);
        outputs[0] = factory.createScalar<int32_t>(error);
        return;
      }

      if (STREQ(cmd, "Add_Analog_Output_Channel")) {
        std::string Phys_Port = CharArray(inputs[2]).toAscii();
        std::string Channel_Name = CharArray(inputs[3]).toAscii();
        const TypedArray<double> minvarray = std::move(inputs[4]);
        const TypedArray<double> maxvarray = std::move(inputs[5]);
        const TypedArray<int32_t> terminal_configarray = std::move(inputs[6]);
        double minv = minvarray[0];
        double maxv = maxvarray[0];
        int32_t terminal_config = terminal_configarray[0];

        TypedArray<double> out_data = std::move(inputs[7]);
        auto out_data_ptr = getPointer(out_data);
        TypedArray<int32_t> numsampsarray = std::move(inputs[8]);
        instance->numsamples = numsampsarray[0];
        auto error = instance->Add_Output_Channel(
            Phys_Port, Channel_Name, out_data_ptr, minv, maxv, terminal_config);
        outputs[0] = factory.createScalar<int32_t>(error);
        return;
      }

      if (STREQ(cmd, "Add_Digital_Output_Channel")) {
        std::string Phys_Port = CharArray(inputs[2]).toAscii();
        std::string Channel_Name = CharArray(inputs[3]).toAscii();
        TypedArray<uInt8> out_data = std::move(inputs[4]);
        TypedArray<int32_t> numsampsarray = std::move(inputs[5]);
        instance->numsamples = numsampsarray[0];
        auto out_data_ptr = getPointer(out_data);
        auto error =
            instance->Add_Output_Channel(Phys_Port, Channel_Name, out_data_ptr);
        outputs[0] = factory.createScalar<int32_t>(0);
        return;
      }

      if (STREQ(cmd, "Add_Output_Counter")) {
        std::string Phys_Port = CharArray(inputs[2]).toAscii();
        std::string Channel_Name = CharArray(inputs[3]).toAscii();
        std::string counter = CharArray(inputs[4]).toAscii();

        TypedArray<int32_t> lowtickarray = std::move(inputs[5]);
        int32_t lowticks = lowtickarray[0];
        TypedArray<int32_t> hightickarray = std::move(inputs[6]);
        int32_t highticks = hightickarray[0];
        TypedArray<int32_t> startdelayarray = std::move(inputs[7]);
        int32_t startdelay = startdelayarray[0];

        int32_t error = instance->Add_Output_Counter(
            Phys_Port, Channel_Name, counter, lowticks, highticks, startdelay);
        outputs[0] = factory.createScalar<int32_t>(error);
        return;
      }

      if (STREQ(cmd, "Read_Data")) {
        int32_t error = instance->Read_Data();
        outputs[0] = factory.createScalar<int32_t>(error);
        if (instance->task_type[0] == 'd') {
          auto nn = factory.createArray<uint8_t>(
              {1, (uint64_t)instance->numchannels *
                      (uint64_t)instance->numsamples});
          uint8_t *dataptr = getPointer(nn);
          memcpy(dataptr, (uint8_t *)instance->task_data,
                 (uint64_t)instance->numchannels *
                     (uint64_t)instance->numsamples * sizeof(uint8_t));
          outputs[1] = nn;
        } else {
          auto nn = factory.createArray<double>(
              {1, (uint64_t)instance->numchannels *
                      (uint64_t)instance->numsamples});
          double *dataptr = getPointer(nn);
          memcpy(dataptr, (double *)instance->task_data,
                 (uint64_t)instance->numchannels *
                     (uint64_t)instance->numsamples * sizeof(double));
          outputs[1] = nn;
        }
        return;
      }

      if (STREQ(cmd, "Write_Data")) {
        int32_t error = instance->Write_Data();
        outputs[0] = factory.createScalar<int32_t>(error);
        return;
      }

      if (STREQ(cmd, "Start_Task")) {
        int32_t error = instance->Start_Task();
        outputs[0] = factory.createScalar<int32_t>(error);
        return;
      }

      if (STREQ(cmd, "Configure_Clock")) {
        int32_t error = 0;
        std::string Phys_Port = CharArray(inputs[2]).toAscii();
        const TypedArray<double> rate = std::move(inputs[3]);
        const TypedArray<uint32_t> numsamples = std::move(inputs[4]);
        instance->rate = rate[0];
        instance->numsamples = (int)numsamples[0];
        error = instance->Attach_Clock(Phys_Port);
        outputs[0] = factory.createScalar<int32_t>(error);
        return;
      }

      if (STREQ(cmd, "Attach_Trigger")) {
        std::string Phys_Port = CharArray(inputs[2]).toAscii();
        int32_t error = instance->Attach_Trigger(Phys_Port, true);
        outputs[0] = factory.createScalar<int32_t>(error);
        return;
      }

      if (STREQ(cmd, "TaskDone?")) {
        uint32_t taskdone;
        int32_t error = instance->Is_Task_Done(&taskdone);
        outputs[0] = factory.createScalar<int32_t>(error);
        outputs[1] = factory.createScalar<uint32_t>(taskdone);
        return;
      }

      if (STREQ(cmd, "Stop_Task")) {
        int32_t error = instance->Stop_Task();
        outputs[0] = factory.createScalar<int32_t>(error);
        return;
      }
      if (STREQ(cmd, "Clear_Task")) {
        int32_t error = instance->Clear_Task();
        outputs[0] = factory.createScalar<int32_t>(error);
        return;
      }

      if (STREQ(cmd, "Connect_Terminas")) {
        int32_t error = instance->Connect_Terminals(
            CharArray(inputs[2]).toAscii(), CharArray(inputs[3]).toAscii());
        outputs[0] = factory.createScalar<int32_t>(error);
        return;
      }

      if (STREQ(cmd, "Delete_Handle")) {
        delete (instance);
        int32_t error = 0;
        mexUnlock();
        outputs[0] = factory.createScalar<int32_t>(error);
        return;
      }
    }
    return;
  }
};