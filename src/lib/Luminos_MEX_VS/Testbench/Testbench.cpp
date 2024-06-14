#define _CRTDBG_MAP_ALLOC
#include <Windows.h>
#include <iostream>
#include "Cam_Wrapper.h"
#include <stdlib.h>
#include <crtdbg.h>


int main(int argc, char *argv[]) {
  std::string ppath = "E:\\Luminos_data\\testbench\\test";
  Cam_Wrapper *cwrapper = new Cam_Wrapper(Cam_Wrapper::TYPE_KINETIX, "");


  bool keepgoing = true;
  int i, j;
  int bufindex = 0;
  int bufavail = 0;
  char ix = '0';
  double *cont_buf = (double *)malloc(sizeof(double));
  double *ROI_Buf = (double *)malloc(1e6 * sizeof(double));
  int32 *roicoords = (int32 *)malloc(4 * sizeof(int32));
  char c;
  while (ix != 'q') {
    ix = getchar();
    if (ix == 'r') {
      bufindex = 0;
      for (int j = 0; j < 10; j++) {
        bufavail = cwrapper->ROI_Buff_Avail();
        while (bufavail < 10) {
          bufavail = cwrapper->ROI_Buff_Avail();
        }
        cwrapper->Get_ROI_Buffer(ROI_Buf + bufindex, bufavail);
        bufindex += bufavail;
        Sleep(100);
      }
      for (int j = 0; j < bufindex; j++) {
        printf("%f \t", *(ROI_Buf + j));
      }
      printf("\n");
    }
    if (ix == 'c') {
      bufavail = cwrapper->Get_Contour_numel();
      cont_buf = (double *)realloc(cont_buf, bufavail * sizeof(double));
      i = 0;
      while (i < 10) {
        if (cwrapper->Contour_Data_Ready()) {
          cwrapper->Get_Contour_Data(cont_buf, bufavail);
          for (j = 0; j < bufavail; j++) {
            printf("%f \t", *(cont_buf + j));
          }
          printf("\n");
          i++;
        }
      }
      free(cont_buf);
    }
    if (ix == 'e') {
      double expt;
      std::cin >> expt;
      cwrapper->Set_Exposure(expt);
    }

    if (ix == 'g') {
      cwrapper->GetROI(roicoords);
      for (i = 0; i < 4; i++) {
        printf("%d \t", *(roicoords + i));
      }
      printf("\n");
    }
    if (ix == 's') {
      for (i = 0; i < 4; i++) {
        std::cin >> roicoords[i];
      }
      printf("\n");
      cwrapper->Set_ROI(roicoords);
    }

    if (ix == 't') {
      cwrapper->Set_Read_Mode(1);
    }

    if (ix == 'b') {
      for (i = 0; i < 4; i++) {
        std::cin >> roicoords[i];
        // print roicoords
        printf("roicoords[%d] = %d \n", i, roicoords[i]);
      }
      cwrapper->Set_RDrive_Mode(0);
      printf("\n");
      cwrapper->Prepare_Sync_Acquisition(1, roicoords, 1);
      Sleep(1);
      cwrapper->Start_Acquisition(10, ppath.c_str());
    }

    if (ix == 'a') {
      roicoords[0] = 1400;
      roicoords[1] = 448;
      roicoords[2] = 1400;
      roicoords[3] = 300;
      cwrapper->Set_RDrive_Mode(0);
      printf("\n");
      cwrapper->Prepare_Sync_Acquisition(0.00125, roicoords, 1);
      Sleep(1);
      cwrapper->Start_Acquisition(10000, ppath.c_str());
      //Sleep(20000);
      //cwrapper->Set_Exposure(0.00125);
    }
  }

  delete cwrapper;
  free(ROI_Buf);
  free(roicoords);
  free(cont_buf);
  _CrtDumpMemoryLeaks();
  return 0;
}
