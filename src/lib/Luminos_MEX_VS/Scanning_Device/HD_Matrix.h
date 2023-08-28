#pragma once
#include <iostream>
#include <stdlib.h>
#ifdef CONFOCAL_EXPORTS
#define LUMINOSCONFOCAL_API __declspec(dllexport)
#else
#define LUMINOSCONFOCAL_API __declspec(dllimport)
#endif

class LUMINOSCONFOCAL_API HD_Matrix {
public:
  HD_Matrix(unsigned rows, unsigned cols);
  HD_Matrix(unsigned rows, unsigned cols, double *data);
  HD_Matrix();
  ~HD_Matrix();
  int Copy_Scaled_Subarray(uint16_t *target, int col_offset, int row_offset,
                           int rows, int cols, double minval, double maxval);
  int Fill_Zeros();
  double &operator()(unsigned row, unsigned col);
  double operator()(unsigned row, unsigned col) const;
  int resize(unsigned rows, unsigned cols);
  double *data_;

private:
  unsigned rows_, cols_;
  bool owns_data;
};

inline HD_Matrix::HD_Matrix()
    : rows_(0), cols_(0), data_(NULL), owns_data(true) {}

inline HD_Matrix::HD_Matrix(unsigned rows, unsigned cols)
    : rows_(rows), cols_(cols) {
  if (rows == 0 || cols == 0)
    printf("HD_Matrix constructor has 0 size");
  data_ = (double *)malloc((double)rows * (double)cols * sizeof(double));
  owns_data = true;
}

inline HD_Matrix::HD_Matrix(unsigned rows, unsigned cols, double *data)
    : rows_(rows), cols_(cols), data_(data) {
  if (rows == 0 || cols == 0)
    printf("HD_Matrix constructor has 0 size");
  owns_data = false;
}

inline HD_Matrix::~HD_Matrix() {
  if (owns_data) {
    free(data_);
  }
}

inline int HD_Matrix::Fill_Zeros() {
  memset(data_, 0, rows_ * cols_ * sizeof(double));
  return 0;
}

inline double &HD_Matrix::operator()(unsigned row, unsigned col) {
  if (row >= rows_ || col >= cols_)
    printf("HD_Matrix subscript out of bounds");
  return data_[cols_ * row + col];
}

inline double HD_Matrix::operator()(unsigned row, unsigned col) const {
  if (row >= rows_ || col >= cols_)
    printf("const HD_Matrix subscript out of bounds");
  return data_[cols_ * row + col];
}

inline int HD_Matrix::resize(unsigned rows, unsigned cols) {
  if ((rows != rows_) || (cols != cols_)) {
    double *tmp =
        (double *)malloc((double)rows * (double)cols * sizeof(double));
    free(data_);
    data_ = tmp;
    rows_ = rows;
    cols_ = cols;
  }
  Fill_Zeros();
  return 0;
}

inline int HD_Matrix::Copy_Scaled_Subarray(uint16_t *target, int col_offset,
                                           int row_offset, int rows, int cols,
                                           double minval, double maxval) {
  int k = 0;
  for (int i = row_offset; i < rows; i++) {
    for (int j = col_offset; j < cols; j++) {
      *(target + k) = (uint16_t)round((data_[cols_ * i + j] - minval) /
                                      (maxval - minval) * 65535);
      k++;
    }
  }
  return 0;
}
