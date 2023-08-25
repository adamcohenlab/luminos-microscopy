#include "DAQ_Buffered_Task.h"

int DAQ_Buffered_Task::Attach_Clock(string Phys_Port) {
  int error = Driver_Package->Attach_Clock(taskHandle, &Phys_Port[0],
                                           &task_type[0], numsamples, rate);
  return error;
}

int DAQ_Buffered_Task::Attach_Clock(string Phys_Port, int buffer_size) {
  int error = Driver_Package->Attach_Clock(taskHandle, &Phys_Port[0],
                                           &task_type[0], buffer_size, rate);
  return error;
}

int DAQ_Buffered_Task::Attach_Trigger(string Phys_Port, bool rising_edge) {
  int error =
      Driver_Package->Attach_Trigger(taskHandle, &Phys_Port[0], rising_edge);
  return error;
}

int DAQ_Buffered_Task::Attach_Callback_Method(DAQ_Callback *CallFun,
                                              int samps_per_callback) {
  int error = Driver_Package->Attach_Callback_Method(taskHandle, CallFun,
                                                     samps_per_callback);
  return error;
}

int DAQ_Buffered_Task::Is_Task_Done(uint32_t *taskdone) {
  int error = Driver_Package->Is_Task_Done(taskHandle, (uInt32 *)taskdone);
  return error;
}
