#pragma once
#ifndef __CLASS_HANDLE_H__
#define __CLASS_HANDLE_H__
#include "mex.hpp"
#include "mexAdapter.hpp"
#include <stdint.h>
#include <string>
#include <cstring>
#include <typeinfo>

#define CLASS_HANDLE_SIGNATURE 0xFF00F0A5

using namespace matlab::mex;
using matlab::mex::ArgumentList;

template <class base> class class_handle {
public:
  class_handle(base *ptr)
      : signature_m(CLASS_HANDLE_SIGNATURE), name_m(typeid(base).name()),
        ptr_m(ptr) {}
  ~class_handle() {
    signature_m = 0;
    delete ptr_m;
  }
  bool isValid() {
    return ((signature_m == CLASS_HANDLE_SIGNATURE) &&
            !strcmp(name_m.c_str(), typeid(base).name()));
  }
  base *ptr() { return ptr_m; }

private:
  uint32_t signature_m;
  const std::string name_m;
  base *const ptr_m;
};

template <class base> inline uint64_t convertPtr2Mat(base *ptr) {
  return reinterpret_cast<uint64_t>(new class_handle<base>(ptr));
}

template <class base>
inline class_handle<base> *convertMat2HandlePtr(uint64_t in) {
  class_handle<base> *ptr = reinterpret_cast<class_handle<base> *>(in);
  return ptr;
}

template <class base> inline base *convertMat2Ptr(uint64_t in) {
  return convertMat2HandlePtr<base>(in)->ptr();
}

template <class base> inline void destroyObject(uint64_t in) {
  delete convertMat2HandlePtr<base>(in);
}

#endif // __CLASS_HANDLE_HPP__
