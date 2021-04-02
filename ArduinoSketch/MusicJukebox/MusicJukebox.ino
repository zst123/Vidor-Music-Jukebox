#include "fpga_setup.h"
#include "mcu_setup.h"


void init_app() {
  // Serial  - Native USB interface
  // Serial1 - Default serial port on D13, D14 (Sercom 5)

  // Start serial communication to PC
  Serial.begin(115200);
  Serial.println("Hello world!");

  // Start serial communication to FPGA
  Serial1.begin(9600);

  pinMode(A6, INPUT);
  pinMode(A5, INPUT);
  pinMode(A4, INPUT);
  pinMode(A4, INPUT);
  pinMode(A3, INPUT);
  pinMode(A2, INPUT);
  pinMode(A1, INPUT);
  pinMode(A0, INPUT);


  pinMode(5, INPUT);
  pinMode(4, INPUT);
  pinMode(3, INPUT);
  pinMode(2, INPUT);
  pinMode(1, INPUT);
  pinMode(0, INPUT);

  //pinMode(D14, INPUT);
  //pinMode(D13, INPUT);
}

// the loop function runs over and over again forever
void loop() {
  digitalWrite(LED_BUILTIN, !digitalRead(A6));
  
  while (Serial.available()) {
    char recv = Serial.read();
    //Serial.print("Recv:")
    //Serial.println(recv);
    Serial1.print(recv);
  }

  while (Serial1.available()) {
    char recv = Serial1.read();
    Serial.print("Recv1:");
    Serial.println(recv);    
  }
}
