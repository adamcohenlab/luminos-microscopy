#pragma once
#include "DAQ_Channel.h"
#include "DAQ_Vendor_Package.h"
#include "DAQ_Vendors.h"
#include "DAQ_Utilities.h"
#include <stdio.h>
#include <stdlib.h>
#include <string>
#include <vector>
#ifdef DAQ_EXPORTS
#define DAQ_API __declspec(dllexport)
#else
#define DAQ_API __declspec(dllimport)
#endif
using namespace std;
class DAQ_API DAQ_Task {
public:
  DAQ_Task(int Task_Vendor);
  DAQ_Task(int Task_Vendor, string task_type_in);
  ~DAQ_Task();
  int Generate_taskHandle();
  int Add_Input_Channel(string Phys_Port, string Channel_Name);
  int Add_Input_Channel(string Phys_Port, string Channel_Name, double minval,
                        double maxval, int terminalConfig);
  int Add_Output_Channel(string Phys_Port, string Channel_Name,
                         double *output_data);
  int Add_Output_Channel(string Phys_Port, string Channel_Name,
                         uInt8 *output_data);
  int Add_Output_Channel(string Phys_Port, string Channel_Name,
                         double *output_data, double minval, double maxval,
                         int terminalConfig);
  int Add_Output_Counter(string Phys_Port, string Channel_Name, string counter,
                         int32 lowTicks, int32 highTicks, int32 startdelay);
  int Read_Data();
  int Read_Data(int man_numsamples, int read_counter);
  int Read_Data(int man_numsamples, int read_counter, int fragment_size);
  int Write_Data();
  int Start_Task();
  int Stop_Task();
  int Clear_Task();
  int Allocate_Aux_Buffer(size_t numsamples);
  int Connect_Terminals(string Source_Terminal, string Destination_Terminal);
  string task_type;
  DAQ_Vendor_Package *Driver_Package;
  void *taskHandle;
  void *task_data;
  vector<DAQ_Channel> Channel_Group;
  int numchannels;
  int numsamples;
  char errBuff[2048];
  int Update_Channel_Pointers();
  double *aux_tdata;

private:
  int Extend_taskdata(uInt8 *new_channel_data, bool output_type);
  int Extend_taskdata(double *new_channel_data, bool output_type);
};
