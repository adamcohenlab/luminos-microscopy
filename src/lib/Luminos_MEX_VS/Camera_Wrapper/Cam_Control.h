#pragma once
#include "Params_disp.h"
#include "CamFrame.h"
#include <windows.h>
#include "SDL.h"
#include <stdio.h>
#include <math.h>
#include <windows.h> // for threads, mutex
#include <process.h> // for threads, mutex
#include "Streaming_Device.h"
class Streaming_Device;
//Cam_Control prototype
class Cam_Control: public Streaming_Device {
#pragma message ("Cam_Control_Defined")
public:
	virtual CamFrame* aq_snap(void) = 0;
	virtual CamFrame* aq_thread_snap(void) = 0;
	virtual bool aq_live_restart()=0;
	virtual bool aq_live_restart(SDL_Rect inputROI, int binning, double exposureTime) = 0;
	virtual bool aq_sync_prepare(SDL_Rect inputROI, int binning, double exposureTime) = 0;
	virtual bool aq_sync_start(int32 recordFrames, const char* fpath) = 0;
	virtual void aq_sync_stop() = 0;
	virtual bool dc_shutdown() = 0;
	bool rdrive_mode;
	int dropped_frame_count;
	int acq_done;
	int read_mode;
};