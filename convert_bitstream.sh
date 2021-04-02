#!/usr/bin/env bash

BITSTREAM_FILE=./FpgaProject/projects/MKRVIDOR4000_template/output_files/MKRVIDOR4000.ttf
ARDUINO_FILE=./ArduinoSketch/MusicJukebox/app.h 

echo "// $(date)" > $ARDUINO_FILE
./vidorcvt/vidorcvt < $BITSTREAM_FILE >> $ARDUINO_FILE 
