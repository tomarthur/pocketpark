/* 
  Shake Example
  Theme Park of Everyday
  http://www.themeparkofeveryday.com
  
  This project is enabled by the LightBlue Bean.
  https://punchthrough.com/bean/
  

  
  Tom Arthur
  NYU ITP
  
   Contains code adapted from:
     'Facebook Flagger' (Bean Notifications)
     Release r1-0
     by Colin Karpfinger, Punch Through Design LLC
     Released under MIT license.
   
   and
   
     enableWakeOnConnect() function example.
     This example code is in the public domain.
 
 */


#include <Servo.h>
#define OTTER_SERVO_PIN 0

Servo otterServo;
boolean visableOtter = false;

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

  // Only wakeup Arduino if a user device is connected. This saves battery life.
  Bean.enableWakeOnConnect(true);
}

void loop() 
{ 
  // Check to see if the LightBlue Bean is connected to a user device
  connected = Bean.getConnectionState();

  if (connected)
  {
    // Set the LightBlue Bean LED to Green so you know PocketPark has connected.
    
    // Read the scratch number. This is how a user's device talks to your Installation.
    scratchNumber = Bean.readScratchNumber(1);

    // for this example, the expected values are between 0 and 180 which match the servo
    // there is no need to constrain or map values in this case
    
    if (scratchNumber != lastScratchNumber) {
//      otterServo.attach(OTTER_SERVO_PIN);
      
      if (scratchNumber != 0) {
        Bean.setLed(0, 255, 0);
        visableOtter = !visableOtter;
      } else {
        Bean.setLed(255, 0, 0);
      }
      
      if (visableOtter == true) {
        Bean.setLed(255, 0, 0);
        otterServo.write(0);
      } else {
        Bean.setLed(0, 0, 255);
        otterServo.write(180);
      }
 
      
      lastScratchNumber = scratchNumber;
    }

    Bean.sleep(50);

  } 
  // when disconnected from the user device, turn the installation off.
  else {

    // reset the location of the servo
    otterServo.write(180);
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



