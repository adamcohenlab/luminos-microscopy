#pragma once
#include "StreamDisplayHD.h"
#include "DAQ_Buffered_Task.h"
#include "HD_Grid_Data.h"
#include "Streaming_Device.h"

class Streaming_Device;
class LUMINOSCONFOCAL_API Scanning_Device :public Streaming_Device
{
public:
	Scanning_Device(int DAQ_Vendor_Code, string galvox_physport_in, string galvoy_physport_in, string galvofbx_physport_in,
		string galvofby_physport_in, string PMT_physport_in, string timebase_source, string trigger_physport_in, string sync_counter_in, double sampling_rate,
		double feedback_scaling, int galvos_only_in);
	~Scanning_Device();
	int Startup(double* galvoxdata, double* galvoydata, int numsamples, int xpixles, int ypixels);
	int Startup(double* galvoxdata, double* galvoydata, int numsamples, int xpixles, int ypixels, string trigger_source);
	int Reset_Display();
	int Restart_Live_Acq(double minx,double maxx,double miny,double maxy,double binning);
	CamFrame* aq_thread_snap(void);
	bool aq_live_restart(SDL_Rect inputROI, int binning, double exposureTime);
	int Acq_Sync_Frames(double* galvoxdata, double* galvoydata, int numsamples_per_frame, int nframes, string trigger_source);

	int Construct_Callback_Info();
	DAQ_Callback* Galvo_Callback;

	void aq_live_stop();
	double find_sensor_size();
	int Get_AI_Data();
	int Update_Galvo_Scan(double* galvox_scandata,double* galvoy_scandata,int numsamples, int xpixles, int ypixels);
	int Cleanup();
	int Acq_Frames(int numframes);
	int Acq_Frames(int numframes,string trigger_source);
	int Launch_Read_Thread();
	int aq_live_restart();

	int Is_Acq_Done(uint32_t* taskdone);
	int Generate_Raster_WFM(SDL_FRect ROI, double points_per_V, double** xwfm_pointer, double** ywfm_pointer);
	int Generate_Triangle_WFM(SDL_FRect ROI, double points_per_V, double** xwfm_pointer, double** ywfm_pointer);

	int Raster_From_Bounds(SDL_FRect ROIin, double points_per_V);
	int Raster_From_Bounds_Sawtooth(SDL_FRect ROIin, double points_per_V);
	

	int galvos_only;
	bool lastframecleared;
	bool fullROImode;
	int DAQ_Vendor;
	double feedback_scale;
	StreamDisplayHD Display;
	HD_Grid_Data Grid_Data;
	int samples_per_frame;
	double* galvox_scandata;
	double* galvoy_scandata;
	double* galvofbx_data;
	double* galvofby_data;
	double* PMT_Data;
	double* Reference_Data;
	bool internal_trigger;
	DAQ_Buffered_Task* AO_Task;
	DAQ_Buffered_Task* AI_Task;
	DAQ_Buffered_Task* Galvo_Sync_Counter;
	int PMT_Channel;
	int galvox_Channel;
	int galvoy_Channel;
	int galvofbx_Channel;
	int galvofby_Channel;
	double sampling_rate;
	DAQ_Callback cb1;

	double vmax;
	double vmin;
	int points_per_pixel;


	string time_source;
	string sync_counter;
	string galvox_physport;
	string galvoy_physport;
	string galvofbx_physport;
	string galvofby_physport;
	string ai_physports;
	
	string galvo_channames;
	string ai_channames;
	string trigger_physport;
	bool Raster_Mode;
	HANDLE DQ_Transfer_Mutex;
	bool newframeavailable;

	int read_counter;
	int sub_buffersize;
	int read_limit;

	HANDLE ReadReadyMutex;
	HANDLE ReadThread;

	HANDLE GridDataMutex;
	HANDLE aidatamutex;
	HANDLE GridThread;
	bool newaidataavail;
	double* holder_taskdata;
};

void Galvo_Callback_Fcn(void* args);
unsigned __stdcall Read_Explicit(void* pArguments);
unsigned __stdcall GetLastFrame(void* pArguments);