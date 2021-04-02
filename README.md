# Vidor Music Jukebox

This is a music jukebox project made in Verilog HDL using the FPGA on the Arduino MKR Vidor 4000. 



## Before we start

#### Guides to set up the Arduino IDE and Quartus Prime IDE:

- https://www.arduino.cc/en/Tutorial/VidorGSVHDL
- https://www.arduino.cc/en/Tutorial/VidorQuartusVHDL/
- https://maker.pro/arduino/tutorial/how-to-program-the-arduino-mkr-vidor-4000s-fpga-with-intel-quartus-ide

#### Specifications of the MKR Vidor 4000

- https://www.element14.com/community/docs/DOC-92333/l/arduino-mkr-vidor-4000-pinout-samd21-pin-mapping-tech-specs-eagle-files-github-schematics-reference-links-faq-and-more 
- https://www.baldengineer.com/arduino-mkr-vidor-4000-hands-on.html
- https://www.arduino.cc/en/Guide/MKRVidor4000 

> Intel Cyclone 10 (10CL010YU256C8G) FPGA
>
> Microchip ATSAMD21G18A microcontroller



#### Arduino Connection

<img src="https://content.arduino.cc/assets/Pinout-MKRvidor4000_latest.png" alt="https://content.arduino.cc/assets/Pinout-MKRvidor4000_latest.png" style="zoom:20%;" />

#### Arduino Vidor Examples Codes

- https://github.com/vidor-libraries/VidorPeripherals
- https://github.com/vidor-libraries/VidorFPGA
- https://github.com/wd5gnr/VidorFPGA



## Hardware Setup

### Block Diagram

![Block Diagram](https://www.element14.com/community/servlet/JiveServlet/showImage/38-37453-1007629/pastedImage_1.png)

### Pinout

| Arduino  |    Device    |
| :------: | :----------: |
|    A0    |    LCD RS    |
|    A1    |    LCD EN    |
|    A4    |    Buzzer    |
|    A5    |  LED2 (PWM)  |
|    A6    | LED1 (Blink) |
|    D2    |    LCD D4    |
|    D3    |    LCD D5    |
|    D4    |    LCD D6    |
|    D5    |    LCD D7    |
| D13 (RX) |  HC-06 TXD   |
| D14 (TX) |  HC-06 RXD   |

### LCD Connections

Ussing a standard HD44780 LCD 16x2 Character display.

***Be careful of the 5V Vdd supply and the 3V3 logic levels***

```
/* ----------------------------------
 * PIN CONNECTIONS FOR LCD
 * ----------------------------------
 * (01) Vss - GND
 * (02) Vdd - 5V*
 * (03) Vee - GND with Resistor
 * (04) RS  - Arduino A0
 * (05) R/W - GND
 * (06) En  - Arduino A1
 * (07) DB0
 * (08) DB1
 * (09) DB2
 * (10) DB3
 * (11) DB4 - Arduino D2
 * (12) DB5 - Arduino D3
 * (13) DB6 - Arduino D4
 * (14) DB7 - Arduino D5
 * (15) LED+ (A) - 3V3 with Resistor
 * (16) LED- (K) - GND
 * ----------------------------------
 */
```

### Wifi NINA Module

Use my sketch for *VidorNinaSerialPassthrough*. It was based on this code: https://gist.github.com/sameer/6ee696303579798d2e20c9ab7e52a088

Communicate using command line esptool.

	$ pwd
	/home/user1/snap/arduino/50/.arduino15/packages/esp32/tools/esptool_py/2.6.1
	
	$ python3 esptool.py chip_id
	esptool.py v2.6
	Found 1 serial ports
	Serial port /dev/ttyACM1
	Connecting....
	Detecting chip type... ESP32
	Chip is ESP32D0WDQ6 (revision 1)
	Features: WiFi, BT, Dual Core, 240MHz, VRef calibration in efuse, Coding Scheme None
	MAC: 84:0d:8e:11:38:88
	Uploading stub...
	Running stub...
	Stub running...
	Warning: ESP32 has no Chip ID. Reading MAC instead.
	MAC: 84:0d:8e:11:38:88
	Hard resetting via RTS pin...

## Software Setup

### Arduino code

Inside the ArduinoSketch directory, there is the MusicJukebox project which contains the code to program the Arduino along with bitstream generated from FpgaProject

### FPGA code

The FpgaProject directory is the project to be opened in Quartus IDE. After generating the bitstream, run `convert_bitstream.sh` to convert the bitstream into an Arduino header file. 