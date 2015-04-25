/*
  Theme Park of Everyday
  http://www.themeparkofeveryday.com
  Controll Pinwheels with the Microphone

  This project is enabled by the LightBlue Bean.
  https://punchthrough.com/bean/

  Use data from the microphone on a user's device
  to activate a relay which switches on a bubble machine.

  Tom Arthur
  NYU ITP
 */


#include <Servo.h>

Servo bigWheel;  // create servo object to control a servo
Servo smallWheel0;
Servo smallWheel1;

// store values recieved by phone
long scratchNumber = 0;
long lastScratchNumber = -1;

// track BLE connection for when to activate effect
bool connected;

void setup() {
  Serial.begin(57600);

  bigWheel.attach(0);     // attaches the servo on pin 0 to the servo object
  smallWheel0.attach(3);  // attaches the servo on pin 3 to the servo object
  smallWheel1.attach(2);  // attaches the servo on pin 2 to the servo object

  Bean.enableWakeOnConnect(true);    // only wakeup arduino if phone is connected
}

void loop() {
  connected = Bean.getConnectionState();
  if (connected)
  {
    scratchNumber = Bean.readScratchNumber(1);
    Bean.setLed(0, 255, 0);

    if (scratchNumber != lastScratchNumber) {
      lastScratchNumber = scratchNumber;
      //      int constrainedVal = constrain(scratchNumber, 0, 25);
      int mappedValue = map(scratchNumber, 0, 25, 90, 180);

      bigWheel.write(mappedValue / 2);
      smallWheel0.write(mappedValue-2);
      smallWheel1.write(mappedValue-2);

      lastScratchNumber = scratchNumber;

    }

  }
  else {    // when disconnected from phone, reset the device
    bigWheel.detach();
    smallWheel0.detach();
    smallWheel1.detach();
    Bean.setLed(0, 0, 0);
    Bean.sleep(0xFFFFFFFF);
  }
}


