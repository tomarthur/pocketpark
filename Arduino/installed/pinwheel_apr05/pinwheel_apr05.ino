/* 
  Theme Park of Everyday
  http://www.themeparkofeveryday.com
  Pinwheel Installation
  
  This project is enabled by the LightBlue Bean.
  https://punchthrough.com/bean/
  
  Use data from the microphone on a user's device 
  to activate a relay which switches on a bubble machine.
  
  Tom Arthur
  NYU ITP
 */
#include <AccelStepper.h>

#define STEP_PIN 0
int value = 0;
//#define SLEEP_PIN 5
#define DIRECTION_PIN 1
//boolean sequenceStarted = false;
//
//AccelStepper stepper(1, STEP_PIN, DIRECTION_PIN); // Defaults to AccelStepper::FULL4WIRE (4 pins) on 2, 3, 4, 5

///////////////////////////////////////////////////////
// Required variables for Theme Park of Everyday Installations

// Store values recieved by phone
long scratchNumber = 0;   
long lastScratchNumber = 0;

// Track BLE connection
bool connected;

///////////////////////////////////////////////////////

void setup() { 
  Serial.begin(57600);
  
  pinMode(STEP_PIN, OUTPUT);
//  pinMode(SLEEP_PIN, OUTPUT);
  pinMode(DIRECTION_PIN, OUTPUT);
//  digitalWrite(SLEEP_PIN, HIGH);

  
  // Only wakeup Arduino if a device is connected. This saves battery life.
  Bean.enableWakeOnConnect(true);   
}

void loop() {
//  // Check to see if the LightBlue Bean is connected to a device

  connected = Bean.getConnectionState();

  
  // Only enable the Installation if connected
  if (connected)                          
  {
    pinMode(DIRECTION_PIN, HIGH);
    analogWrite(STEP_PIN, value);
    Bean.setLed(0, 255, 0);
    if (value < 255) {
      value++;
      delay(100);
    }  else {
      value = 0;
    }
 
  }
  // when disconnected from the device, turn the installation off.
  else {    


    
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


/////////////////////////////////////////////////////////
//// Basic Framework without Example
//// Delete everything above this line and uncomment to start fresh.
/////////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////////
//// Required for Theme Park of Everyday Installations
//
//// Store values recieved by phone
//long scratchNumber = 0;   
//long lastScratchNumber = 0;
//
//// Track BLE connection
//bool connected;
//
/////////////////////////////////////////////////////////
//
//void setup() { 
//  Serial.begin(57600);
//  
//  // Only wakeup Arduino if a device is connected. This saves battery life.
//  Bean.enableWakeOnConnect(true);   
//}
//
//void loop() {
//  // Check to see if the LightBlue Bean is connected to a device
//  connected = Bean.getConnectionState();  
//  
//  // Only enable the Installation if connected
//  if (connected)                          
//  {
//    // Set the LightBlue Bean LED to Green so you know PocketPark has connected
//    Bean.setLed(0, 255, 0);
//    // Read the scratch number. This is how a user's device talks to your Installation.
//    scratchNumber = Bean.readScratchNumber(1);    
//    
//    if (scratchNumber != lastScratchNumber) {
//      
//      // do something here based on the range of values
//      lastScratchNumber = scratchNumber;
//    }
//    
//  }
//  // when disconnected from the device, turn the installation off.
//  else {    
//    
//    // turn your installation off here
//    
//    resetInstallation();
//  }
//}
//
/////////////////////////////////////////////////////////
//// Required functions for Theme Park of Everyday Installations
//
//void resetInstallation() {
//    // Reset the scratch number, prevents unexpected behavior on the next connection
//    Bean.setScratchNumber(1, 0);
//    // Turn the LightBlue Bean LED off so you know PocketPark has disconnected
//    Bean.setLed(0, 0, 0);
//    Bean.sleep(0xFFFFFFFF);
//}
/////////////////////////////////////////////////////////
