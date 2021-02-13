// Arduino program to count number of exposure active pulses from camera and produce triggering pulses 

// Include the fast digital read/write library
#include "digitalWriteFast.h"

// Define Pins
// Inputs
const int switchPin = 2;

// Outputs
const int highPin = 4;
const int extraGround1 = 12;
const int extraGround2 = 13;
const int LEDPin = 6;
const int trigPin = 8;

// Switch tracker state variables
boolean currentSwitch = LOW;
boolean previousSwitch = LOW;

// Counter
int currentCount = 0;
const int countLimit = 16; // i.e. number of frames per volume


void setup() {
  // Input signals
  pinModeFast(switchPin, INPUT);

  // Output signals
  pinModeFast(highPin,OUTPUT);
  pinModeFast(extraGround1,OUTPUT);
  pinModeFast(extraGround2,OUTPUT);
  pinModeFast(LEDPin,OUTPUT);
  pinModeFast(trigPin,OUTPUT);

  // Set high pin to HIGH
  digitalWriteFast(highPin,HIGH);

  // Set extra ground pins to LOW
  digitalWriteFast(extraGround1,LOW);
  digitalWriteFast(extraGround2,LOW);

  // Turn on LED
  digitalWriteFast(LEDPin,HIGH);
}

void loop() {
  
  currentSwitch = digitalReadFast(switchPin);

  if (currentSwitch == LOW) {
    if (previousSwitch == HIGH) {
      // We have recieved a down edge, count it
      currentCount++;
    }
  }

  if (currentCount == 1) {

    // Switch the LED back on
    digitalWriteFast(LEDPin,HIGH);
    
  }
  
  if (currentCount == countLimit) {

    // Turn off LED (until next down edge is detected
    digitalWriteFast(LEDPin,LOW);
    
    // Trigger out
    digitalWriteFast(trigPin,LOW);
    delayMicroseconds(1); // amazingly 1 us seems to be enough to reliably trigger the "Koolerton" function generator
    digitalWriteFast(trigPin,HIGH);
    
    // Reset the count
    currentCount = 0;
    
  }
  
  
  // Remember this cycle's switch state
  previousSwitch = currentSwitch;

}
