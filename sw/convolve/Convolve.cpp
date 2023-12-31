// Greg Stitt
// University of Florida

#include <cassert>
#include <iostream>

#include "Convolve.h"
#include "Timer.h"

using namespace std;

Kernel::Kernel(const appWord_t *kernel, unsigned int size) {
  
  allocated = false;

  if (size > Convolve::MAX_KERNEL_SIZE) {
      cerr << "Current FPGA implemenetation doesn't support kernels larger than " << Convolve::MAX_KERNEL_SIZE << endl;
      throw KernelSizeException();
  }
  
  // kernel transferred to the FPGA needs to be 32 bits
  this->kernel = new unsigned int [Convolve::MAX_KERNEL_SIZE];
  this->size = Convolve::MAX_KERNEL_SIZE;

  for (unsigned i=0, j=0; i < Convolve::MAX_KERNEL_SIZE; i++) {

      if (i < size) {
          
          this->kernel[i] = kernel[j++];
      }
      else {

          this->kernel[i] = 0;
      }      
  }
  
  allocated = true;  
}

Kernel::~Kernel() {

  if (allocated)
     delete[] kernel;
}

unsigned int Kernel::getSize() const {
  return size;
}

unsigned int *Kernel::getKernel() const {
  return kernel;
}

ostream & operator<<(ostream& stream, const Kernel &k) {
  
  for (unsigned i=0; i < k.getSize(); i++) {   
    stream << k.kernel[i] << " ";
  }
  return stream;
}


Signal::Signal(const appWord_t *signal, unsigned int size) {

  this->unpaddedSize = size;
  this->size = size+2*(Convolve::MAX_KERNEL_SIZE-1);
  this->signal = new appWord_t [this->size];

  // pad the original signal based on the maximum kernel size that can
  // be handled by the FPGA
  
  for (unsigned i=0,j=0; i < this->size; i++) {
      
      if (i < Convolve::MAX_KERNEL_SIZE-1 || i >= size+Convolve::MAX_KERNEL_SIZE-1) {
          this->signal[i] = 0;
      }
      else {
          this->signal[i] = signal[j++];
      }      
  }
  
  allocated = true;  
}

Signal::~Signal() {

  if (allocated)
     delete signal;
}

unsigned int Signal::getSize() const {
  return size;
}

unsigned int Signal::getUnpaddedSize() const {
  return unpaddedSize;
}

appWord_t *Signal::getSignal() const {
  return signal;
}

ostream & operator<<(ostream& stream, const Signal &s) {
  
  for (unsigned i=0; i < s.getSize(); i++) {   
    stream << s.signal[i] << " ";
  }
  return stream;
}


Convolve::Convolve(Board &board) : App(board) {
  
}

Convolve::~Convolve() {
  
}

void Convolve::start(const appWord_t *signal, unsigned int signalSize, 
                     const appWord_t *kernel, unsigned int kernelSize) {

  assert(signal != NULL);
  assert(kernel != NULL);

  Signal paddedSignal(signal, signalSize);
  Kernel paddedKernel(kernel, kernelSize);

//  cout << "Signal = " << paddedSignal << endl;
//  cout << "Kernel = " << paddedKernel << endl;

  start(paddedSignal, paddedKernel);
}


void Convolve::getOutput(appWord_t *output, unsigned int outputSize) {
  
  assert(output != NULL);

  write(0, MODE_ADDR);
  read(output, 0, outputSize);
}


void Convolve::waitUntilDone(float timeout) {

  Timer waitTime;
  unsigned value = 0;

  write(1, MODE_ADDR);

  waitTime.start();
  while (!value && waitTime.elapsedTime() < timeout) {
    this->read(&value, DONE_ADDR, 1);
  }
  waitTime.stop();

  if (value == 0) {
    throw TimeoutException();
  }
}

bool Convolve::isDone() {
  
  bool done;
  write(1, MODE_ADDR);
  read(done, DONE_ADDR);
  return done;
}


void Convolve::start(Signal &signal, Kernel &kernel) {

  // Disable user mode
  write(0, MODE_ADDR);

  // Send signal to input RAM
  write(signal.getSignal(), 0, signal.getSize());
  
  // Enable user mode
  write(1, MODE_ADDR);

  // Clear the buffers (this signal is self-clearing in the FPGA)
  write(1, CLEAR_ADDR);

  // Send the unpadded signal size
  write(signal.getUnpaddedSize(), SIGNAL_SIZE_ADDR);
  /* unsigned int size;
     read(size, SIGNAL_SIZE_ADDR);
     assert(signal.getUnpaddedSize() == size);*/

  // Send the kernel
  for (unsigned i=0; i < kernel.getSize(); i++) {
    write(kernel.getKernel()[i], KERNEL_DATA_ADDR);
    /*unsigned temp;
      read(temp, KERNEL_DATA_ADDR);
      assert(temp == kernel.getKernel()[i]);*/
  }
  
  /*unsigned loaded;
  read(loaded, KERNEL_LOADED_ADDR);
  assert(loaded == 1); */

  write(1, GO_ADDR); 
}

