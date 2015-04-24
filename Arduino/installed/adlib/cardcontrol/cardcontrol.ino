/*

 Automatic Ad Lib
 Thesis Version
 
 Tom Arthur
 ITP Thesis 2015 Spring
 ITP Automata 2014 Fall
 
 Includes public domain code by Nicholas Zambetti
 Wire Master Reader
 by Nicholas Zambetti <http://www.zambetti.com>
 
 Demonstrates use of the Wire library
 Reads data from an I2C/TWI slave device
 Refer to the "Wire Slave Sender" example for use with this
 
 Created 29 March 2006
 This example code is in the public domain.
 
 Includes public domain code by Tom Igoe:
 Time Check
 
 Gets the time from the Linux processor via Bridge
 then parses out hours, minutes and seconds for the Arduino
 using an Arduino Yun.
 
 created  27 May 2013
 modified 21 June 2013
 By Tom Igoe
 
 */


#include <AccelStepper.h>
#include <Wire.h>
#define DS1307_ADDRESS 0x68

//Process date;                 // process used to get the date
int hours, minutes, seconds;  // for the results
int lastSecond = -1;          // need an impossible value for comparison
int lastMinute = -1;          // last minute for use with cards
int lastDisplayedTime = -2;   // last time displayed on cards
int millisSinceClock = 0;
int delayTime = 0;

int motorSpeed = 2000;        //maximum steps per second (about 3rps / at 16 microsteps)
int motorAccel = 1600;        //steps/second/second to accelerate

// const int ledPin =  13;       // the number of the LED pin

int serialCard0, serialCard1, serialCard2, serialCard3, serialCard4;

// universal for motor control
const int motorDirPin = 4;    // all motors travel in the same direction
const int sleepPin = 13;
int fullRotation = 2000;      // define full rotation to calculate new card
int state = 2;                // current display mode

//set up the accelStepper intances and associated variables
const int motorStepPin0 = 3;
const int calibratePin0 = 2;
const int homingValue0 = 440;
int calibrateState0 = 0;
int nextCard0 = 0;
int currentCard0 = 0;
int stepperCard0 = 0;
AccelStepper stepper0(1, motorStepPin0, motorDirPin);    // flip1

const int motorStepPin1 = 5;
const int calibratePin1 = 11;
const int homingValue1 = 110;
int calibrateState1 = 0;
int nextCard1 = 0;
int currentCard1 = 0;
int stepperCard1 = 0;
AccelStepper stepper1(1, motorStepPin1, motorDirPin);    // flip2

const int motorStepPin2 = 6;
const int calibratePin2 = 7;
const int homingValue2 = 515;
int calibrateState2 = 0;
int nextCard2 = 0;
int currentCard2 = 0;
int stepperCard2 = 0;
AccelStepper stepper2(1, motorStepPin2, motorDirPin);    // flip3

const int motorStepPin3 = 9;
const int calibratePin3 = 8;
const int homingValue3 = 110;
int calibrateState3 = 0;
int nextCard3 = 0;
int currentCard3 = 0;
int stepperCard3 = 0;
AccelStepper stepper3(1, motorStepPin3, motorDirPin);    // flip4

const int motorStepPin4 = 10;
const int calibratePin4 = 12;
const int homingValue4 = 105;
int calibrateState4 = 0;
int nextCard4 = 0;
int currentCard4 = 0;
int stepperCard4 = 0;

AccelStepper stepper4(1, motorStepPin4, motorDirPin);    // flip5
int networkState;
int lastState;
int showTimeRandom = 0;
int count = 0;
int needCalibrateCount = 0;

void setup() {
  Serial.begin(9600);

  Wire.begin(4);
  Wire.onReceive(receiveEvent); // register event
  //  while (!Serial);
  Serial.println("Automatic Automata");  // Title of sketch

  pinMode(sleepPin, OUTPUT);
  digitalWrite(sleepPin, HIGH);
  randomSeed(analogRead(3));

  stepper0.setPinsInverted(1, 0, 0);
  stepper0.setMaxSpeed(motorSpeed);
  stepper0.setAcceleration(motorAccel);
  pinMode(calibratePin0, INPUT);

  stepper1.setPinsInverted(1, 0, 0);
  stepper1.setMaxSpeed(motorSpeed);
  stepper1.setAcceleration(motorAccel);
  pinMode(calibratePin1, INPUT);

  stepper2.setPinsInverted(1, 0, 0);
  stepper2.setMaxSpeed(motorSpeed);
  stepper2.setAcceleration(motorAccel);
  pinMode(calibratePin2, INPUT);

  stepper3.setPinsInverted(1, 0, 0);
  stepper3.setMaxSpeed(motorSpeed);
  stepper3.setAcceleration(motorAccel);
  pinMode(calibratePin3, INPUT);

  stepper4.setPinsInverted(1, 0, 0);
  stepper4.setMaxSpeed(motorSpeed);
  stepper4.setAcceleration(motorAccel);
  pinMode(calibratePin4, INPUT);

  calibrate(stepper0, 0);
  calibrate(stepper1, 1);
  calibrate(stepper2, 2);
  calibrate(stepper3, 3);
  calibrate(stepper4, 4);
  Serial.println("done");

}

void loop() {
//Serial.println("loop");
  // random sequence
  if (state == 0) {
    Serial.println("starting");
    serialCard0 = random(11, 44);
    serialCard1 = random(11, 44);
    serialCard2 = random(2, 13);
    serialCard3 = random(11, 44);
    serialCard4 = random(11, 44);
    state = 3;

  }
  // display 0s
  else if (state == 1) {              // set next turn for blank display
    Serial.println("time to display 0s");
    Serial.println("time to display 0s");

    serialCard0 = 0;
    serialCard1 = 0;
    serialCard2 = 0;
    serialCard3 = 0;
    serialCard4 = 0;

    state = 2;

    // display time
  } 
  else if (state == 2) {
    delay(1000);
    getTime();

    if (lastDisplayedTime != minutes) {
      String tempHours0, tempHours1, tempMin0, tempMin1;

      String hourString = String( hours );
      String minString = String(minutes);

      tempHours0 = hourString.substring(0, 1);
      tempHours1 = hourString.substring(1);

      tempMin0 = minString.substring(0, 1);
      tempMin1 = minString.substring(1);

      Serial.println(hourString);
      Serial.println(minString);
      Serial.println("tempHours: ");
      Serial.println(tempHours0);
      Serial.println(tempHours1);
      Serial.println(tempMin0);
      Serial.println(tempMin1);


      if (tempHours0 == 0 && tempHours1 == 0 && tempMin0 == 0 && tempMin1 == 0) {
        serialCard0 = 0;
        serialCard1 = 0;
        serialCard2 = 0;
        serialCard3 = 0;
        serialCard4 = 0;
        Serial.println("0 time so random cards");
      } 
      else {
        if (tempHours0 == 0) {
          serialCard0 = 1;
          serialCard1 = tempHours0.toInt() + 1;
 
        } else {
          serialCard0 = tempHours0.toInt() + 1;
          serialCard1 = tempHours1.toInt() + 1;
        }
        
        if (tempMin0 == 0) {
          serialCard3 = 1;
          serialCard4 = tempMin0.toInt() + 1;
        } else {
          serialCard3 = tempMin0.toInt() + 1;
          serialCard4 = tempMin1.toInt() + 1;
        }
         serialCard2 = 2;
      }

      //      state = ;

      lastDisplayedTime = minutes;
    }

  } 
  else if (state == 3) {
    delay(100);
  } 
  else if (state == 4) {
    
    if (needCalibrateCount >= 5) {
      
    calibrate(stepper0, 0);
    calibrate(stepper1, 1);
    calibrate(stepper2, 2);
    calibrate(stepper3, 3);
    calibrate(stepper4, 4);
    needCalibrateCount = 0;
    }
    
    state = 2;
  } else if (state == 5) {
    
    serialCard0 = 0;
    serialCard1 = 0;
    serialCard2 = 0;
    serialCard3 = 0;
    serialCard4 = 0;
    
    state = 4;
  }
  


  serialCard0 = constrain(serialCard0, 0, 45);
  serialCard1 = constrain(serialCard1, 0, 45);
  serialCard2 = constrain(serialCard2, 0, 40);
  serialCard3 = constrain(serialCard3, 0, 45);
  serialCard4 = constrain(serialCard4, 0, 45);

  stepperCard0 = serialCard0 * 45;
  stepperCard1 = serialCard1 * 45;
  stepperCard2 = serialCard2 * 50;
  stepperCard3 = serialCard3 * 45;
  stepperCard4 = serialCard4 * 45;


  int newPosition0 = stepperCard0;
  int newPosition1 = stepperCard1;
  int newPosition2 = stepperCard2;
  int newPosition3 = stepperCard3;
  int newPosition4 = stepperCard4;

  boolean fixLocation0 = false;
  boolean fixLocation1 = false;
  boolean fixLocation2 = false;
  boolean fixLocation3 = false;
  boolean fixLocation4 = false;

  if (stepperCard0 < currentCard0) {
    int tempPost0 = fullRotation - currentCard0;
    newPosition0 = currentCard0 + tempPost0 + newPosition0;
    //Serial.print("board 0 fixed position: ");
    //Serial.println(newPosition0);
    fixLocation0 = true;
  }

  if (stepperCard1 < currentCard1) {
    int tempPost1 = fullRotation - currentCard1;
    //Serial.print("board 1 fixed position: ");
    newPosition1 = currentCard1 + tempPost1 + newPosition1;
    fixLocation1 = true;
  }

  if (stepperCard2 < currentCard2) {
    int tempPost2 = fullRotation - currentCard2;
    //Serial.print("board 1 fixed position: ");
    newPosition2 = currentCard2 + tempPost2 + newPosition2;
    fixLocation2 = true;
  }

  if (stepperCard3 < currentCard3) {
    int tempPost3 = fullRotation - currentCard3;
    //Serial.print("board 1 fixed position: ");
    newPosition3 = currentCard3 + tempPost3 + newPosition3;
    fixLocation3 = true;
  }
  if (stepperCard4 < currentCard4) {
    int tempPost4 = fullRotation - currentCard4;
    //Serial.print("board 1 fixed position: ");
    newPosition4 = currentCard4 + tempPost4 + newPosition4;
    fixLocation4 = true;
  }

  stepper0.moveTo(newPosition0);
  stepper1.moveTo(newPosition1);
  stepper2.moveTo(newPosition2);
  stepper3.moveTo(newPosition3);
  stepper4.moveTo(newPosition4);

  if (stepper0.distanceToGo() != 0 || stepper1.distanceToGo() != 0 || stepper2.distanceToGo() != 0 || stepper3.distanceToGo() != 0 || stepper4.distanceToGo() != 0){
    digitalWrite(sleepPin, LOW);
    delay(100);
  } else {
    digitalWrite(sleepPin, HIGH);
  }
  
  while (stepper0.distanceToGo() != 0 || stepper1.distanceToGo() != 0 || stepper2.distanceToGo() != 0 || stepper3.distanceToGo() != 0 || stepper4.distanceToGo() != 0) {
    stepper0.run();
    stepper1.run();
    stepper2.run();
    stepper3.run();
    stepper4.run();

    if (stepper0.distanceToGo() == 0) {
      if (fixLocation0 == true) {
        //Serial.print("location 0 it thinks is: ");
        //Serial.println(stepper0.currentPosition());
        stepper0.setCurrentPosition(stepperCard0);
        //Serial.print("fixed location for 0 ");
        //Serial.println(stepperCard0);
        fixLocation0 = false;
      }

      currentCard0 = stepper0.currentPosition();
      stepper0.stop();
    }

    if (stepper1.distanceToGo() == 0) {
      if (fixLocation1 == true) {
        //Serial.print("location 1 it thinks is: ");
        //Serial.println(stepper1.currentPosition());
        stepper1.setCurrentPosition(stepperCard1);
        //Serial.print("fixed location for 1 ");
        //Serial.println(stepperCard1);
        fixLocation1 = false;
      }

      currentCard1 = stepper1.currentPosition();
      stepper1.stop();
    }

    if (stepper2.distanceToGo() == 0) {
      if (fixLocation2 == true) {
        //Serial.print("location 0 it thinks is: ");
        //Serial.println(stepper0.currentPosition());
        stepper2.setCurrentPosition(stepperCard2);
        //Serial.print("fixed location for 0 ");
        //Serial.println(stepperCard0);
        fixLocation2 = false;
      }

      currentCard2 = stepper2.currentPosition();
      stepper2.stop();
    }

    if (stepper3.distanceToGo() == 0) {
      if (fixLocation3 == true) {
        //Serial.print("location 0 it thinks is: ");
        //Serial.println(stepper0.currentPosition());
        stepper3.setCurrentPosition(stepperCard3);
        //Serial.print("fixed location for 0 ");
        //Serial.println(stepperCard0);
        fixLocation3 = false;
      }

      currentCard3 = stepper3.currentPosition();
      stepper3.stop();
    }

    if (stepper4.distanceToGo() == 0) {
      if (fixLocation4 == true) {
        //Serial.print("location 0 it thinks is: ");
        //Serial.println(stepper0.currentPosition());
        stepper4.setCurrentPosition(stepperCard4);
        //Serial.print("fixed location for 0 ");
        //Serial.println(stepperCard0);
        fixLocation4 = false;
      }

      currentCard4 = stepper4.currentPosition();
      stepper4.stop();
    }
  }
}


void calibrate(AccelStepper currentStepper, int currentFlip) {
  digitalWrite(sleepPin, LOW);
  boolean step1 = false;        // part one of calibration complete
  boolean calibrated = false;   // calibration complete
  int startTime = millis();
  int millisWait = 0;
  int currentCalibrate = -1;
  int currentCalibratePin = -1;
  int currentHomingValue = -1;

  currentStepper.setMaxSpeed(400);
  currentStepper.setAcceleration(80000.0);
  Serial.println(currentFlip);
  // set pins and homing locations for each board
  if (currentFlip == 0) {
    currentCalibrate = calibrateState0;
    currentCalibratePin = calibratePin0;
    currentHomingValue = homingValue0;
  }
  else if (currentFlip == 1) {
    currentCalibrate = calibrateState1;
    currentCalibratePin = calibratePin1;
    currentHomingValue = homingValue1;

  }
  else if (currentFlip == 2) {
    currentCalibrate = calibrateState2;
    currentCalibratePin = calibratePin2;
    currentHomingValue = homingValue2;

  }
  else if (currentFlip == 3) {
    currentCalibrate = calibrateState3;
    currentCalibratePin = calibratePin3;
    currentHomingValue = homingValue3;

  }
  else if (currentFlip == 4) {
    currentCalibrate = calibrateState4;
    currentCalibratePin = calibratePin4;
    currentHomingValue = homingValue4;

  }
  else {

    //    Serial.println("ERROR THIS ISN'T A STEPPER I UNDERSTAND");
  }

  // set an artifically long movement so we it all the way though the hole
  currentStepper.moveTo(10000);

  // find the magnet that indicates the index position
  while (step1 == false) {
    currentStepper.run();

    currentCalibrate = digitalRead(currentCalibratePin);
    //    Serial.println(currentCalibrate);
    //    if (millis() > startTime + 1000){
    // check if the home position is found
    // if it is, the calibration is complete:
    if (currentCalibrate == LOW) {
      if (step1 == false) {
        // turn LED on:
        // digitalWrite(ledPin, HIGH);
        currentStepper.stop();
        currentStepper.setCurrentPosition(0);

        delay(500);

        step1 = true;
        currentStepper.moveTo(currentHomingValue);

      }
    }
    else {
      // digitalWrite(ledPin, LOW);
    }
    //    }
  }

  // move to the start card
  while (step1 == true && calibrated == false) {

    if (currentStepper.distanceToGo() == 0) {
      //go the other way the same amount of steps
      //so if current position is 400 steps out, go position -400
      currentStepper.setCurrentPosition(0);
      calibrated = true;
    }

    currentStepper.run();
  }

  currentStepper.setCurrentPosition(0);

  //  Serial.print("calibration done for: ");
  //  Serial.println(currentFlip);
  //  delay(500);
  digitalWrite(sleepPin, HIGH);
}



void getTime() {

  // Reset the register pointer
  Wire.beginTransmission(DS1307_ADDRESS);

  byte zero = 0x00;
  Wire.write(zero);
  Wire.endTransmission();

  Wire.requestFrom(DS1307_ADDRESS, 7);

  int second = bcdToDec(Wire.read());
  int minute = bcdToDec(Wire.read());
  int hour = bcdToDec(Wire.read() & 0b111111); //24 hour time
  int weekDay = bcdToDec(Wire.read()); //0-6 -> sunday - Saturday
  int monthDay = bcdToDec(Wire.read());
  int month = bcdToDec(Wire.read());
  int year = bcdToDec(Wire.read());

  //print the date EG   3/1/11 23:59:59
  hours = hour;
  minutes = minute;

}

// function that executes whenever data is received from master
// this function is registered as an event, see setup()
void receiveEvent(int howMany)
{
  while(1 < Wire.available()) // loop through all but the last
  {
    char c = Wire.read(); // receive byte as a character
    Serial.print(c);         // print the character
  }
  int x = Wire.read();    // receive byte as an integer

  Serial.println(x);         // print the integer

  if (x == 71) {
    Serial.println("start sequence");
    state = 0;
  } 
  else if ( x == 69) {
    state = 5;
    needCalibrateCount++;
    Serial.println("end Sequence");
  }
}

byte bcdToDec(byte val)  {
  // Convert binary coded decimal to normal decimal numbers
  return ( (val/16*10) + (val%16) );
}


