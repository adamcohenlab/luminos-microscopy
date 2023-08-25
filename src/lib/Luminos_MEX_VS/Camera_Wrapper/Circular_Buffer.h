#pragma once
#include <cstdio>
#include <memory>
#include <mutex>
/* This header implements a FIFO ircular Buffer template class. The circular buffer is initialized with a single size argument.
It exposes a put, get, reset interface along with methods to check for full and empty status and to return the current filled size and the total theoretical capacity.*/

template <class T> class Circular_Buffer {
public:
    //New Circular_Buffer to hold <size> elements of type <T>
  explicit Circular_Buffer(size_t size)
      : buf_(std::unique_ptr<T[]>(new T[size])), max_size_(size) {}

  //Put new item of type <T> at next position in buffer (head), circling back to start when full.
  void put(T item) {
    std::lock_guard<std::mutex> lock(mutex_);

    buf_[head_] = item;

    if (full_) {
      tail_ = (tail_ + 1) % max_size_;
    }

    head_ = (head_ + 1) % max_size_;

    full_ = head_ == tail_;
  }

  // Get oldest item from Circular Buffer, removing it from the buffer
  T get() {
    std::lock_guard<std::mutex> lock(mutex_);

    if (empty()) {
      return T();
    }

    // Read data and advance the tail (we now have a free space)
    auto val = buf_[tail_];
    full_ = false;
    tail_ = (tail_ + 1) % max_size_;

    return val;
  }

  //Clear buffer. Results in empty buffer, as after initialization (data is NOT overwritten with 0s)
  void reset() {
    std::lock_guard<std::mutex> lock(mutex_);
    head_ = tail_;
    full_ = false;
  }

  //Is buffer empty?
  bool empty() const {
    // if head and tail are equal, we are empty
    return (!full_ && (head_ == tail_));
  }

  //Is buffer full? (next put will overwrite oldest value).
  bool full() const {
    // If tail is ahead the head by 1, we are full
    return full_;
  }

  //How many elements of type <T> can buffer hold?
  size_t capacity() const { return max_size_; }

  //How many elements of type <T> are currently in the buffer (==capacity iff buffer is full)
  size_t size() const {
    size_t size = max_size_;

    if (!full_) {
      if (head_ >= tail_) {
        size = head_ - tail_;
      } else {
        size = max_size_ + head_ - tail_;
      }
    }

    return size;
  }

private:
  std::mutex mutex_;
  std::unique_ptr<T[]> buf_;
  size_t head_ = 0;
  size_t tail_ = 0;
  const size_t max_size_;
  bool full_ = 0;
};