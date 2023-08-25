#include "NI_DAQmx_Vendor_Package.h"

NI_DAQmx_Vendor_Package::NI_DAQmx_Vendor_Package() {}

int NI_DAQmx_Vendor_Package::Create_Task(void **taskHandle_ref) {
  int error = DAQmxCreateTask("", taskHandle_ref);
  return error;
}

int NI_DAQmx_Vendor_Package::Start_Task(void *taskHandle) {
  int error = 0;
  DAQmxStartTask(taskHandle);
  return error;
}

int NI_DAQmx_Vendor_Package::Stop_Task(void *taskHandle) {
  int error = 0;
  DAQmxStopTask(taskHandle);
  return error;
}

int NI_DAQmx_Vendor_Package::Clear_Task(void *taskHandle) {
  int error = 0;
  DAQmxClearTask(taskHandle);
  return error;
}

int NI_DAQmx_Vendor_Package::Attach_Clock(void *taskHandle, char *Phys_Port,
                                          char *Task_Type, int numsamples,
                                          double rate) {
  int error = 0;
  if (*(Task_Type + 2) == 'c') {
    error = DAQmxCfgSampClkTiming(taskHandle, Phys_Port, rate, DAQmx_Val_Rising,
                                  DAQmx_Val_ContSamps, numsamples);
  } else {
    error = DAQmxCfgSampClkTiming(taskHandle, Phys_Port, rate, DAQmx_Val_Rising,
                                  DAQmx_Val_FiniteSamps, numsamples);
  }
  return 0;
}

int NI_DAQmx_Vendor_Package::Attach_Trigger(void *taskHandle, char *Phys_Port,
                                            bool rising_edge) {
  int error = DAQmxCfgDigEdgeStartTrig(taskHandle, Phys_Port,
                                       rising_edge ? (DAQmx_Val_Rising)
                                                   : (DAQmx_Val_Falling));
  return error;
}

int NI_DAQmx_Vendor_Package::Add_AI_Channel(void *taskHandle, char *Phys_Port,
                                            char *Channel_Name,
                                            int32 terminalConfig,
                                            float64 minval, float64 maxval) {
  int error = DAQmxCreateAIVoltageChan(taskHandle, Phys_Port, Channel_Name,
                                       terminalConfig, minval, maxval,
                                       DAQmx_Val_Volts, NULL);
  return error;
}

int NI_DAQmx_Vendor_Package::Add_AO_Channel(void *taskHandle, char *Phys_Port,
                                            char *Channel_Name,
                                            int32 terminalConfig,
                                            float64 minval, float64 maxval) {
  int error = DAQmxCreateAOVoltageChan(taskHandle, Phys_Port, Channel_Name,
                                       minval, maxval, DAQmx_Val_Volts, NULL);
  return error;
}

int NI_DAQmx_Vendor_Package::Add_DI_Channel(void *taskHandle, char *Phys_Port,
                                            char *Channel_Name) {
  int error = DAQmxCreateDIChan(taskHandle, Phys_Port, Channel_Name,
                                DAQmx_Val_ChanPerLine);
  return error;
}

int NI_DAQmx_Vendor_Package::Add_DO_Channel(void *taskHandle, char *Phys_Port,
                                            char *Channel_Name) {
  int error = DAQmxCreateDOChan(taskHandle, Phys_Port, Channel_Name,
                                DAQmx_Val_ChanPerLine);
  return error;
}

int NI_DAQmx_Vendor_Package::Add_CO_Channel(void *taskHandle, char *counter,
                                            char *Channel_Name, char *Phys_Port,
                                            int32 lowTicks, int32 highTicks,
                                            int32 sdelay) {
  int error =
      DAQmxCreateCOPulseChanTicks(taskHandle, counter, Channel_Name, Phys_Port,
                                  DAQmx_Val_Low, sdelay, lowTicks, highTicks);
  if (error == 0) {
    error = DAQmxCfgImplicitTiming(taskHandle, DAQmx_Val_ContSamps, 1000);
  }
  return error;
}

int NI_DAQmx_Vendor_Package::Add_CI_Channel(void *taskHandle, char *counter,
                                            char *Channel_Name,
                                            bool rising_edge) {
  int error = 0;
  DAQmxCreateCICountEdgesChan(taskHandle, counter, Channel_Name,
                              rising_edge ? (DAQmx_Val_Rising)
                                          : (DAQmx_Val_Falling),
                              0, DAQmx_Val_CountUp);
  return error;
}

int NI_DAQmx_Vendor_Package::Read_Analog_Data(void *taskHandle,
                                              double *data_target,
                                              int numsamples, int numchannels) {
  int error = 0;
  int32 samps_read;
  error = DAQmxReadAnalogF64(taskHandle, numsamples, -1,
                             DAQmx_Val_GroupByChannel, data_target,
                             numsamples * numchannels, &samps_read, NULL);
  return error;
}

int NI_DAQmx_Vendor_Package::Read_Counter_Data(void *taskHandle,
                                               double *data_target,
                                               int numsamples,
                                               int numchannels) {
  int error = 0;
  int32 samps_read;
  error = DAQmxReadCounterF64(taskHandle, numsamples, -1, data_target,
                              numsamples, &samps_read, NULL);
  return error;
}

int NI_DAQmx_Vendor_Package::Read_Digital_Data(void *taskHandle,
                                               uInt8 *data_target,
                                               int numsamples,
                                               int numchannels) {
  int error = 0;
  int32 samps_read;
  error = DAQmxReadDigitalU8(taskHandle, numsamples, -1,
                             DAQmx_Val_GroupByChannel, data_target,
                             numsamples * numchannels, &samps_read, NULL);
  return error;
}

int NI_DAQmx_Vendor_Package::Write_Analog_Data(void *taskHandle, double *data,
                                               int numsamples) {
  int error = 0;
  int32 samps_read;
  error =
      DAQmxWriteAnalogF64(taskHandle, numsamples, false, -1,
                          DAQmx_Val_GroupByChannel, data, &samps_read, NULL);
  return error;
}

int NI_DAQmx_Vendor_Package::Write_Counter_Data(void *taskHandle,
                                                uInt32 highticks,
                                                uInt32 lowticks) {
  int error = 0;
  error = DAQmxWriteCtrTicksScalar(taskHandle, false, -1, highticks, lowticks,
                                   NULL);
  return error;
}

int NI_DAQmx_Vendor_Package::Write_Digital_Data(void *taskHandle, uInt8 *data,
                                                int numsamples) {
  int32 samps_read;
  int error = DAQmxWriteDigitalLines(taskHandle, numsamples, false, -1,
                                     DAQmx_Val_GroupByChannel,
                                     (const uInt8 *)data, &samps_read, NULL);
  return error;
}

int NI_DAQmx_Vendor_Package::Attach_Callback_Method(void *taskHandle,
                                                    DAQ_Callback *CallFun,
                                                    int numsamples) {
  int error = DAQmxRegisterEveryNSamplesEvent(
      taskHandle, DAQmx_Val_Acquired_Into_Buffer, numsamples, 0, EveryNCallback,
      (void *)CallFun);
  printf("Callback Attached: error_code %d \n", error);
  return error;
}

int NI_DAQmx_Vendor_Package::Is_Task_Done(void *taskHandle, uInt32 *task_done) {
  int error = DAQmxIsTaskDone(taskHandle, task_done);
  return error;
}

int NI_DAQmx_Vendor_Package ::Connect_Terminals(char *Source_Terminal,
                                                char *Destination_Terminal) {
  int error = DAQmxConnectTerms(Source_Terminal, Destination_Terminal,
                                DAQmx_Val_DoNotInvertPolarity);
  return error;
}

int32 CVICALLBACK EveryNCallback(TaskHandle taskHandle,
                                 int32 everyNsamplesEventType, uInt32 nSamples,
                                 void *callbackData) {
  DAQ_Callback *CallFun = (DAQ_Callback *)callbackData;
  CallFun->CallbackFcn(CallFun->argpointer);

  return 0;
}