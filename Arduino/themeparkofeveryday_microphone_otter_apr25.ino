/* 
  Microphone Blow Otter Example
  April 25 2015
  Theme Park of Everyday
  http://www.themeparkofeveryday.com
  
  In this example, you can blow into the microphone in your device 
  to make the otter hide or pop out of the grass.
  
  ///////////////////////////////////////////////////////
  Expected Values from Pocket Park for Microphone
  NOTE: Values differ between devices
  
  Range between 0 and 300
  
  It requires significant blowing to get to 300, you're more likely
  to see values maxing out around 150.
  
  Experiment by mapping and constraining the value.
  int mappedValue = map(scratchNumber, 0, 150, 0, 180);
  int constrainedValue = constrain(mappedValue, 0, 180);
 
  ///////////////////////////////////////////////////////

  Tom Arthur
  NYU ITP
  
  This project is enabled by the LightBlue Bean.
  https://punchthrough.com/bean/
 */
 

#include <Servo.h>
#define OTTER_SERVO_PIN 0

Servo otterServo;

///////////////////////////////////////////////////////
// Required variables for Theme Park of Everyday Installations

// Store values received by phone
long scratchNumber = 0;   
long lastScratchNumber = 0;

// Track BLE connection
bool connected;

///////////////////////////////////////////////////////

void setup() { 
  Serial.begin(57600);
  
  // Only wakeup Arduino if a device is connected. This saves battery life.
  Bean.enableWakeOnConnect(true);   
}

void loop() {
  // Check to see if the LightBlue Bean is connected to a device
  connected = Bean.getConnectionState();  
  
  // Only enable the Installation if connected
  if (connected)                          
  {
    // Set the LightBlue Bean LED to Green so you know PocketPark has connected.
    Bean.setLed(0, 255, 0);
    
    // Read the scratch number. This is how a user's device talks to your Installation.
    scratchNumber = Bean.readScratchNumber(1);
    
    if (scratchNumber != lastScratchNumber) {
      // TROUBLESHOOTING: show that data has come in from the user device
      Bean.setLed(0, 0, 255);
    
      otterServo.attach(OTTER_SERVO_PIN);
      otterServo.write(scratchNumber);
      lastScratchNumber = scratchNumber;
    }
    
    Bean.sleep(50);
  }
  // when disconnected from the device, turn the installation off.
  else {    
    
    // reset the location of the servo
    otterServo.write(150);
    delay(1000);
    otterServo.detach();

    resetInstallation();
  }
}

///////////////////////////////////////////////////////
// Required functions for Theme Park of Everyday Installations

void resetInstallation() {
    // Reset the scratch number, prevents unexpected behavior on the next connection
    Bean.setScratchNumber(1, 0);
    // Turn the LightBlue Bean LED off so you know PocketPark has disconnected
    Bean.setLed(0, 0, 0);
    Bean.sleep(0xFFFFFFFF);
}

///////////////////////////////////////////////////////
