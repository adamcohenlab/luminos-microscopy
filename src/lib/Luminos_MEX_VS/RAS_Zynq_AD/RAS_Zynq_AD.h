#pragma once
#include <winsock2.h>
#include <ws2tcpip.h>
#include <stdlib.h>
#include <stdio.h>
#include <iphlpapi.h>
#include <fstream>
#include <string>
#include <vector>
#include <process.h> // for threads, mutex
#include <atomic>
#pragma comment(lib, "Ws2_32.lib")

#define DEFAULT_BUFLEN 512
#define MAX_PULSES_PER_PACKET 458000
#define HS_SAMPLES_PER_PULSE 64
#define AUX_SAMPLES_PER_PULSE 3
#define HS_BYTES_PER_BURST (MAX_PULSES_PER_PACKET * 2 * HS_SAMPLES_PER_PULSE)
#define AUX_BYTES_PER_BURST (MAX_PULSES_PER_PACKET * 4 * AUX_SAMPLES_PER_PULSE)
#define TOTAL_BYTES_PER_BURST (HS_BYTES_PER_BURST + AUX_BYTES_PER_BURST)

#ifdef HD_RAS_Zynq_EXPORTS
#define HD_RAS_Zynq_API __declspec(dllexport)
#else
#define HD_RAS_Zynq_API __declspec(dllimport)
#endif

using namespace std;

unsigned Receive_Data(void *pArguments);
unsigned Process_Buffer_Threaded(void *pArguments);

class HD_RAS_Zynq_API RAS_Zynq_AD {
public:
  RAS_Zynq_AD(string ip_address, uint32_t port_in);
  ~RAS_Zynq_AD();
  int Connect_to_Zynq();
  int Allocate_Buffer();
  int Configure_Task(uint64_t numpulses_in);
  int SetAutoTriggerMode(char mode);
  int SetTestRampMode(char mode);
  int Set_HS_Delay(uint8_t delay);
  int Set_AUX_Delay(uint8_t delay);
  int Send_Command(char command, char argument);
  int Start_Task();
  int Process_Buffer();
  int SetAmplifierGain(int8_t gain);
  int Post_Process_AuxData();
  int Process_Buffer_Continuous();
  int16_t *HS_Buffer;
  uint32_t *Aux_Buffer;
  uint16_t *Aux_DataA;
  uint16_t *Aux_DataB;
  char *task_buff_a;
  char *task_buff_b;
  volatile char *task_data;
  volatile char *processing_pointer;
  string target_filename;

  SOCKADDR_IN *target;

  WSADATA wsdata;
  SOCKET connection_socket;
  string tcpip_address;
  uint32_t port;
  int databufflen;
  int numbursts;
  int numpulses;
  uint16_t burst_counter;
  uint16_t bursts_requested;
  HANDLE Data_Transfer_Mutex;
  HANDLE read_data_thread;
  HANDLE process_buffer_thread;
  atomic_bool data_available;
  atomic_uint8_t taskdone;
};
