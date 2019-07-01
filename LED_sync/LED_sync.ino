/* 
  Camera double exposure, dual-LED, and fixation target synchronizer v1.0
  For 2-LED retroillumination project
  Timothy D. Weber, BU Biomicroscopy Lab, 2019

 */

// Include the fast digital read/write library
#include "digitalWriteFast.h"

// Set exposure time (time for LEDs to be on)
const int exposureTimeUs = 2000;
const int E1 = exposureTimeUs - 89;
const int E2 = 1000/(11*2); // this is 1000 ms divided by framerate divided by 2, for fixation target exposure time time

// set up some digital state variables
boolean currentBusySignal = false;
boolean previousBusySignal  = false;

// set up constant parameters
const int busySignalPin = 0; // Camera's "busy" signal
const int LED1Pin = 1; 
const int LED2Pin = 2;
const int fixPin = 3;

void setup() {
  // initialize input/output pins:
  pinModeFast(busySignalPin, INPUT);

  pinModeFast(LED1Pin, OUTPUT);
  pinModeFast(LED2Pin, OUTPUT);

}

void loop() {
  // Continuously poll the state of exposure signal (read and compare takes ~250 ns)
  currentBusySignal = digitalReadFast(busySignalPin);
  
  if (currentBusySignal == HIGH) {

    if (previousBusySignal == LOW) {
      // Busy signal is high and last cycle was low => UP edge
      // Start the LED exposure sequence
  
      // Start LED 1 ASAP--no delay
      
      // Turn LED 1 on
      digitalWriteFast(LED1Pin,HIGH);
      
      // Some delay for proper exposure time
      delayMicroseconds(exposureTimeUs);
  
      // Turn LED 1 off
      digitalWriteFast(LED1Pin,LOW);

      // Some very short delay
      delayMicroseconds(72);
      
      // Turn LED 2 on
      digitalWriteFast(LED2Pin,HIGH);

      // Some delay
      delayMicroseconds(E1);
  
      // Turn LED 2 off
      digitalWriteFast(LED1Pin,LOW);

      // Some delay
      delayMicroseconds(100);

      // Turn fixation target on
      digitalWriteFast(fixPin,HIGH);

      // Calculated delay
      delay(E2);
      
      // Turn fixation target off
      digitalWriteFast(fixPin,LOW);

    }
    
  }

  // Record this cycle's busy signal state
  previousBusySignal = currentBusySignal;
  
}
