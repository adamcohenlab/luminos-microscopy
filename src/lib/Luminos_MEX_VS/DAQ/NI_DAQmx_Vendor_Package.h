#pragma once
#include "DAQ_Vendor_Package.h"
#include "NIDAQmx.h"
class NI_DAQmx_Vendor_Package : public DAQ_Vendor_Package {
public:
  NI_DAQmx_Vendor_Package();
  int Create_Task(void **taskHandle_ref);
  int Attach_Clock(void *taskHandle, char *Phys_Port, char *Task_Type,
                   int numsamples, double rate);
  int Attach_Trigger(void *taskHandle, char *Phys_Port, bool risingedge);
  int Add_AI_Channel(void *taskHandle, char *Phys_Port, char *Channel_Name,
                     int32 terminalConfig, float64 minval, float64 maxVal);
  int Add_AO_Channel(void *taskHandle, char *Phys_Port, char *Channel_Name,
                     int32 terminalConfig, float64 minval, float64 maxVal);
  int Add_DI_Channel(void *taskHandle, char *Phys_Port, char *Channel_Name);
  int Add_DO_Channel(void *taskHandle, char *Phys_Port, char *Channel_Name);
  int Add_CI_Channel(void *taskHandle, char *counter, char *Channel_Name,
                     bool rising_edge);
  int Add_CO_Channel(void *taskHandle, char *counter, char *Channel_Name,
                     char *Phys_Port, int32 lowTicks, int32 highTicks,
                     int32 sdelay);
  int Attach_Callback_Method(void *taskHandle, DAQ_Callback *CallFun,
                             int numsamples);
  int Start_Task(void *taskHandle);
  int Stop_Task(void *taskHandle);
  int Clear_Task(void *taskHandle);
  int Write_Analog_Data(void *taskHandle, double *data, int numsamples);
  int Write_Counter_Data(void *taskHandle, uInt32 highticks, uInt32 lowticks);
  int Write_Digital_Data(void *taskHandle, uInt8 *data, int numsamples);
  int Read_Analog_Data(void *taskHandle, double *data_target, int numsamples,
                       int numchannels);
  int Read_Counter_Data(void *taskHandle, double *data_target, int numsamples,
                        int numchannels);
  int Read_Digital_Data(void *taskHandle, uInt8 *data_target, int numsamples,
                        int numchannels);
  int Is_Task_Done(void *taskHandle, uInt32 *task_done);
  int Connect_Terminals(char *Source_Terminal, char *Destination_Terminal);
};

int32 CVICALLBACK EveryNCallback(TaskHandle taskHandle,
                                 int32 everyNsamplesEventType, uInt32 nSamples,
                                 void *callbackData);
