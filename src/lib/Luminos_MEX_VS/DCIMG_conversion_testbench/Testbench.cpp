#ifdef HAMAMATSU_CONFIGURED

#define _CRTDBG_MAP_ALLOC
#include <Windows.h>
#include <iostream>
#include <stdlib.h>
#include <crtdbg.h>
#include "dcimg2bin.h"
#include <chrono>
using namespace std::chrono;
int main(int argc, char* argv[])
{
#define LINEBYLINE 0
  const char *dcimg_fname =
      "C:\\Users\\Labmember\\Desktop\\Rebecca\\20231129\\174658_FRG1c_D1F1v7_2OvaryB_WF_10Hz\\frames1.dcimg";
  const char *fname_bin_tgt =
      "C:\\Users\\Labmember\\Desktop\\Rebecca\\20231129\\174658_FRG1c_D1F1v7_2OvaryB_WF_10Hz\\frames1_new.bin";
  auto start = high_resolution_clock::now();
  convert_file(dcimg_fname, fname_bin_tgt);
  auto stop = high_resolution_clock::now();
  auto duration = duration_cast<milliseconds>(stop - start);
  printf("New method: %d seconds\n", duration.count()/1000);
 
 /*dcimg_fname = "C:\\Users\\Labmember\\Desktop\\Phil "
                "Brooks\\dcimg_testing\\frames2.dcimg";
 fname_bin_tgt = "C:\\Users\\Labmember\\Desktop\\Phil "
                  "Brooks\\dcimg_testing\\frames1_old.bin";
#define LINEBYLINE 0
start = high_resolution_clock::now();
  convert_file(dcimg_fname, fname_bin_tgt);
stop = high_resolution_clock::now();
duration = duration_cast<milliseconds>(stop - start);
  printf("Old method: %d seconds\n", duration.count() / 1000);*/
	_CrtDumpMemoryLeaks();
	return 0;
}

#endif