#include "Scanning_Device.h"

Scanning_Device::Scanning_Device(int DAQ_Vendor_Code, string galvox_physport_in,
                                 string galvoy_physport_in,
                                 string galvofbx_physport_in,
                                 string galvofby_physport_in,
                                 string PMT_physport_in, string timebase_source,
                                 string trigger_physport_in,
                                 string sync_counter_in, double sample_rate,
                                 double feedback_scaling, int galvos_only_in)

{
  feedback_scale = feedback_scaling;
  DAQ_Vendor = DAQ_Vendor_Code;
  newframeavailable = false;
  isCapturing = false;
  isRecording = false;
  int error;
  bin = 1;
  DQ_Transfer_Mutex = CreateMutex(NULL, FALSE, NULL);
  ghMutexCapturing = CreateMutex(NULL, FALSE, NULL);
  Galvo_Callback = NULL;
  LastFrame = (CamFrame *)malloc(sizeof(CamFrame));
  LastFrame->buf = NULL;
  lastframecleared = false;
  AI_Task = NULL;
  AO_Task = NULL;
  Galvo_Sync_Counter = NULL;
  holder_taskdata = NULL;
  framereset_switch = false;
  sampling_rate = sample_rate;

  galvos_only = galvos_only_in;

  sync_counter = sync_counter_in;

  time_source = timebase_source;

  time_source = timebase_source;
  galvox_physport = galvox_physport_in;
  galvoy_physport = galvoy_physport_in;
  galvofby_physport = galvofby_physport_in;
  galvofbx_physport = galvofbx_physport_in;

  ai_physports = PMT_physport_in;
  trigger_physport = trigger_physport_in;

  exposureTimeSeconds = 1 / sampling_rate;
  Display.attach_camera(this);
  Display.launch_disp_threads();
  Display.Launch_Handoff_Thread();
  Display.keydelta = .1;
  vmin = -5;
  vmax = 5;
  bin = 10;
  points_per_pixel = 2;
  newaidataavail = false;
  aidatamutex = CreateMutex(NULL, FALSE, NULL);
  fullROImode = false;
}
Scanning_Device::~Scanning_Device() { Cleanup(); }

int Scanning_Device::Restart_Live_Acq(double minx, double maxx, double miny,
                                      double maxy, double binning) {
  SDL_Rect ROIin;
  ROIin.x = (minx - vmin) * bin;
  ROIin.y = (miny - vmin) * bin;
  ROIin.w = (maxx - minx) * bin;
  ROIin.h = (maxy - miny) * bin;
  aq_live_restart(ROIin, binning, 1);
  return 0;
}

bool Scanning_Device::aq_live_restart(SDL_Rect ROIin, int binning,
                                      double exposureTime) {
  double *xwfm_pointer;
  double *ywfm_pointer;
  SDL_FRect reform_ROI;
  if (!fullROImode) {
    ROIin.x += 1;
    ROIin.y += 1;
  }
  fullROImode = false;
  reform_ROI.w = (double)ROIin.w / bin;
  reform_ROI.h = (double)ROIin.h / bin;
  reform_ROI.x = (double)ROIin.x / bin + vmin;
  reform_ROI.y = (double)ROIin.y / bin + vmin;

  ROI.w = ROIin.w * binning / bin;
  ROI.h = ROIin.h * binning / bin;
  ROI.x = ROIin.x * binning / bin;
  ROI.y = ROIin.y * binning / bin;

  bin = binning;

  int numpoints = Generate_Triangle_WFM(reform_ROI, bin * points_per_pixel,
                                        &xwfm_pointer, &ywfm_pointer);
  Update_Galvo_Scan(xwfm_pointer, ywfm_pointer, numpoints,
                    (int)(reform_ROI.w * bin), (int)(reform_ROI.h * bin));
  free(xwfm_pointer);
  free(ywfm_pointer);
  return false;
}

double Scanning_Device::find_sensor_size() {
  if (framereset_switch) {
    bin = 10;
    framereset_switch = false;
  }
  fullROImode = true;
  return (vmax - vmin) * bin;
}

void Scanning_Device::aq_live_stop() { Cleanup(); }

int Scanning_Device::Raster_From_Bounds(SDL_FRect ROIin, double points_per_V) {
  double *xwfm_pointer;
  double *ywfm_pointer;

  bin = points_per_V / points_per_pixel / feedback_scale;

  ROI.w = (double)ROIin.w * bin;
  ROI.h = (double)ROIin.h * bin;
  ROI.x = ((double)ROIin.x - vmin) * bin;
  ROI.y = ((double)ROIin.y - vmin) * bin;

  int numpoints = Generate_Triangle_WFM(ROIin, bin * points_per_pixel,
                                        &xwfm_pointer, &ywfm_pointer);
  Update_Galvo_Scan(xwfm_pointer, ywfm_pointer, numpoints, (int)(ROIin.w * bin),
                    (int)(ROIin.h * bin));
  free(xwfm_pointer);
  free(ywfm_pointer);
  return 0;
}

int Scanning_Device::Raster_From_Bounds_Sawtooth(SDL_FRect ROIin,
                                                 double points_per_V) {
  double *xwfm_pointer;
  double *ywfm_pointer;

  bin = points_per_V / points_per_pixel / feedback_scale;

  ROI.w = (double)ROIin.w * bin;
  ROI.h = (double)ROIin.h * bin;
  ROI.x = ((double)ROIin.x - vmin) * bin;
  ROI.y = ((double)ROIin.y - vmin) * bin;

  int numpoints = Generate_Raster_WFM(ROIin, bin * points_per_pixel,
                                      &xwfm_pointer, &ywfm_pointer);
  Update_Galvo_Scan(xwfm_pointer, ywfm_pointer, numpoints, (int)(ROIin.w * bin),
                    (int)(ROIin.h * bin));
  free(xwfm_pointer);
  free(ywfm_pointer);
  return 0;
}

int Scanning_Device::Generate_Triangle_WFM(SDL_FRect ROI, double points_per_V,
                                           double **xwfm_pointer,
                                           double **ywfm_pointer) {
  int columns = round(ROI.w * points_per_V);
  int rows = round(ROI.h * points_per_V);
  int numpoints = 2 * columns * rows;
  *xwfm_pointer = (double *)malloc(numpoints * sizeof(double));
  *ywfm_pointer = (double *)malloc(numpoints * sizeof(double));
  if ((*xwfm_pointer) != nullptr && (*ywfm_pointer) != nullptr) {
    for (int i = 0; i < numpoints; i++) {
      *((*xwfm_pointer) + i) =
          (((int)floor(i / columns) % 2) == 0)
              ? (ROI.x + (i % columns) * 1 / points_per_V)
              : ((ROI.x + ROI.w - (i % columns) * 1 / points_per_V));
      *((*ywfm_pointer) + i) =
          ROI.y + floor(i / (2 * columns)) * 1 / points_per_V;
    }
  }
  return numpoints;
}

int Scanning_Device::Generate_Raster_WFM(SDL_FRect ROI, double points_per_V,
                                         double **xwfm_pointer,
                                         double **ywfm_pointer) {
  int columns = round(ROI.w * points_per_V);
  int rows = round(ROI.h * points_per_V);
  int numpoints = columns * rows;
  *xwfm_pointer = (double *)malloc(numpoints * sizeof(double));
  *ywfm_pointer = (double *)malloc(numpoints * sizeof(double));
  if ((*xwfm_pointer) != nullptr && (*ywfm_pointer) != nullptr) {
    for (int i = 0; i < numpoints; i++) {
      *((*xwfm_pointer) + i) = ROI.x + (i % columns) * 1 / points_per_V;
      *((*ywfm_pointer) + i) = ROI.y + floor(i / columns) * 1 / points_per_V;
    }
  }
  return numpoints;
}

int Scanning_Device::Startup(double *galvoxdata, double *galvoydata,
                             int numsamples, int xpixels, int ypixels) {
  if (galvos_only == 0) {
    AI_Task = new DAQ_Buffered_Task(DAQ_Vendor, "aic");
    AI_Task->numsamples = numsamples;
    AI_Task->rate = sampling_rate;
  }
  AO_Task = new DAQ_Buffered_Task(DAQ_Vendor, "aoc");
  Galvo_Sync_Counter = new DAQ_Buffered_Task(DAQ_Vendor, "coc");

  AO_Task->numsamples = numsamples;
  AO_Task->rate = sampling_rate;

  read_counter = 0;

  holder_taskdata = (double *)malloc(numsamples * 3 * sizeof(double));

  double max_x = (*galvoxdata) * feedback_scale;
  double min_x = (*galvoxdata) * feedback_scale;
  double max_y = (*galvoydata) * feedback_scale;
  double min_y = (*galvoydata) * feedback_scale;
  for (int ii = 0; ii < numsamples; ii++) {
    if ((galvoxdata[ii] * feedback_scale) > max_x) {
      max_x = (galvoxdata[ii]) * feedback_scale;
    }
    if ((galvoxdata[ii] * feedback_scale) < min_x) {
      min_x = (galvoxdata[ii]) * feedback_scale;
    }
    if ((galvoydata[ii] * feedback_scale) > max_y) {
      max_y = (galvoydata[ii]) * feedback_scale;
    }
    if ((galvoydata[ii] * feedback_scale) < min_y) {
      min_y = (galvoydata[ii]) * feedback_scale;
    }
  }
  bin =
      ((double)xpixels / (max_x - min_x) + (double)ypixels / (max_y - min_y)) /
      2 * feedback_scale;
  Grid_Data.Set_Grid(min_x, max_x, min_y, max_y, xpixels, ypixels);
  ROI.x = (min_x / feedback_scale - vmin) * bin;
  ROI.y = (min_y / feedback_scale - vmin) * bin;
  ROI.w = round((max_x - min_x) * bin / feedback_scale);
  ROI.h = round((max_y - min_y) * bin / feedback_scale);

  // Grid_Data.Print_Grid();
  string DevName = galvox_physport.substr(0, galvox_physport.find("/"));
  int error;
  Galvo_Sync_Counter->Add_Output_Counter(
      string("/") + DevName + string("/ao/SampleClock"),
      string("Galvo_Sync_Counter"), sync_counter, AO_Task->numsamples / 2,
      AO_Task->numsamples - (AO_Task->numsamples / 2), 0);

  error = AO_Task->Add_Output_Channel(galvox_physport, string("galvo_x"),
                                      galvoxdata, -10, 10, -1);
  galvox_Channel = AO_Task->numchannels;

  error = AO_Task->Add_Output_Channel(galvoy_physport, string("galvo_y"),
                                      galvoydata, -10, 10, -1);
  galvoy_Channel = AO_Task->numchannels;

  if (galvos_only == 0) {
    error = AI_Task->Add_Input_Channel(galvofbx_physport, string("galvfb_x"),
                                       -10, 10, -1);
    galvofbx_Channel = AI_Task->numchannels;

    error = AI_Task->Add_Input_Channel(galvofby_physport, string("galvfb_y"),
                                       -10, 10, -1);
    galvofby_Channel = AI_Task->numchannels;

    error =
        AI_Task->Add_Input_Channel(ai_physports, string("PMT"), -10, 10, -1);
    PMT_Channel = AI_Task->numchannels;
    error = AI_Task->Attach_Clock(time_source, AI_Task->numsamples * 10);
  }
  error = AO_Task->Attach_Clock(time_source);

  error = Galvo_Sync_Counter->Start_Task();
  error = AO_Task->Write_Data();
  error = AO_Task->Start_Task();
  if (galvos_only == 0) {
    isCapturing = true;
    Launch_Read_Thread();
    error = AI_Task->Start_Task();
  }
  return 0;
};

int Scanning_Device::Launch_Read_Thread() {
  unsigned sdthreadid;
  unsigned sdthreadid2;
  ReadThread = (HANDLE)_beginthreadex(NULL, 1e8, &Read_Explicit, (void *)this,
                                      0, &sdthreadid);
  GridThread = (HANDLE)_beginthreadex(NULL, 1e8, &GetLastFrame, (void *)this, 0,
                                      &sdthreadid2);
  return 0;
}

unsigned __stdcall Read_Explicit(void *pArguments) {
  Scanning_Device *cfcl_ptr = (Scanning_Device *)pArguments;
  int i = 0;
  int error = 0;
  cfcl_ptr->newaidataavail = false;
  while (cfcl_ptr->isCapturing) {
    error = cfcl_ptr->AI_Task->Read_Data();

    if (cfcl_ptr->newaidataavail) {
    } else {
      WaitForSingleObject(cfcl_ptr->aidatamutex, 10);
      memcpy(cfcl_ptr->holder_taskdata, cfcl_ptr->AI_Task->task_data,
             (double)cfcl_ptr->AI_Task->numsamples * 3 * sizeof(double));
      cfcl_ptr->newaidataavail = true;
      ReleaseMutex(cfcl_ptr->aidatamutex);
    }
    if (error != 0) {
      printf("error_detected_in_read! %d", error);
    }
  }
  cfcl_ptr->AI_Task->Stop_Task();
  _endthreadex(0);
  return 0;
}

unsigned __stdcall GetLastFrame(void *pArguments) {
  Scanning_Device *cfcl_ptr = (Scanning_Device *)pArguments;
  double totxshift = 0;
  double totyshift = 0;
  double *fbx_ptr;
  double *fby_ptr;
  double *xptr;
  double *yptr;
  double meanxshift;
  double meanyshift;
  int numsamples;
  while (cfcl_ptr->isCapturing) {
    cfcl_ptr->lastframecleared = false;
    WaitForSingleObject(cfcl_ptr->DQ_Transfer_Mutex, 100);
    WaitForSingleObject(cfcl_ptr->aidatamutex, INFINITE);
    numsamples = cfcl_ptr->AO_Task->numsamples;
    fbx_ptr = cfcl_ptr->holder_taskdata +
              (numsamples * (cfcl_ptr->galvofbx_Channel - 1));
    fby_ptr = cfcl_ptr->holder_taskdata +
              (numsamples * (cfcl_ptr->galvofby_Channel - 1));
    xptr = (double *)cfcl_ptr->AO_Task->task_data;
    yptr = (double *)cfcl_ptr->AO_Task->task_data + numsamples;

    if (cfcl_ptr->newaidataavail) {
      totxshift = 0;
      totyshift = 0;
      for (int i = 0; i < cfcl_ptr->AO_Task->numsamples; i++) {
        totxshift += xptr[i] * cfcl_ptr->feedback_scale - fbx_ptr[i];
        totyshift += yptr[i] * cfcl_ptr->feedback_scale - fby_ptr[i];
      }
      meanyshift = totyshift / numsamples;
      meanxshift = totxshift / numsamples;
      cfcl_ptr->Grid_Data.Update_Data_DCShift(
          cfcl_ptr->holder_taskdata +
              (numsamples * (cfcl_ptr->galvofbx_Channel - 1)),
          cfcl_ptr->holder_taskdata +
              (numsamples * (cfcl_ptr->galvofby_Channel - 1)),
          cfcl_ptr->holder_taskdata +
              (numsamples * (cfcl_ptr->PMT_Channel - 1)),
          numsamples, meanxshift, meanyshift);
      cfcl_ptr->newaidataavail = false;
      ReleaseMutex(cfcl_ptr->aidatamutex);
    } else {
      ReleaseMutex(cfcl_ptr->aidatamutex);
    }
    // Grid_Data.Print_Values();
    ReleaseMutex(cfcl_ptr->DQ_Transfer_Mutex);
    cfcl_ptr->newframeavailable = true;
  }
  cfcl_ptr->lastframecleared = true;
  _endthreadex(0);
  return 0;
}

int Scanning_Device::Acq_Sync_Frames(double *galvoxdata, double *galvoydata,
                                     int numsamples_per_frame, int nframes,
                                     string trigger_source) {
  isCapturing = false;
  Cleanup();
  AI_Task = new DAQ_Buffered_Task(DAQ_Vendor, "aif");
  AO_Task = new DAQ_Buffered_Task(DAQ_Vendor, "aoc");
  Galvo_Sync_Counter = new DAQ_Buffered_Task(DAQ_Vendor, "coc");
  AO_Task->numsamples = numsamples_per_frame;
  AI_Task->numsamples = numsamples_per_frame * nframes;
  AO_Task->rate = sampling_rate;
  AI_Task->rate = sampling_rate;

  int error;
  error = Galvo_Sync_Counter->Add_Output_Counter(
      time_source, string("Galvo_Sync_Counter"), sync_counter,
      AO_Task->numsamples / 2, AO_Task->numsamples / 2, 0);

  error = AO_Task->Add_Output_Channel(galvox_physport, string("galvo_x"),
                                      galvoxdata, -10, 10, -1);
  galvox_Channel = AO_Task->numchannels;

  error = AO_Task->Add_Output_Channel(galvoy_physport, string("galvo_y"),
                                      galvoydata, -10, 10, -1);
  galvoy_Channel = AO_Task->numchannels;

  error = AI_Task->Add_Input_Channel(galvofbx_physport, string("galvfb_x"), -10,
                                     10, -1);
  galvofbx_Channel = AI_Task->numchannels;

  error = AI_Task->Add_Input_Channel(galvofby_physport, string("galvfb_y"), -10,
                                     10, -1);
  galvofby_Channel = AI_Task->numchannels;

  error = AI_Task->Add_Input_Channel(ai_physports, string("PMT"), -10, 10, -1);
  PMT_Channel = AI_Task->numchannels;

  error = AO_Task->Attach_Clock(time_source);
  error = AI_Task->Attach_Clock(time_source);
  error = AI_Task->Attach_Trigger(trigger_source, true);
  error = AO_Task->Attach_Trigger(trigger_source, true);
  error = Galvo_Sync_Counter->Attach_Trigger(trigger_source, true);
  error = Galvo_Sync_Counter->Start_Task();
  error = AO_Task->Write_Data();
  error = AO_Task->Start_Task();
  error = AI_Task->Start_Task();
  isRecording = true;
  isCapturing = true;
  return 0;
};

int Scanning_Device::Get_AI_Data() {
  int error = 0;
  AI_Task->Read_Data();
  return error;
}

int Scanning_Device::Cleanup() {
  isCapturing = false;
  isRecording = false;
  uint32_t taskdone = 0;

  if (AI_Task) {
    while (taskdone == 0) {
      AI_Task->Is_Task_Done(&taskdone);
    }
    while (lastframecleared == false) {
    };
    AI_Task->Clear_Task();
    delete AI_Task;
    AI_Task = NULL;
  }

  if (holder_taskdata) {
    free(holder_taskdata);
    holder_taskdata = NULL;
  }
  if (AO_Task) {
    AO_Task->Clear_Task();
    delete AO_Task;
    AO_Task = NULL;
  }

  if (Galvo_Sync_Counter) {
    Galvo_Sync_Counter->Clear_Task();
    delete Galvo_Sync_Counter;
    Galvo_Sync_Counter = NULL;
  }
  return 0;
}

int Scanning_Device::Update_Galvo_Scan(double *galvox_scandata,
                                       double *galvoy_scandata, int numsamples,
                                       int xpixels, int ypixels) {
  Cleanup();
  Startup(galvox_scandata, galvoy_scandata, numsamples, xpixels, ypixels);
  return 0;
};

int Scanning_Device::Acq_Frames(int numframes) {
  uint32_t taskdone = 0;
  isCapturing = false;
  if (AI_Task) {

    while (taskdone == 0) {
      AI_Task->Is_Task_Done(&taskdone);
    }
    AI_Task->Clear_Task();
    delete AI_Task;
    AI_Task = NULL;
  }
  AI_Task = new DAQ_Buffered_Task(DAQ_Vendor, "aif");
  isRecording = true;
  int numsamples_per_frame = AO_Task->numsamples;
  int total_samples = numsamples_per_frame * numframes;
  AI_Task->rate = sampling_rate;
  AI_Task->numsamples = total_samples;
  int error = AI_Task->Add_Input_Channel(galvofbx_physport, string("galvfb_x"),
                                         -10, 10, -1);
  galvofbx_Channel = AI_Task->numchannels;

  error = AI_Task->Add_Input_Channel(galvofby_physport, string("galvfb_y"), -10,
                                     10, -1);
  galvofby_Channel = AI_Task->numchannels;

  error = AI_Task->Add_Input_Channel(ai_physports, string("PMT"), -10, 10, -1);
  PMT_Channel = AI_Task->numchannels;
  error = AI_Task->Attach_Clock(time_source);
  error = AI_Task->Attach_Trigger(
      string("/") + sync_counter + string("InternalOutput"), true);
  error = AI_Task->Start_Task();
  isCapturing = false;
  isRecording = false;
  return 0;
}

int Scanning_Device::aq_live_restart() {
  fullROImode = true;
  aq_live_restart(ROI, bin, 1);
  return 0;
}

int Scanning_Device::Is_Acq_Done(uint32_t *taskdone) {
  return AI_Task->Is_Task_Done(taskdone);
}

CamFrame *Scanning_Device::aq_thread_snap() {
  WaitForSingleObject(DQ_Transfer_Mutex, INFINITE);
  if ((!newframeavailable) || (!AI_Task)) {
    return NULL;
  }
  if (LastFrame->buf == nullptr) {
    LastFrame->buf =
        (uint16_t *)malloc(Grid_Data.numx * Grid_Data.numy * sizeof(uint16_t));
  } else {
    if ((LastFrame->height * LastFrame->width) !=
        Grid_Data.numx * Grid_Data.numy) {
      LastFrame->buf = (uint16_t *)realloc(
          LastFrame->buf, Grid_Data.numx * Grid_Data.numy * sizeof(uint16_t));
    }
  }
  if (LastFrame->buf != nullptr) {
    Grid_Data.Data.Copy_Scaled_Subarray(
        (uint16_t *)LastFrame->buf, 0, 0, Grid_Data.numy, Grid_Data.numx,
        AI_Task->Channel_Group[PMT_Channel - 1].min,
        AI_Task->Channel_Group[PMT_Channel - 1].max);
  }
  ReleaseMutex(DQ_Transfer_Mutex);
  LastFrame->height = Grid_Data.numy;
  LastFrame->width = Grid_Data.numx;
  LastFrame->top = 0;
  LastFrame->left = 0;
  newframeavailable = false;
  return LastFrame;
}
