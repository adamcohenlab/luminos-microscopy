#include "RAS_Zynq_AD.h"

RAS_Zynq_AD::RAS_Zynq_AD(string ip_address, uint32_t port_in) {
  target = (SOCKADDR_IN *)malloc(sizeof(SOCKADDR_IN));
  if (target) {
    target->sin_family = AF_INET;
    target->sin_port = htons(port_in);
    inet_pton(AF_INET, ip_address.c_str(), &(target->sin_addr.s_addr));
  }
  task_buff_a = NULL;
  task_buff_b = NULL;
  HS_Buffer = NULL;
  Aux_Buffer = NULL;
  Aux_DataA = NULL;
  Aux_DataB = NULL;
  tcpip_address = ip_address;
  port = port_in;
  taskdone = 0;
  Data_Transfer_Mutex = CreateMutex(NULL, FALSE, NULL);
  data_available = false;
}

RAS_Zynq_AD::~RAS_Zynq_AD() {
  if (task_buff_a) {
    free(task_buff_a);
    task_buff_a = NULL;
  }
  if (task_buff_b) {
    free(task_buff_b);
    task_buff_b = NULL;
  }
  if (HS_Buffer) {
    free(HS_Buffer);
    HS_Buffer = NULL;
  }
  if (Aux_Buffer) {
    free(Aux_Buffer);
    Aux_Buffer = NULL;
  }

  if (Aux_DataA) {
    free(Aux_DataA);
    Aux_DataA = NULL;
  }
  if (Aux_DataB) {
    free(Aux_DataB);
    Aux_DataB = NULL;
  }

  if (target) {
    free(target);
    target = NULL;
  }
  closesocket(connection_socket);
  WSACleanup();
}

int RAS_Zynq_AD::Configure_Task(uint64_t numpulses_in) {
  numpulses = numpulses_in;
  numbursts = (int)ceil(((float)numpulses) / MAX_PULSES_PER_PACKET);
  Send_Command(1, numbursts); // Allocate Buffers
  Send_Command(8, 0);         // Write Zeros to Buffers
  Allocate_Buffer();
  return 0;
}

int RAS_Zynq_AD::Start_Task() {
  burst_counter = 0;
  Send_Command(2, 0);
  unsigned int threadID;
  unsigned int threadID2;

  taskdone = 0;
  data_available = false;
  // Receive_Data((void*)this); Uncomment this line to debug in a blocking call.
  read_data_thread = (HANDLE)_beginthreadex(NULL, 0, &Receive_Data,
                                            (void *)this, 0, &threadID);
  return 0;
}

int RAS_Zynq_AD::Set_HS_Delay(uint8_t delay) {
  Send_Command(11, delay);
  return 0;
}

int RAS_Zynq_AD::Set_AUX_Delay(uint8_t delay) {
  Send_Command(12, delay);
  return 0;
}

int RAS_Zynq_AD::SetAutoTriggerMode(char mode) {
  Send_Command(7, mode);
  return 0;
}

int RAS_Zynq_AD::SetTestRampMode(char mode) {
  Send_Command(9, mode);
  return 0;
}

int RAS_Zynq_AD::Connect_to_Zynq() {
  WSADATA wsaData;
  int iResult;
  iResult = WSAStartup(MAKEWORD(2, 2), &wsaData);
  if (iResult != 0) {
    printf("WSAStartup failed with error: %d\n", iResult);
    return 1;
  }
  connection_socket = INVALID_SOCKET;
  connection_socket = socket(AF_INET, SOCK_STREAM, 0);
  double buflen = 2e9;
  int optret = setsockopt(connection_socket, SOL_SOCKET, SO_RCVBUF,
                          (const char *)(&buflen), sizeof(buflen));
  if (optret != 0) {
    printf("Buffer Adjust Failed!");
  }
  int option = 1;
  optret = setsockopt(connection_socket, SOL_SOCKET, SO_REUSEADDR,
                      (char *)&option, sizeof(option));
  if (optret != 0) {
    printf("setsocketopt failed!");
  }
  int ib = 1;
  optret = setsockopt(connection_socket, IPPROTO_TCP, TCP_NODELAY, (char *)&ib,
                      sizeof(ib));
  if (optret != 0) {
    printf("NODELAY Adjust Failed!");
  }
  if (connection_socket == INVALID_SOCKET) {
    printf("Error at socket(): %ld\n", WSAGetLastError());
    WSACleanup();
    return 1;
  }

  int result = connect(connection_socket, (SOCKADDR *)target, sizeof(*target));
  if (result == SOCKET_ERROR) {
    closesocket(connection_socket);
    connection_socket = INVALID_SOCKET;
  }
  return 0;
}

int RAS_Zynq_AD::Allocate_Buffer() {
  if (task_buff_a) {
    free(task_buff_a);
    task_buff_a = NULL;
  }
  task_buff_a = (char *)malloc(TOTAL_BYTES_PER_BURST * (uint64_t)numbursts);
  task_data = task_buff_a;
  if (HS_Buffer) {
    free(HS_Buffer);
    HS_Buffer = NULL;
  }
  HS_Buffer = (int16_t *)malloc(HS_BYTES_PER_BURST * (uint64_t)numbursts);

  if (Aux_Buffer) {
    free(Aux_Buffer);
    Aux_Buffer = NULL;
  }
  Aux_Buffer = (uint32_t *)malloc(AUX_BYTES_PER_BURST * (uint64_t)numbursts);
  if (Aux_DataA) {
    free(Aux_DataA);
    Aux_DataA = NULL;
  }
  Aux_DataA = (uint16_t *)malloc(AUX_BYTES_PER_BURST * (uint64_t)numbursts / 2);
  if (Aux_DataB) {
    free(Aux_DataB);
    Aux_DataB = NULL;
  }
  Aux_DataB = (uint16_t *)malloc(AUX_BYTES_PER_BURST * (uint64_t)numbursts / 2);

  return 0;
}

unsigned __stdcall Receive_Data_Continuous(void *pArguments) {
  RAS_Zynq_AD *Zynq = (RAS_Zynq_AD *)pArguments;
  unsigned long long bytes_received = 0;
  int bytes_last_transfer = 0;
  int error = 0;
  while (bytes_received < (unsigned long long)TOTAL_BYTES_PER_BURST *
                              (unsigned long long)Zynq->numbursts) {
    bytes_last_transfer =
        recv(Zynq->connection_socket, (char *)Zynq->task_data + bytes_received,
             (unsigned long long)TOTAL_BYTES_PER_BURST * Zynq->numbursts -
                 bytes_received,
             MSG_WAITALL);
    if (bytes_last_transfer < 0) {
      error = WSAGetLastError();
    } else {
      bytes_received += bytes_last_transfer;
      printf("received %d bytes \n", bytes_last_transfer);
    }
  }
  Zynq->Process_Buffer();
  return 0;
}

int RAS_Zynq_AD::Process_Buffer_Continuous() {
  while (~taskdone) {
    if (data_available) {
      memcpy(HS_Buffer, (void *)processing_pointer, HS_BYTES_PER_BURST);
      memcpy(Aux_Buffer, (void *)(processing_pointer), AUX_BYTES_PER_BURST);
      processing_pointer += TOTAL_BYTES_PER_BURST;
      data_available = false;
    }
  }
  Post_Process_AuxData();
  taskdone = 1;
  return 0;
}

unsigned __stdcall Receive_Data(void *pArguments) {
  RAS_Zynq_AD *Zynq = (RAS_Zynq_AD *)pArguments;
  unsigned long long bytes_received = 0;
  int bytes_last_transfer = 0;
  int error = 0;
  while (bytes_received < (unsigned long long)TOTAL_BYTES_PER_BURST *
                              (unsigned long long)Zynq->numbursts) {
    bytes_last_transfer =
        recv(Zynq->connection_socket, (char *)Zynq->task_data + bytes_received,
             (unsigned long long)TOTAL_BYTES_PER_BURST * Zynq->numbursts -
                 bytes_received,
             MSG_WAITALL);
    if (bytes_last_transfer < 0) {
      error = WSAGetLastError();
    } else {
      bytes_received += bytes_last_transfer;
      printf("received %d bytes \n", bytes_last_transfer);
    }
  }
  Zynq->Process_Buffer();
  return 0;
}

int RAS_Zynq_AD::Process_Buffer() {
  processing_pointer = task_buff_a;
  for (int ii = 0; ii < numbursts; ii++) {
    memcpy(HS_Buffer + (HS_BYTES_PER_BURST / 2) * ii,
           (void *)processing_pointer, HS_BYTES_PER_BURST);
    memcpy(Aux_Buffer + (AUX_BYTES_PER_BURST / 4) * ii,
           (void *)(processing_pointer + HS_BYTES_PER_BURST),
           AUX_BYTES_PER_BURST);
    processing_pointer += TOTAL_BYTES_PER_BURST;
  }
  Post_Process_AuxData();
  taskdone = 1;
  return 0;
}

int RAS_Zynq_AD::Post_Process_AuxData() {
  for (int i = 0;
       i < (MAX_PULSES_PER_PACKET * AUX_SAMPLES_PER_PULSE * numbursts); i++) {
    *(Aux_DataA + i) = (uint16_t)(*(Aux_Buffer + i) >> 18);
    *(Aux_DataB + i) = (uint16_t)((*(Aux_Buffer + i) >> 4) & 0x3FFF);
  }
  return 0;
}

int RAS_Zynq_AD::SetAmplifierGain(int8_t gain) {
  Send_Command(10, gain);
  return 0;
}

int RAS_Zynq_AD::Send_Command(char command, char argument) {
  Sleep(500);
  const char sendbuf[2] = {command, argument};
  int iResult;
  iResult = send(connection_socket, sendbuf, 2, 0);
  if (iResult == SOCKET_ERROR) {
    printf("send failed: %d\n", WSAGetLastError());
    closesocket(connection_socket);
    WSACleanup();
    return 1;
  }
  return 0;
}
