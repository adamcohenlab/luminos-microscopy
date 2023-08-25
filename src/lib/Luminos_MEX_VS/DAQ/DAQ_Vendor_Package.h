#pragma once
#include "DAQ_Utilities.h"

class DAQ_Vendor_Package {
public:
  virtual int Create_Task(void **taskHandle_ref) = 0;
  virtual int Attach_Clock(void *taskHandle, char *Phys_Port, char *Task_Type,
                           int numsamples, double rate) = 0;
  virtual int Attach_Trigger(void *taskHandle, char *Phys_Port,
                             bool risingedge) = 0;
  virtual int Add_AI_Channel(void *taskHandle, char *Phys_Port,
                             char *Channel_Name, int32 terminalConfig,
                             float64 minval, float64 maxVal) = 0;
  virtual int Add_AO_Channel(void *taskHandle, char *Phys_Port,
                             char *Channel_Name, int32 terminalConfig,
                             float64 minval, float64 maxVal) = 0;
  virtual int Add_DI_Channel(void *taskHandle, char *Phys_Port,
                             char *Channel_Name) = 0;
  virtual int Add_DO_Channel(void *taskHandle, char *Phys_Port,
                             char *Channel_Name) = 0;
  virtual int Add_CI_Channel(void *taskHandle, char *counter,
                             char *Channel_Name, bool rising_edge) = 0;
  virtual int Add_CO_Channel(void *taskHandle, char *counter,
                             char *Channel_Name, char *Phys_Port,
                             int32 lowTicks, int32 highTicks, int32 sdelay) = 0;
  virtual int Attach_Callback_Method(void *taskHandle, DAQ_Callback *CallFun,
                                     int numsamples) = 0;
  virtual int Start_Task(void *taskHandle) = 0;
  virtual int Stop_Task(void *taskHandle) = 0;
  virtual int Clear_Task(void *taskHandle) = 0;
  virtual int Write_Analog_Data(void *taskHandle, double *data,
                                int numsamples) = 0;
  virtual int Write_Counter_Data(void *taskHandle, uInt32 highticks,
                                 uInt32 lowticks) = 0;
  virtual int Write_Digital_Data(void *taskHandle, uInt8 *data,
                                 int numsamples) = 0;
  virtual int Read_Analog_Data(void *taskHandle, double *data_target,
                               int numsamples, int numchannels) = 0;
  virtual int Read_Counter_Data(void *taskHandle, double *data_target,
                                int numsamples, int numchannels) = 0;
  virtual int Read_Digital_Data(void *taskHandle, uInt8 *data_target,
                                int numsamples, int numchannels) = 0;
  virtual int Is_Task_Done(void *taskHandle, uInt32 *task_done) = 0;
  virtual int Connect_Terminals(char *Source_Terminal,
                                char *Destination_Terminal) = 0;
};