#pragma once
//CamFrame class holds frame data along with ROI metadata.
typedef long int32;
typedef unsigned long _ui32;
class CamFrame {
public:
  int32 iFrame;
  void *buf;
  int32 width;  // [i:o] horizontal pixel count
  int32 height; // [i:o] vertical line count
  int32 left;   // [i:o] horizontal start pixel
  int32 top;
};
