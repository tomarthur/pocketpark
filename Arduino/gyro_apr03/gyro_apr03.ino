/* 
  Theme Park of Everyday
  http://www.themeparkofeveryday.com
  iOS Device Gyro Example 1.0
  
  This project is enabled by the LightBlue Bean.
  https://punchthrough.com/bean/
  
  Use data from the gyro on a user's device 
  to activate a servo which makes an otter pop 
  out of the grass.
  
  Tom Arthur
  NYU ITP
  
  Contains code adapted from:
  'Facebook Flagger' (Bean Notifications)
  Release r1-0
  by Colin Karpfinger, Punch Through Design LLC
  Released under MIT license. See LICENSE for details.
 */

#include <Servo.h>
#define OTTER_SERVO_PIN 0

Servo otterServo;

///////////////////////////////////////////////////////
// Required variables for Theme Park of Everyday Installations

// Store values recieved by phone
long scratchNumber = 0;   
long lastScratchNumber = 0;

// Track BLE connection
bool connected;

///////////////////////////////////////////////////////

void setup() 
{
  Serial.begin(57600);

  // Only wakeup Arduino if a device is connected. This saves battery life.
  Bean.enableWakeOnConnect(true);   
}

void loop() 
{ 
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
      // Connect to the servo and change it's location
      otterServo.attach(OTTER_SERVO_PIN);
      otterServo.write(scratchNumber);
      lastScratchNumber = scratchNumber;
//      otterServo.detach();
    }
    
    // Bean sleep functions often prevent unexpected behavior
    Bean.sleep(50);
  } 
  else {    // when disconnected from phone, reset the device

    // Return the otter to the grass before turning Installation off
    Bean.setScratchNumber(1, 150);
    otterServo.attach(OTTER_SERVO_PIN);
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


