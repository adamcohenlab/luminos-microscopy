#include "mex.hpp"
#include "mexAdapter.hpp"
#include "class_handle.h"
#include <cstdlib>
#include <cstdio>
#include <iostream>
#include <cstring>
#include <string>
#include "Scanning_Device.h"
//ADD INCLUDE FOR THE CLASS YOU WISH TO WRAP HERE

#define STREQ(x,y) !(std::strcmp(x.c_str(),y))
#define MPRINT(eng,fac,x) eng->feval(u"display", 0, std::vector<Array>({ fac.createScalar(x) }))
#define MERROR(eng,fac,x) eng->feval(u"error", 0, std::vector<Array>({ fac.createScalar(x) }))
using namespace matlab::data;
using matlab::mex::ArgumentList;


//! Extracts the pointer to underlying data from the non-const iterator (`TypedIterator<T>`).
/*! This function does not throw any exceptions. */
template <typename T>
inline T* toPointer(const matlab::data::TypedIterator<T>& it) MW_NOEXCEPT {
    static_assert(std::is_arithmetic<T>::value && !std::is_const<T>::value,
        "Template argument T must be a std::is_arithmetic and non-const type.");
    return it.operator->();
}

template <typename T>
inline T* getPointer(matlab::data::TypedArray<T>& arr) MW_NOEXCEPT {
    static_assert(std::is_arithmetic<T>::value, "Template argument T must be a std::is_arithmetic type.");
    return toPointer(arr.begin());
}
template <typename T>
inline const T* getPointer(const matlab::data::TypedArray<T>& arr) MW_NOEXCEPT {
    return getPointer(const_cast<matlab::data::TypedArray<T>&>(arr));
}

class MexFunction : public matlab::mex::Function
{
private:
    ArrayFactory factory;
    std::shared_ptr<matlab::engine::MATLABEngine> matlabPtr;

    void validateArguments(ArgumentList outputs, ArgumentList inputs)
    {
        if (inputs.size() > 2)
            MERROR(matlabPtr, factory, "Require at most 2 inputs");
        if (inputs[0].getType() != ArrayType::CHAR)
            MERROR(matlabPtr, factory, "First input has to be a CHAR array");
        if (inputs.size() > 1) {
            if (inputs[1].getType() != ArrayType::UINT64) {
                MERROR(matlabPtr, factory, "Second input has to be type uint64. Should be the coded handle for the camera instance.");
            }
        }
    }

    void foo(int n, const double* a, const double* b, double* c) {
        int i;
        for (i = 0; i < n; i++)
            c[i] = a[i] * b[i];
    }
    void displayOnMATLAB(std::ostringstream& stream) {
        // Pass stream content to MATLAB fprintf function
        matlabPtr->feval(u"fprintf", 0,
            std::vector<Array>({ factory.createScalar(stream.str()) }));
        // Clear stream buffer
        stream.str("");
    }


    std::ostringstream stream;



public:
    MexFunction() : matlabPtr(getEngine()) {}
    ~MexFunction() {}
    void operator() (ArgumentList outputs, ArgumentList inputs)
    {
        int n = inputs[0].getNumberOfElements();
        std::string cmd = CharArray(inputs[0]).toAscii();

        if (inputs.size() > 1) {
            if (STREQ(cmd, "new")) {

                matlab::data::Array init_struct(inputs[1]);
                const TypedArray<uint16_t> DAQ_vendor_array = matlabPtr->getProperty(init_struct, u"DAQ_Vendor");
                uint16_t DAQ_vendor = DAQ_vendor_array[0];

                const TypedArray<uint16_t> galvos_only_array = matlabPtr->getProperty(init_struct, u"galvos_only");
                uint16_t galvos_only = galvos_only_array[0];

                const TypedArray<double> sample_rate_array = matlabPtr->getProperty(init_struct, u"sample_rate");
                double sample_rate = sample_rate_array[0];

                const TypedArray<double> feedbackscalearray = matlabPtr->getProperty(init_struct, u"feedback_scaling");
                double feedback_scale = feedbackscalearray[0];


                std::string galvox_physport = CharArray(matlabPtr->getProperty(init_struct, u"galvox_physport")).toAscii();
                std::string galvoy_physport = CharArray(matlabPtr->getProperty(init_struct, u"galvoy_physport")).toAscii();
                std::string galvofbx_physport = CharArray(matlabPtr->getProperty(init_struct, u"galvofbx_physport")).toAscii();
                std::string galvofby_physport = CharArray(matlabPtr->getProperty(init_struct, u"galvofby_physport")).toAscii();
                std::string PMT_Physport = CharArray(matlabPtr->getProperty(init_struct, u"PMT_physport")).toAscii();
                std::string timebase_source = CharArray(matlabPtr->getProperty(init_struct, u"timebase_source")).toAscii();
                std::string trigger_physport = CharArray(matlabPtr->getProperty(init_struct, u"trigger_physport")).toAscii();
                std::string sync_counter = CharArray(matlabPtr->getProperty(init_struct, u"sync_counter")).toAscii();
                mexLock();
                uint64_t instance_handle = convertPtr2Mat<Scanning_Device>(new Scanning_Device((int)DAQ_vendor,
                    galvox_physport,galvoy_physport,galvofbx_physport,galvofby_physport, PMT_Physport,
                    timebase_source,trigger_physport,sync_counter,sample_rate, feedback_scale,(int) galvos_only));
                outputs[0] = factory.createScalar<uint64_t>(instance_handle);
                return;
            }
            


            matlab::data::Array init_struct(inputs[1]);
            const TypedArray<uint64_t> B = std::move(matlabPtr->getProperty(init_struct,u"mexPointer"));
            uint64_t handl = B[0];
            Scanning_Device* instance = convertMat2Ptr<Scanning_Device>(handl);
            
            if (STREQ(cmd, "Mex_Cleanup")) {
                delete instance;
                mexUnlock();
                outputs[0] = factory.createScalar<uint64_t>(0);
                return;
            }

            if (STREQ(cmd, "Startup")) {
                const TypedArray<double> galvoxdata = matlabPtr->getProperty(init_struct, u"galvox_wfm");
                const TypedArray<double> galvoydata = matlabPtr->getProperty(init_struct, u"galvoy_wfm");
                const TypedArray<int64_t> xpixels = matlabPtr->getProperty(init_struct, u"xpixels");
                const TypedArray<int64_t> ypixels = matlabPtr->getProperty(init_struct, u"ypixels");
                outputs[0]=factory.createScalar<int32_t>(instance->Startup((double*)getPointer(galvoxdata), (double*)getPointer(galvoydata), galvoxdata.getNumberOfElements(),
                    xpixels[0], ypixels[0]));
                return;
            }

            if (STREQ(cmd, "Raster_From_Bounds")) {

                const TypedArray<double> boundsarray = inputs[2];
                double* bounds = (double*)getPointer(boundsarray);
                SDL_FRect ROI;
                ROI.x = bounds[0];
                ROI.y = bounds[1];
                ROI.w = bounds[2]-bounds[0];
                ROI.h = bounds[3]-bounds[1];

                const TypedArray<double> ppvArray = matlabPtr->getProperty(init_struct, u"Points_Per_Volt");

                outputs[0] = factory.createScalar<int32_t>(instance->Raster_From_Bounds(ROI, ppvArray[0]));

                auto galvoxwfm = factory.createArray<double>({ 1,(uint64_t)instance->AO_Task->numsamples });
                auto galvoywfm = factory.createArray<double>({ 1,(uint64_t)instance->AO_Task->numsamples });
                auto galvoxpointer = getPointer(galvoxwfm);
                auto galvoypointer = getPointer(galvoywfm);
                memcpy(galvoxpointer, instance->AO_Task->Channel_Group[instance->galvox_Channel - 1].data, sizeof(double) * instance->AO_Task->numsamples);
                memcpy(galvoypointer, instance->AO_Task->Channel_Group[instance->galvoy_Channel - 1].data, sizeof(double) * instance->AO_Task->numsamples);
                matlabPtr->setProperty(init_struct, u"galvox_wfm", galvoxwfm);
                matlabPtr->setProperty(init_struct, u"galvoy_wfm", galvoywfm);
                return;
            }

            if (STREQ(cmd, "Sawtooth_Raster_From_Bounds")) {

                const TypedArray<double> boundsarray = inputs[2];
                double* bounds = (double*)getPointer(boundsarray);
                SDL_FRect ROI;
                ROI.x = bounds[0];
                ROI.y = bounds[1];
                ROI.w = bounds[2] - bounds[0];
                ROI.h = bounds[3] - bounds[1];

                const TypedArray<double> ppvArray = matlabPtr->getProperty(init_struct, u"Points_Per_Volt");

                outputs[0] = factory.createScalar<int32_t>(instance->Raster_From_Bounds_Sawtooth(ROI, ppvArray[0]));

                auto galvoxwfm = factory.createArray<double>({ 1,(uint64_t)instance->AO_Task->numsamples });
                auto galvoywfm = factory.createArray<double>({ 1,(uint64_t)instance->AO_Task->numsamples });
                auto galvoxpointer = getPointer(galvoxwfm);
                auto galvoypointer = getPointer(galvoywfm);
                memcpy(galvoxpointer, instance->AO_Task->Channel_Group[instance->galvox_Channel - 1].data, sizeof(double) * instance->AO_Task->numsamples);
                memcpy(galvoypointer, instance->AO_Task->Channel_Group[instance->galvoy_Channel - 1].data, sizeof(double) * instance->AO_Task->numsamples);
                matlabPtr->setProperty(init_struct, u"galvox_wfm", galvoxwfm);
                matlabPtr->setProperty(init_struct, u"galvoy_wfm", galvoywfm);
                return;
            }

            if (STREQ(cmd, "Sync_Waveform_From_Stream")) {
                auto galvoxwfm = factory.createArray<double>({ 1,(uint64_t)instance->AO_Task->numsamples });
                auto galvoywfm = factory.createArray<double>({ 1,(uint64_t)instance->AO_Task->numsamples });
                auto galvoxpointer = getPointer(galvoxwfm);
                auto galvoypointer = getPointer(galvoywfm);
                memcpy(galvoxpointer, instance->AO_Task->Channel_Group[instance->galvox_Channel - 1].data, sizeof(double) * instance->AO_Task->numsamples);
                memcpy(galvoypointer, instance->AO_Task->Channel_Group[instance->galvoy_Channel - 1].data, sizeof(double) * instance->AO_Task->numsamples);
                matlabPtr->setProperty(init_struct, u"galvox_wfm", galvoxwfm);
                matlabPtr->setProperty(init_struct, u"galvoy_wfm", galvoywfm);
                return;
            }


            if (STREQ(cmd, "Acq_Frames")) {
                TypedArray<int32_t> numframesarray = std::move(inputs[2]);
                instance->Acq_Frames(numframesarray[0]);
                
                outputs[0]=factory.createScalar<int32_t>(instance->Get_AI_Data());

                auto galvofbxarray = factory.createArray<double>({ 1,(uint64_t)instance->AI_Task->numsamples });
               auto galvofbxpointer = getPointer(galvofbxarray);
                memcpy(galvofbxpointer, instance->AI_Task->Channel_Group[instance->galvofbx_Channel - 1].data, sizeof(double) * instance->AI_Task->numsamples);
                outputs[1] = galvofbxarray;

                auto galvofbyarray = factory.createArray<double>({ 1,(uint64_t)instance->AI_Task->numsamples });
                auto galvofbypointer = getPointer(galvofbyarray);
                memcpy(galvofbypointer, instance->AI_Task->Channel_Group[instance->galvofby_Channel - 1].data, sizeof(double) * instance->AI_Task->numsamples);
                outputs[2] = galvofbyarray;

                auto PMT_Array = factory.createArray<double>({ 1,(uint64_t)instance->AI_Task->numsamples });
                auto PMTpointer = getPointer(PMT_Array);
                memcpy(PMTpointer, instance->AI_Task->Channel_Group[instance->PMT_Channel - 1].data, sizeof(double) * instance->AI_Task->numsamples);
                outputs[3] = PMT_Array;
                return;
            }

            if (STREQ(cmd, "Acq_Sync_Frames")) {
                TypedArray<int32_t> numframesarray = std::move(inputs[2]);
                const TypedArray<double> galvoxdata = matlabPtr->getProperty(init_struct, u"galvox_wfm");
                const TypedArray<double> galvoydata = matlabPtr->getProperty(init_struct, u"galvoy_wfm");
                std::string trigger_source = CharArray(matlabPtr->getProperty(init_struct, u"trigger_physport")).toAscii();

                outputs[0] = factory.createScalar<int32_t>(instance->Acq_Sync_Frames((double*)getPointer(galvoxdata), (double*)getPointer(galvoydata),galvoxdata.getNumberOfElements(), numframesarray[0],trigger_source));

                return;
            }

            if (STREQ(cmd, "Read_AI_Data")) {
                auto galvofbxarray = factory.createArray<double>({ 1,(uint64_t)instance->AI_Task->numsamples });

                auto galvofbyarray = factory.createArray<double>({ 1,(uint64_t)instance->AI_Task->numsamples });
                
                auto PMT_Array = factory.createArray<double>({ 1,(uint64_t)instance->AI_Task->numsamples });

                outputs[0] = factory.createScalar<int32_t>(instance->Get_AI_Data());

                auto galvofbxpointer = getPointer(galvofbxarray);
                memcpy(galvofbxpointer, instance->AI_Task->Channel_Group[instance->galvofbx_Channel - 1].data, sizeof(double) * instance->AI_Task->numsamples);
                outputs[1] = galvofbxarray;

                auto galvofbypointer = getPointer(galvofbyarray);
                memcpy(galvofbypointer, instance->AI_Task->Channel_Group[instance->galvofby_Channel - 1].data, sizeof(double) * instance->AI_Task->numsamples);
                outputs[2] = galvofbyarray;

                auto PMTpointer = getPointer(PMT_Array);
                memcpy(PMTpointer, instance->AI_Task->Channel_Group[instance->PMT_Channel - 1].data, sizeof(double) * instance->AI_Task->numsamples);
                outputs[3] = PMT_Array;
                return;
            }

            if (STREQ(cmd, "Update_Galvo_Scan")) {
                const TypedArray<double> galvoxdata = matlabPtr->getProperty(init_struct, u"galvox_wfm");
                const TypedArray<double> galvoydata = matlabPtr->getProperty(init_struct, u"galvoy_wfm");
                const TypedArray<int64_t> xpixels = inputs[2];
                const TypedArray<int64_t> ypixels = inputs[3];
                
                outputs[0] = factory.createScalar<int32_t>(instance->Update_Galvo_Scan((double*)getPointer(galvoxdata), (double*)getPointer(galvoydata), galvoxdata.getNumberOfElements(),
                    xpixels[0], ypixels[0]));
                return;
            }

            if (STREQ(cmd, "Raster_From_Bounds")) {
                    const TypedArray<double> raster_bounds = matlabPtr->getProperty(init_struct, u"raster_bounds");
                    const TypedArray<double> binning= matlabPtr->getProperty(init_struct, u"Points_Per_Volt");
                    instance->Restart_Live_Acq(raster_bounds[0], raster_bounds[1], raster_bounds[2],raster_bounds[3], binning[0]);
                return;
            }


            if (STREQ(cmd, "Restart_Live")) {
                outputs[0] = factory.createScalar<int>(instance->aq_live_restart());
                return;
            }

            if (STREQ(cmd, "GetFrameRate")) {
                outputs[0] = factory.createScalar<double>((double)(instance->AI_Task->numsamples) / ((double)instance->AI_Task->rate));
                return;
            }

        }
        return;
    }
};