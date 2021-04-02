#include <wiring_private.h>
#include "pinout.h"

/* Assign new serial port in SAMD hardware for the Wifi Nina Module */
// https://www.arduino.cc/en/Tutorial/SamdSercom
Uart SerialNina (&sercom3, 1, 0, SERCOM_RX_PAD_1, UART_TX_PAD_0); // Create the new UART instance assigning it to pin 1 and 0

// Attach the interrupt handler to the SERCOM
void SERCOM3_Handler() {
  SerialNina.IrqHandler();
}
