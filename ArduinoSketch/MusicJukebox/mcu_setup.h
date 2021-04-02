#include <wiring_private.h>
//
///* Configure in Quartus */
//#define FPGA_NINA_TX         ( 0)
//#define FPGA_NINA_RX         ( 1)
//
//#define FPGA_NINA_MISO       (10)
//#define FPGA_NINA_SCK        ( 9)
//#define FPGA_NINA_MOSI       ( 8)
//
//#define FPGA_NINA_GPIO0      ( 7) // WM_PIO27 -> NiNa GPIO0 -> FPGA N9
//#define FPGA_SPIWIFI_RESET   ( 6) // WM_RESET -> NiNa RESETN -> FPGA R1
//#define FPGA_SPIWIFI_ACK     ( 5) // WM_PIO7  -> NiNa GPIO33 -> FPGA P6
//#define FPGA_SPIWIFI_SS      ( 4) // WM_PIO28 -> NiNa GPIO5 -> FPGA N11
//
///* Assign new serial port in SAMD hardware for the Wifi Nina Module */
//// https://www.arduino.cc/en/Tutorial/SamdSercom
//Uart SerialNina (&sercom3, 1, 0, SERCOM_RX_PAD_1, UART_TX_PAD_0); // Create the new UART instance assigning it to pin 1 and 0
//
//// Attach the interrupt handler to the SERCOM
//void SERCOM3_Handler() {
//  SerialNina.IrqHandler();
//}

// https://github.com/guywithaview/Arduino-Test/blob/master/sercom/sercom.ino
/*
  SERCOM Test
  
  Test the ability to add extra hardware serial ports to the MKR1000
  This sketch has the following serial interfaces:
    Serial  - Native USB interface
    Serial1 - Default serial port on D13, D14 (Sercom 5)
    Serial2 - Extra serial port on D0, D1 (Sercom 3)
    Serial3 - Extra serial port on D4, D5 (Sercom 4)
    
  Good explanation of sercom funcationality here: 
  https://learn.adafruit.com/using-atsamd21-sercom-to-add-more-spi-i2c-serial-ports/muxing-it-up
  This sketch will echo characters recieved on any of the 4 serial ports to all other serial ports.
  for Arduino MKR1000
  by Tom Kuehn
  26/06/2016
*/

/*
// Serial2 pin and pad definitions (in Arduino files Variant.h & Variant.cpp)
#define PIN_SERIAL2_RX       (1ul)                // Pin description number for PIO_SERCOM on D1
#define PIN_SERIAL2_TX       (0ul)                // Pin description number for PIO_SERCOM on D0
#define PAD_SERIAL2_TX       (UART_TX_PAD_0)      // SERCOM pad 0 TX
#define PAD_SERIAL2_RX       (SERCOM_RX_PAD_1)    // SERCOM pad 1 RX

// Serial3 pin and pad definitions (in Arduino files Variant.h & Variant.cpp)
#define PIN_SERIAL3_RX       (5ul)                // Pin description number for PIO_SERCOM on D5
#define PIN_SERIAL3_TX       (4ul)                // Pin description number for PIO_SERCOM on D4
#define PAD_SERIAL3_TX       (UART_TX_PAD_2)      // SERCOM pad 2 TX
#define PAD_SERIAL3_RX       (SERCOM_RX_PAD_3)    // SERCOM pad 3 RX

// Instantiate the extra Serial classes
Uart Serial2(&sercom3, PIN_SERIAL2_RX, PIN_SERIAL2_TX, PAD_SERIAL2_RX, PAD_SERIAL2_TX);
Uart Serial3(&sercom4, PIN_SERIAL3_RX, PIN_SERIAL3_TX, PAD_SERIAL3_RX, PAD_SERIAL3_TX);

void SERCOM3_Handler()    // Interrupt handler for SERCOM3
{
  Serial2.IrqHandler();
}

void SERCOM4_Handler()    // Interrupt handler for SERCOM4
{
  Serial3.IrqHandler();
}

*/
