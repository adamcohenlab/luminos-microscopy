#include "tb.h"
#include "DAQ_Buffered_Task.h"
#undef main
#define RT_2 1.41421356237
int main() {

  DAQ_Buffered_Task *AI_Task;
  AI_Task = new DAQ_Buffered_Task(
      1, "aic"); // the task type actually matters (see DAQ_Task::Write_Data)
  int numSamples = 10;
  int sampling_rate = 500000;
  std::string galovox_physport =
      "Dev2/ai1"; // dev3 is the name of the USB port on your computer that the
                  // DAQ is connected to, ai1 means the first analog input port
                  // on the DAQ (see metal plate on DAQ for where ai1 is)

  AI_Task->numsamples = numSamples;
  AI_Task->rate = sampling_rate;

  // double *galvoxdata;

  double minval = -10;
  double maxval = 10;
  int terminalConfig = -1;

  int error = AI_Task->Add_Input_Channel(galovox_physport, "galvo_x", minval,
                                         maxval, terminalConfig);

  error = AI_Task->Start_Task(); // prepare task to begin reading data
  error = AI_Task->Read_Data();  // read data from the DAQ

  double *task_data = (double *)AI_Task->task_data;

  // print the task_data array
  for (int i = 0; i < numSamples + 5; i++) {
    cout << "task_data[" << i << "] = " << task_data[i] << endl;
  } // the last 5 samples give weird values, as expected

  uint32_t taskdone = 0;
  AI_Task->Is_Task_Done(&taskdone);
  cout << "taskdone = " << taskdone << endl; // 0 means yes

  return 0;
  // AI_Task->Add_Input_Channel() return 0;
}
