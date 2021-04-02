#include "fpga_setup.h"
#include "mcu_setup.h"

//#include <SPI.h>
#include "src/WiFiNINA/WiFiNINA.h"
#include "wifi_secrets.h"

bool bootloaderMode = false;

void init_app() {
  // initialize serial communication at 9600 bits per second:
  Serial.begin(115200);
  while (!Serial); // wait for serial port to connect. Needed for native USB port only
  Serial.println("Hello world!");

  // Setup Wifi Serial
  SerialNina.begin(115200); // NINA-W102 baud rate
  pinPeripheral(1, PIO_SERCOM); //Assign RX function to pin 1
  pinPeripheral(0, PIO_SERCOM); //Assign TX function to pin 0

  // Setup Wifi pinouts
  pinMode(FPGA_NINA_GPIO0, OUTPUT);
  pinMode(FPGA_SPIWIFI_RESET, OUTPUT);

  // Manually set to upload mode
  if (bootloaderMode) {
    digitalWrite(FPGA_NINA_GPIO0, LOW);
  } else {
    digitalWrite(FPGA_NINA_GPIO0, HIGH);
  }
  // Reset Wifi module
  digitalWrite(FPGA_SPIWIFI_RESET, LOW);
  delay(100);
  digitalWrite(FPGA_SPIWIFI_RESET, HIGH);

  // Setup wifi
  //setup_wifi();
}

int rts = -1;
int dtr = -1;

// the loop function runs over and over again forever
void loop() {
  digitalWrite(LED_BUILTIN, !digitalRead(LED_BUILTIN));
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

  //loop_wifi();
}

 
///////please enter your sensitive data in the Secret tab/arduino_secrets.h
char ssid[] = SECRET_SSID;        // your network SSID (name)
char pass[] = SECRET_PASS;    // your network password (use for WPA, or use as key for WEP)
int status = WL_IDLE_STATUS;     // the WiFi radio's status

// Specify IP address or hostname
String hostName = "www.google.com";
int pingResult;

void setup_wifi() {
  // check for the WiFi module:
  if (WiFi.status() == WL_NO_MODULE) {
    Serial.println("Communication with WiFi module failed!");
    // don't continue
    while (true);
  }

  String fv = WiFi.firmwareVersion();
  if (fv < WIFI_FIRMWARE_LATEST_VERSION) {
    Serial.println("Please upgrade the firmware");
  }

  // attempt to connect to WiFi network:
  while ( status != WL_CONNECTED) {
    Serial.print("Attempting to connect to WPA SSID: ");
    Serial.println(ssid);
    // Connect to WPA/WPA2 network:
    status = WiFi.begin(ssid, pass);

    // wait 5 seconds for connection:
    delay(5000);
  }

  // you're connected now, so print out the data:
  Serial.println("You're connected to the network");
  printCurrentNet();
  printWiFiData();
}

void loop_wifi() {
  Serial.print("Pinging ");
  Serial.print(hostName);
  Serial.print(": ");

  pingResult = WiFi.ping(hostName);

  if (pingResult >= 0) {
    Serial.print("SUCCESS! RTT = ");
    Serial.print(pingResult);
    Serial.println(" ms");
  } else {
    Serial.print("FAILED! Error code: ");
    Serial.println(pingResult);
  }

  delay(5000);
}

void printWiFiData() {
  // print your board's IP address:
  IPAddress ip = WiFi.localIP();
  Serial.print("IP address : ");
  Serial.println(ip);

  Serial.print("Subnet mask: ");
  Serial.println((IPAddress)WiFi.subnetMask());

  Serial.print("Gateway IP : ");
  Serial.println((IPAddress)WiFi.gatewayIP());

  // print your MAC address:
  byte mac[6];
  WiFi.macAddress(mac);
  Serial.print("MAC address: ");
  printMacAddress(mac);
}

void printCurrentNet() {
  // print the SSID of the network you're attached to:
  Serial.print("SSID: ");
  Serial.println(WiFi.SSID());

  // print the MAC address of the router you're attached to:
  byte bssid[6];
  WiFi.BSSID(bssid);
  Serial.print("BSSID: ");
  printMacAddress(bssid);
  // print the received signal strength:
  long rssi = WiFi.RSSI();
  Serial.print("signal strength (RSSI): ");
  Serial.println(rssi);

  // print the encryption type:
  byte encryption = WiFi.encryptionType();
  Serial.print("Encryption Type: ");
  Serial.println(encryption, HEX);
  Serial.println();
}

void printMacAddress(byte mac[]) {
  for (int i = 5; i >= 0; i--) {
    if (mac[i] < 16) {
      Serial.print("0");
    }
    Serial.print(mac[i], HEX);
    if (i > 0) {
      Serial.print(":");
    }
  }
  Serial.println();
}
