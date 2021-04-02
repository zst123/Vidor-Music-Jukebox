#include <wiring_private.h>

/* Configure in Quartus */
#define FPGA_NINA_TX         ( 0)
#define FPGA_NINA_RX         ( 1)

#define FPGA_NINA_MISO       (10)
#define FPGA_NINA_SCK        ( 9)
#define FPGA_NINA_MOSI       ( 8)

#define FPGA_NINA_GPIO0      ( 7) // WM_PIO27 -> NiNa GPIO0 -> FPGA N9
#define FPGA_SPIWIFI_RESET   ( 6) // WM_RESET -> NiNa RESETN -> FPGA R1
#define FPGA_SPIWIFI_ACK     ( 5) // WM_PIO7  -> NiNa GPIO33 -> FPGA P6
#define FPGA_SPIWIFI_SS      ( 4) // WM_PIO28 -> NiNa GPIO5 -> FPGA N11

/* Assign new serial port in SAMD hardware for the Wifi Nina Module */
// https://www.arduino.cc/en/Tutorial/SamdSercom
Uart SerialNina (&sercom3, 1, 0, SERCOM_RX_PAD_1, UART_TX_PAD_0); // Create the new UART instance assigning it to pin 1 and 0

// Attach the interrupt handler to the SERCOM
void SERCOM3_Handler() {
  SerialNina.IrqHandler();
}
