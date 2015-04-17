/* 
  Theme Park of Everyday
  http://www.themeparkofeveryday.com
  iOS Device Microphone Example 1.0
  
  This project is enabled by the LightBlue Bean.
  https://punchthrough.com/bean/
  
  Use data from the microphone on a user's device 
  to activate a relay which switches on a bubble machine.
  
  Tom Arthur
  NYU ITP
 */
 
#define RELAY_PIN 1
#define BAT_PIN 0


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
  
  pinMode(RELAY_PIN, OUTPUT);
  pinMode(BAT_PIN, OUTPUT);
  
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
    digitalWrite(BAT_PIN, HIGH);
    // Read the scratch number. This is how a user's device talks to your Installation.
    scratchNumber = Bean.readScratchNumber(1);
    
    if (scratchNumber > 20) {
      // Turn bubble machine on
      digitalWrite(RELAY_PIN, LOW);
    } 
    else {
      // Turn bubble machine off
      digitalWrite(RELAY_PIN, HIGH);  
    }

  }
  // when disconnected from the device, turn the installation off.
  else {    
    
    digitalWrite(BAT_PIN, LOW);
    digitalWrite(RELAY_PIN, HIGH);
    
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

