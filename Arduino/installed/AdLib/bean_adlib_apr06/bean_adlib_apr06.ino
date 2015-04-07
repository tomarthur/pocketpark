// Wire Slave Sender
// by Nicholas Zambetti <http://www.zambetti.com>

// Demonstrates use of the Wire library
// Sends data as an I2C/TWI slave device
// Refer to the "Wire Master Reader" example for use with this

// Created 29 March 2006

// This example code is in the public domain.


#include <Wire.h>

// track BLE connection for when to activate effect
bool connected;

// store values recieved by phone
long scratchNumber = 0;   
long lastScratchNumber = 0;

void setup() 
{
  Serial.begin(57600);
  Wire.begin();                // join i2c bus with address #2

  Bean.enableWakeOnConnect(true);    // only wakeup arduino if phone is connected
}

void loop()
{
  
  connected = Bean.getConnectionState();
  
  if (connected) {
    Bean.setLed(0, 255, 0);
    scratchNumber = Bean.readScratchNumber(1);
    
    if (scratchNumber != lastScratchNumber) {
       if (scratchNumber != 0) {
          Wire.beginTransmission(4); // transmit to device #4
          Wire.write("G");              // sends one byte  
          Wire.endTransmission();    // stop transmitting
      }
    }
  }
  else {
    Bean.setScratchNumber(1, 0);
    Wire.beginTransmission(4); // transmit to device #4
    Wire.write("E");              // sends one byte  
    Wire.endTransmission();    // stop transmitting
    Bean.setLed(0, 0, 0);
    Bean.sleep(0xFFFFFFFF);
  }
  
}

