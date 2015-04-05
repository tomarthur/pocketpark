/* 
  Theme Park of Everyday
  http://www.themeparkofeveryday.com
  iOS Device Shake Example 1.0
  
  This project is enabled by the LightBlue Bean.
  https://punchthrough.com/bean/
  
  Use shake detection on a user's device to change
  the color on a lantern.
  
  Tom Arthur
  NYU ITP

  Contains code adapted from:
	  BlinkColorList
	  2008, Tod E. Kurt, ThingM, http://thingm.com/
 */

#include "Wire.h"
#include "BlinkM_funcs.h"

// blinkM settings
#define blinkm_addr 0x00

int num_colors = 7;  // how many colors are there the list below

byte color_list[][3] = {
  { 0xff, 0xff, 0xff }, // white
  { 0xff, 0x00, 0xff }, // purple
  { 0xff, 0xff, 0x00 }, // orange
  { 0x00, 0xff, 0xff }, // cyan
  { 0xff, 0x00, 0x00 }, // red
  { 0xff, 0x00, 0x00 }, // red
  { 0xff, 0x00, 0x00 }, // red
};

int i = 0;
byte r,g,b; 

///////////////////////////////////////////////////////
// Required for Theme Park of Everyday Installations

// Store values recieved by phone
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
   // Set the LightBlue Bean LED to Green so you know PocketPark has connected
   Bean.setLed(0, 255, 0);
   // Read the scratch number. This is how a user's device talks to your Installation.
   scratchNumber = Bean.readScratchNumber(1);    
   
   if (scratchNumber != lastScratchNumber) {
     if (scratchNumber == 1){
     	mode
     }
     // do something here based on the range of values
     lastScratchNumber = scratchNumber;
   }
   
 }
 // when disconnected from the device, turn the installation off.
 else {    
   
   // turn your installation off here
   
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


//
//
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
