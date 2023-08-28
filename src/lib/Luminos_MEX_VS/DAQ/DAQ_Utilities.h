#pragma once

#include <string>

class DAQ_Callback {
public:
  void (*CallbackFcn)(void *);
  void *argpointer;
};

#ifndef _NI_int8_DEFINED_
#define _NI_int8_DEFINED_
typedef signed char int8;
#endif
#ifndef _NI_uInt8_DEFINED_
#define _NI_uInt8_DEFINED_
typedef unsigned char uInt8;
#endif
#ifndef _NI_int16_DEFINED_
#define _NI_int16_DEFINED_
typedef signed short int16;
#endif
#ifndef _NI_uInt16_DEFINED_
#define _NI_uInt16_DEFINED_
typedef unsigned short uInt16;
#endif
#ifndef _NI_int32_DEFINED_
#define _NI_int32_DEFINED_
#if ((defined(__GNUG__) || defined(__GNUC__)) && defined(__x86_64__))
typedef signed int int32;
#else
typedef signed long int32;
#endif
#endif
#ifndef _NI_uInt32_DEFINED_
#define _NI_uInt32_DEFINED_
#if ((defined(__GNUG__) || defined(__GNUC__)) && defined(__x86_64__))
typedef unsigned int uInt32;
#else
typedef unsigned long uInt32;
#endif
#endif
#ifndef _NI_float32_DEFINED_
#define _NI_float32_DEFINED_
typedef float float32;
#endif
#ifndef _NI_float64_DEFINED_
#define _NI_float64_DEFINED_
typedef double float64;
#endif
#ifndef _NI_int64_DEFINED_
#define _NI_int64_DEFINED_
#if defined(__linux__) || defined(__APPLE__)
typedef long long int int64;
#else
typedef __int64 int64;
#endif
#endif
#ifndef _NI_uInt64_DEFINED_
#define _NI_uInt64_DEFINED_
#if defined(__linux__) || defined(__APPLE__)
typedef unsigned long long uInt64;
#else
typedef unsigned __int64 uInt64;
#endif
#endif
