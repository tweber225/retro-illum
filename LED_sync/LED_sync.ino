/* 
  Camera double exposure, dual-LED, and fixation target synchronizer v1.0
  For 2-LED retroillumination project
  Timothy D. Weber, BU Biomicroscopy Lab, 2019

 */

// Include the fast digital read/write library
#include "digitalWriteFast.h"

// Set exposure time (time for LEDs to be on)
const int exposureTimeUs = 2000;

// Set empirical values
const int fallTimeUs = 80;
const int interFrameTimeUs = 1;
const int readTimeMs = 74;

// Calculate some delay times
const int E1 = exposureTimeUs - fallTimeUs; // in us
const int E2 = fallTimeUs + interFrameTimeUs; // in us
const int E3 = readTimeMs - E1/1000 + 1; // in ms
const int E4 = E3 - 10; // in ms

// set up constant parameters
const int exposureSignalPin = 0; // Camera's "busy" signal
const int LED1Pin = 1; 
const int LED2Pin = 2;
const int fixPin = 3;



void setup() {
  
  // initialize input/output pins:
  pinModeFast(exposureSignalPin, INPUT);
  pinModeFast(LED1Pin, OUTPUT);
  pinModeFast(LED2Pin, OUTPUT);

}

void loop() {
  // Continuously poll the state of exposure signal (read and compare takes ~250 ns)

  if digitalReadFast(exposureSignalPin) {
    // Start the LED exposure sequence

    // Start LED 1 ASAP--no delay
    digitalWriteFast(LED1Pin,HIGH);
    
    // Some delay for proper exposure time
    delayMicroseconds(E1);

    // Turn LED 1 off
    digitalWriteFast(LED1Pin,LOW);

    // Some very short delay
    delayMicroseconds(E2);
    
    // Turn LED 2 on
    digitalWriteFast(LED2Pin,HIGH);

    // Some delay
    delayMicroseconds(E1);

    // Turn LED 2 off
    digitalWriteFast(LED1Pin,LOW);

    // Some delay for the second exposure to complete
    // 2nd exposure = read time (fixed)
    delay(E3);

    // Turn fixation target on
    digitalWriteFast(fixPin,HIGH);

    // Calculated delay
    delay(E4);
    
    // Turn fixation target off
    digitalWriteFast(fixPin,LOW);

  }

  // Return to continuous polling of exposure signal & wait for next sequence
  
}
