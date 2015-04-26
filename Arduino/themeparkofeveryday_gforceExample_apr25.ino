/* 
  GForce Example
  April 25 2015
  Theme Park of Everyday
  http://www.themeparkofeveryday.com
  
  ///////////////////////////////////////////////////////
  Expected Values from Pocket Park for GForce
  NOTE: This is an experimental input.
 
  Range between 0 and 200.
  
  It requires signifigant force to get to 200, you're more likely
  to see values maxing out around 50 to 70.
  
  Experiment by mapping and constraining the value.
  int mappedValue = map(scratchNumber, 0, 100, 0, 180);
  int constrainedValue = constrain(mappedValue, 0, 180);
  
  ///////////////////////////////////////////////////////
  
  This example also shows how to troubleshoot, the LED changes red when data
  from a user device is received. 
  
  Tom Arthur
  NYU ITP
  
  This project is enabled by the LightBlue Bean.
  https://punchthrough.com/bean/
  
 
 */


///////////////////////////////////////////////////////
// Required variables for Theme Park of Everyday Installations

// Store values recieved by device
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
    Bean.setLed(0, 255, 0);
    // Read the scratch number. This is how a user's device talks to your Installation.
    scratchNumber = Bean.readScratchNumber(1);
    
    if (scratchNumber != lastScratchNumber) {
      // TROUBLESHOOTING: show that data has come in from the user device
      Bean.setLed(0, 0, 255);
      
      
      // make something happen here //


      lastScratchNumber = scratchNumber;
    }


  } 
  else {
    // when disconnected from the user device, turn the installation off.
    
    // reset your installation here //

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



