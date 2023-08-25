#pragma once
#include "DAQ_Utilities.h"
using namespace std;

class DAQ_Channel {
public:
  string Phys_Port;
  string Channel_Name;
  double min;
  double max;
  void *data;
};