#pragma once
#include "DAQ_Task.h"

class DAQ_API DAQ_Buffered_Task : public DAQ_Task {
public:
  DAQ_Buffered_Task(int Task_Vendor, string task_type)
      : DAQ_Task(Task_Vendor, task_type){};
  int Attach_Clock(string Phys_Port, int buffer_size);
  string clock;
  string trigger;
  double rate;
  int Attach_Clock(string Phys_Port);
  int Attach_Trigger(string Phys_Port, bool rising_edge);
  int Attach_Callback_Method(DAQ_Callback *CallFun, int samps_per_callback);
  int Is_Task_Done(uint32_t *task_done);
};
