#include <stdlib.h>
#include <math.h>
#include <Stepper.h>

const int stepsPerRevolution = 2048;
int motorPins[] = {A2,A5,A3,A4};
Stepper myStepper(stepsPerRevolution, motorPins[0],motorPins[1],motorPins[2],motorPins[3]);

int actual;
int prev=0;
int placeChanged=0;
int spinToggle=1;

char serialFormat[] = { 'M', 'K', 'E', 'W', 'D', ' ', ' ', ' ', ' ', 'D', 'W', 'E', 'K', 'M' };
int preambleStopIndex = 4;
int postambleStartIndex = 9;
int formatLength = 13;
int valueLength = 4;

void setup() {
  Serial.begin(115200);
  for(int i=0; i< 6; i++){
    pinMode(i+2,OUTPUT);
    digitalWrite(i+2,(i==0)?LOW:HIGH);
  }
  myStepper.setSpeed(14);
}
 
void loop() {
    int formatIndex = 0;
    char value[5] = { 0, 0, 0, 0, '\0' };
    
    while (1) {
        delay(3);
        char in = Serial.read();
        if( in == (char) -1 ){
          // Hmmm
        } else if( in == serialFormat[formatIndex] ){
          formatIndex++;
          if (formatIndex > formatLength) {
            break;
          }
        } else if (formatIndex > preambleStopIndex && formatIndex < postambleStartIndex) {
            value[formatIndex-preambleStopIndex-1] = in;
            formatIndex++;
        } else if (in == serialFormat[0] ) {
          formatIndex=1;
        } else {
          formatIndex=0;
        }

    }
    int num = atoi(value+1);

    switch(value[0]){
      case 'T':
        prev=actual;
        actual=num;
        if(prev==actual){ placeChanged=1; }
        turn();
        
        break;
      case 'L':
        for(int i=0; i<6; i++){
          digitalWrite(i+2,((num&(1<<i)) == (1<<i))?HIGH:LOW);
        }
        break;
      case 'R':
        for(int i=0; i<6; i++){
          digitalWrite(i+2,LOW);
        }
        prev =0;
        actual =0;
  }
}
void turn()
{
  int diff = actual-prev;
  int angle=map(diff, 0, 360, 0, 12234);
  myStepper.step(-angle);
  if (!angle && placeChanged) {
    myStepper.step(12234 * spinToggle);
    spinToggle = 0 - spinToggle;
    placeChanged = 0;
  }
  
  /* TURN OFF THE MOTOR PINS, SAVE POWER & HEAT */
  for (int i = 0; i < 4; ++i) {
    digitalWrite(motorPins[i],LOW);
  }
}
