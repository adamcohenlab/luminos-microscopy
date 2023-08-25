#include "DAQ_Task.h"

DAQ_Task::DAQ_Task(int Task_Vendor) {
  if (Task_Vendor == 1) {
    Driver_Package = new NI_DAQmx_Vendor_Package;
  }
  Generate_taskHandle(); // a handle that NI_DAQmx provides 
  aux_tdata = NULL;
  task_data = NULL;

  numchannels = 0;
}

DAQ_Task::DAQ_Task(int Task_Vendor, string task_type_in)
    : task_type(task_type_in) {
  if (Task_Vendor == 1) {
    Driver_Package = new NI_DAQmx_Vendor_Package;
  }
  Generate_taskHandle();
  task_type = task_type_in;
  numchannels = 0;
  aux_tdata = NULL;
  task_data = NULL;
}

DAQ_Task::~DAQ_Task() { Clear_Task(); }

int DAQ_Task::Start_Task() { return Driver_Package->Start_Task(taskHandle); }

int DAQ_Task::Stop_Task() { return Driver_Package->Stop_Task(taskHandle); }

int DAQ_Task::Clear_Task() {
  if (task_data) {
    free(task_data);
    task_data = NULL;
    for (int i = 0; i < numchannels; i++) {
      Channel_Group[i].data = NULL;
    }
  }
  if (aux_tdata) {
    free(aux_tdata);
    aux_tdata = NULL;
  }

  numchannels = 0;
  numsamples = 0;
  return Driver_Package->Clear_Task(taskHandle);
}

int DAQ_Task::Allocate_Aux_Buffer(size_t numsamples) {
  aux_tdata = (double *)malloc(numsamples * sizeof(double));
  return 0;
}

int DAQ_Task::Generate_taskHandle() {
  return Driver_Package->Create_Task(&taskHandle);
}

int DAQ_Task::Add_Input_Channel(string Phys_Port, string Channel_Name) {
  int error = 0;
  numchannels = numchannels + 1;
  Channel_Group.emplace_back();
  Channel_Group[numchannels - 1].Phys_Port = string("test");
  Channel_Group[numchannels - 1].Phys_Port = Phys_Port;
  Channel_Group[numchannels - 1].Channel_Name = Channel_Name;
  const char *ctype = task_type.c_str();
  switch (*ctype) {
  case 'a':
    error = Driver_Package->Add_AI_Channel(
        taskHandle, (char *)Channel_Group[numchannels - 1].Phys_Port.c_str(),
        (char *)Channel_Group[numchannels - 1].Channel_Name.c_str(), -1, -10,
        10);
    Extend_taskdata((double *)task_data, false);
    break;
  case 'd':
    error = Driver_Package->Add_DI_Channel(
        taskHandle, (char *)Channel_Group[numchannels - 1].Phys_Port.c_str(),
        (char *)Channel_Group[numchannels - 1].Channel_Name.c_str());
    Extend_taskdata((uInt8 *)task_data, false);
    break;
  case 'c':
    error = Driver_Package->Add_CI_Channel(
        taskHandle, (char *)Channel_Group[numchannels - 1].Phys_Port.c_str(),
        (char *)Channel_Group[numchannels - 1].Channel_Name.c_str(), true);
    Extend_taskdata((double *)task_data, false);
    break;
  }
  return error;
}

int DAQ_Task::Add_Input_Channel(string Phys_Port, string Channel_Name,
                                double minval, double maxval,
                                int terminalConfig) {
  numchannels = numchannels + 1;
  Channel_Group.emplace_back();
  Channel_Group[numchannels - 1].Phys_Port = Phys_Port;
  Channel_Group[numchannels - 1].Channel_Name = Channel_Name;
  Channel_Group[numchannels - 1].min = minval;
  Channel_Group[numchannels - 1].max = maxval;

  int error = Driver_Package->Add_AI_Channel(
      taskHandle, (char *)Channel_Group[numchannels - 1].Phys_Port.c_str(),
      (char *)Channel_Group[numchannels - 1].Channel_Name.c_str(),
      (int32)terminalConfig, (float64)minval, (float64)maxval);
  Extend_taskdata((double *)task_data, false);
  return error;
}

int DAQ_Task::Add_Output_Channel(string Phys_Port, string Channel_Name,
                                 double *output_data) {
  numchannels = numchannels + 1;
  Channel_Group.emplace_back();
  Channel_Group[numchannels - 1].Phys_Port = Phys_Port;
  Channel_Group[numchannels - 1].Channel_Name = Channel_Name;
  int error = Driver_Package->Add_AO_Channel(
      taskHandle, (char *)Channel_Group[numchannels - 1].Phys_Port.c_str(),
      (char *)Channel_Group[numchannels - 1].Channel_Name.c_str(), 1, -10, 10);
  Extend_taskdata(output_data, true);
  return error;
}

int DAQ_Task::Add_Output_Channel(string Phys_Port, string Channel_Name,
                                 uInt8 *output_data) {
  numchannels = numchannels + 1;
  Channel_Group.emplace_back();
  Channel_Group[numchannels - 1].Phys_Port = Phys_Port;
  Channel_Group[numchannels - 1].Channel_Name = Channel_Name;
  int error = Driver_Package->Add_DO_Channel(
      taskHandle, (char *)Channel_Group[numchannels - 1].Phys_Port.c_str(),
      (char *)Channel_Group[numchannels - 1].Channel_Name.c_str());
  Extend_taskdata(output_data, true);
  return error;
}

int DAQ_Task::Add_Output_Channel(string Phys_Port, string Channel_Name,
                                 double *output_data, double minval,
                                 double maxval, int terminalConfig) {
  numchannels = numchannels + 1;
  Channel_Group.emplace_back();
  Channel_Group[numchannels - 1].Phys_Port = Phys_Port;
  Channel_Group[numchannels - 1].Channel_Name = Channel_Name;
  Channel_Group[numchannels - 1].min = minval;
  Channel_Group[numchannels - 1].max = maxval;

  int error = Driver_Package->Add_AO_Channel(
      taskHandle, (char *)Channel_Group[numchannels - 1].Phys_Port.c_str(),
      (char *)Channel_Group[numchannels - 1].Channel_Name.c_str(),
      (int32)terminalConfig, (float64)minval, (float64)maxval);
  Extend_taskdata(output_data, true);
  return error;
}

int DAQ_Task::Add_Output_Counter(string Phys_Port, string Channel_Name,
                                 string counter, int32 lowTicks,
                                 int32 highTicks, int32 startdelay) {
  numchannels = numchannels + 1;
  task_data = NULL;
  Channel_Group.emplace_back();
  Channel_Group[numchannels - 1].Phys_Port = Phys_Port;
  Channel_Group[numchannels - 1].Channel_Name = Channel_Name;
  int error = Driver_Package->Add_CO_Channel(
      taskHandle, (char *)counter.c_str(),
      (char *)Channel_Group[numchannels - 1].Channel_Name.c_str(),
      (char *)Channel_Group[numchannels - 1].Phys_Port.c_str(), lowTicks,
      highTicks, startdelay);
  return error;
}

int DAQ_Task::Update_Channel_Pointers() {
  const char *ctype = task_type.c_str();

  if ((*ctype) == 'd') {
    for (int i = 0; i < numchannels; i++) {
      Channel_Group[i].data = ((uInt8 *)task_data) + numsamples * i;
    }
  } else {
    for (int i = 0; i < numchannels; i++) {
      Channel_Group[i].data = ((double *)task_data) + numsamples * i;
    }
  }
  return 0;
}

int DAQ_Task::Extend_taskdata(double *new_channel_data, bool output_type) {
  if (numchannels > 1) {
    task_data = realloc(task_data, numsamples * numchannels * sizeof(double));
  } else {
    task_data = malloc(numsamples * sizeof(double));
  }
  for (int i = 0; i < numchannels; i++) {
    Channel_Group[i].data = ((double *)task_data) + numsamples * i;
  }
  if (output_type) {
    memcpy(Channel_Group[numchannels - 1].data, new_channel_data,
           numsamples * sizeof(double));
  }
  return 0;
}

int DAQ_Task::Extend_taskdata(uInt8 *new_channel_data, bool output_type) {
  if (numchannels > 1) {
    task_data = realloc(task_data, numsamples * numchannels * sizeof(uInt8));
  } else {
    task_data = malloc(numsamples * sizeof(uInt8));
  }
  for (int i = 0; i < numchannels; i++) {
    Channel_Group[i].data = ((uInt8 *)task_data) + numsamples * i;
  }
  if (output_type) {
    memcpy(Channel_Group[numchannels - 1].data, new_channel_data,
           numsamples * sizeof(uInt8));
  }
  return 0;
}

int DAQ_Task::Read_Data(int man_numsamples, int read_counter) {
  const char *ctype = task_type.c_str();
  int error = -1;
  switch (*ctype) {
  case 'a':
    error = Driver_Package->Read_Analog_Data(taskHandle, (double *)aux_tdata,
                                             man_numsamples, numchannels);
    for (int i = 0; i < numchannels; i++) {
      memcpy(((double *)task_data) + i * (uint64_t)numsamples +
                 (uint64_t)read_counter * man_numsamples,
             aux_tdata + i * (uint64_t)man_numsamples,
             man_numsamples * sizeof(double));
    }
    break;
  case 'd':
    error = Driver_Package->Read_Digital_Data(taskHandle, (uint8_t *)task_data,
                                              man_numsamples, numchannels);
    break;
  case 'c':
    error = Driver_Package->Read_Counter_Data(taskHandle, (double *)task_data,
                                              man_numsamples, numchannels);
    break;
  }
  return error;
}

int DAQ_Task::Read_Data(int man_numsamples, int read_counter,
                        int fragment_size) {
  const char *ctype = task_type.c_str();
  int error = -1;
  switch (*ctype) {
  case 'a':
    error = Driver_Package->Read_Analog_Data(taskHandle, (double *)aux_tdata,
                                             fragment_size, numchannels);
    for (int i = 0; i < numchannels; i++) {
      memcpy(((double *)task_data) + i * (uint64_t)numsamples +
                 (uint64_t)read_counter * man_numsamples,
             aux_tdata + i * (uint64_t)man_numsamples,
             fragment_size * sizeof(double));
    }
    break;
  case 'd':
    error = Driver_Package->Read_Digital_Data(taskHandle, (uint8_t *)task_data,
                                              man_numsamples, numchannels);
    break;
  case 'c':
    error = Driver_Package->Read_Counter_Data(taskHandle, (double *)task_data,
                                              man_numsamples, numchannels);
    break;
  }
  return error;
}

int DAQ_Task::Read_Data() {
  const char *ctype = task_type.c_str();
  int error = -1;
  switch (*ctype) {
  case 'a':
    error = Driver_Package->Read_Analog_Data(taskHandle, (double *)task_data,
                                             numsamples, numchannels);
    break;
  case 'd':
    error = Driver_Package->Read_Digital_Data(taskHandle, (uint8_t *)task_data,
                                              numsamples, numchannels);
    break;
  case 'c':
    error = Driver_Package->Read_Counter_Data(taskHandle, (double *)task_data,
                                              numsamples, numchannels);
    break;
  }
  return error;
}

int DAQ_Task::Write_Data() {
  const char *ctype = task_type.c_str();
  int error = -1;
  switch (*ctype) {
  case 'a':
    error = Driver_Package->Write_Analog_Data(taskHandle, (double *)task_data,
                                              numsamples);
    break;
  case 'd':
    error = Driver_Package->Write_Digital_Data(taskHandle, (uint8_t *)task_data,
                                               numsamples);
    break;
  }
  return error;
}

int DAQ_Task::Connect_Terminals(string Source_Terminal,
                                string Destination_Terminal) {
  return Driver_Package->Connect_Terminals(
      (char *)Source_Terminal.c_str(), (char *)Destination_Terminal.c_str());
}