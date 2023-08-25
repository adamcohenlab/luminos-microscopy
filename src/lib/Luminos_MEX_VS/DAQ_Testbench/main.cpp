#include "tb.h"
#include "DAQ_Buffered_Task.h"
#undef main
#define RT_2 1.41421356237
int main() {
  /*   Scanning_Device* cfcl = new Scanning_Device(1, "Dev2/ao0", "Dev2/ao1",
     "Dev2/ai2", "Dev2/ai3", "Dev2/ai0", "", "", "Dev2/Ctr0", 100e3, .25);
     double* galvoxdata = (double*)malloc(20000 * sizeof(double));
     double* galvoydata = (double*)malloc(20000 * sizeof(double));

     for (int i = 0; i < 10e3; i++) {
         galvoxdata[i] = (double)(i % 100)/10-5;
         galvoydata[i] = floor(((double)i)/100)/10 - 5;
     }

     double* galvoxdata2 = (double*)malloc(10e3 * sizeof(double));
     double* galvoydata2 = (double*)malloc(10e3 * sizeof(double));

     for (int i = 0; i < 10e3; i++) {
         galvoxdata2[i] = (double)(i % 100) / 200 - .25;
         galvoydata2[i] = floor(((double)i) / 100) / 200 - .25;
     }

     cfcl->Startup(galvoxdata, galvoydata, 10e3,100,100);
     getchar();
     SDL_FRect ROItest;
     ROItest.x = -5;
     ROItest.y = -5;
     ROItest.w = 10;
     ROItest.h = 10;

     cfcl->Raster_From_Bounds(ROItest, 10);
     getchar();
     cfcl->Acq_Frames(10);
     getchar();
     cfcl->AI_Task->Read_Data();
     getchar();
     cfcl->aq_live_restart();
     getchar();
     delete cfcl;
     getchar();
     */
  DAQ_Buffered_Task *DO_Task = new DAQ_Buffered_Task(1, std::string("doc"));
  return 0;
}
