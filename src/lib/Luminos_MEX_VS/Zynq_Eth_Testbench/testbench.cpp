#include <stdlib.h>
#include <crtdbg.h>
#include <iostream>
#include "RAS_Zynq_AD.h"

int main(int argc, char *argv[]) {
  RAS_Zynq_AD *AD = new RAS_Zynq_AD(std::string("192.168.1.10"), 7);
  AD->Connect_to_Zynq();
  Sleep(1000);
  AD->SetAutoTriggerMode(0);
  Sleep(1000);
  AD->Set_AUX_Delay(6);
  Sleep(1000);
  AD->Set_HS_Delay(16);
  Sleep(1000);
  AD->Configure_Task(458000 * 10);
  Sleep(1000);
  AD->SetTestRampMode(1);
  Sleep(1000);
  getchar();
  AD->Start_Task();
  while (AD->taskdone == 0) {
  }
  /*for (int i = 0; i < 458000*5; i++) {
          if (*(AD->HS_Buffer + i % 64) != *(AD->HS_Buffer + i)) {
                  printf("Error at %d", i);
          }
  }*/
  delete (AD);
  return 0;
}