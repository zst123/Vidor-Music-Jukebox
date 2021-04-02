#include "fpga_setup.h"
#include "mcu_setup.h"

bool bootloaderMode = false;

void init_app() {

  // initialize serial communication at 9600 bits per second:
  Serial.begin(115200);
  Serial.println("Hello world!");
  SerialNina.begin(115200); // NINA-W102 baud rate
  pinPeripheral(1, PIO_SERCOM); //Assign RX function to pin 1
  pinPeripheral(0, PIO_SERCOM); //Assign TX function to pin 0


  pinMode(FPGA_NINA_GPIO0, OUTPUT);
  pinMode(FPGA_SPIWIFI_RESET, OUTPUT);
  pinMode(A6, INPUT);
  pinMode(A5, INPUT);
  pinMode(A4, INPUT);

  // Manually set to upload mode
  if (bootloaderMode) {
    digitalWrite(FPGA_NINA_GPIO0, LOW);
  } else {
    digitalWrite(FPGA_NINA_GPIO0, HIGH);
  }
  // Reset module
  digitalWrite(FPGA_SPIWIFI_RESET, LOW);
  delay(1000);
  digitalWrite(FPGA_SPIWIFI_RESET, HIGH);
  
}

int rts = -1;
int dtr = -1;

// the loop function runs over and over again forever
void loop() {
  digitalWrite(LED_BUILTIN, !digitalRead(A6));
  //digitalWrite(LED_BUILTIN, !digitalRead(LED_BUILTIN));
  //delay(250);

  while (Serial.available()) {
    SerialNina.write(Serial.read());
  }

  while (SerialNina.available()) {
    Serial.write(SerialNina.read());
  }

  if (rts != Serial.rts()) {
    digitalWrite(FPGA_SPIWIFI_RESET, Serial.rts() ? LOW : HIGH);
    rts = Serial.rts();
  }
  
  if (dtr != Serial.dtr()) {
    digitalWrite(FPGA_NINA_GPIO0, (Serial.dtr() == 0) ? HIGH : LOW);
    dtr = Serial.dtr();
  }
  
}
