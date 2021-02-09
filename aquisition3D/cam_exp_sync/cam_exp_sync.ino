// Arduino program to count number of exposure active pulses from camera and produce triggering pulses 

// Include the fast digital read/write library
#include "digitalWriteFast.h"

// Define Pins
// Inputs
const int switchPin = 2;

// Outputs
const int highPin = 4;
const int altGround = 12;
const int blinkPin = 13;
const int trigPin = 8;

// Switch tracker state variables
boolean currentSwitch = LOW;
boolean previousSwitch = LOW;

// Counter
int currentCount = 0;
const int countLimit = 14;


void setup() {
  // Input signals
  pinModeFast(switchPin, INPUT);

  // Output signals
  pinModeFast(highPin,OUTPUT);
  pinModeFast(altGround,OUTPUT);
  pinModeFast(blinkPin,OUTPUT);
  pinModeFast(trigPin,OUTPUT);

  // Set high pin to HIGH
  digitalWriteFast(highPin,HIGH);

  // Set extra ground pin to LOW
  digitalWriteFast(altGround,LOW);
}

void loop() {
  
  currentSwitch = digitalReadFast(switchPin);

  if (currentSwitch == HIGH) {
    if (previousSwitch == LOW) {
      // We have recieved an up edge, count it
      currentCount++;
    }
  }

  if (currentCount == countLimit) {
    
    // Trigger out
    digitalWriteFast(blinkPin,LOW);
    digitalWriteFast(trigPin,LOW);
    delayMicroseconds(1);
    digitalWriteFast(blinkPin,HIGH);
    digitalWriteFast(trigPin,HIGH);

    
    // Reset the count
    currentCount = 0;
    
  }
  
  
  // Remember this cycle's switch state
  previousSwitch = currentSwitch;

}
