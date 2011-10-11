###############################################################################
#                     Makefile for Arduino Duemilanove/Uno                    #
#             Copyright (C) 2011 Álvaro Justen <alvaro@justen.eng.br>         #
#                         http://twitter.com/turicas                          #
#                                                                             #
# This project is hosted at GitHub: http://github.com/turicas/arduinoMakefile #
#                                                                             #
# This program is free software; you can redistribute it and/or               #
#  modify it under the terms of the GNU General Public License                #
#  as published by the Free Software Foundation; either version 2             #
#  of the License, or (at your option) any later version.                     #
#                                                                             #
# This program is distributed in the hope that it will be useful,             #
#  but WITHOUT ANY WARRANTY; without even the implied warranty of             #
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the              #
#  GNU General Public License for more details.                               #
#                                                                             #
# You should have received a copy of the GNU General Public License           #
#  along with this program; if not, please read the license at:               #
#  http://www.gnu.org/licenses/gpl-2.0.html                                   #
###############################################################################

#Sketch, board and IDE path configuration (in general change only this section)
# Sketch filename (should be in the same directory of Makefile)
SKETCH_NAME=Blink.pde
# The port Arduino is connected
#  Uno, in GNU/linux: generally /dev/ttyACM0
#  Duemilanove, in GNU/linux: generally /dev/ttyUSB0
PORT=/dev/ttyACM0
# The path of Arduino IDE
ARDUINO_DIR=/home/alvaro/arduino-0022
# Boardy type: use "arduino" for Uno or "stk500v1" for Duemilanove
BOARD_TYPE=arduino
# Baud-rate: use "115200" for Uno or "19200" for Duemilanove
BAUD_RATE=115200

#Compiler and uploader configuration
ARDUINO_CORE=$(ARDUINO_DIR)/hardware/arduino/cores/arduino
INCLUDE=-I. -I$(ARDUINO_DIR)/hardware/arduino/cores/arduino
TMP_DIR=/tmp/build_arduino
MCU=atmega328p
DF_CPU=16000000
CC=/usr/bin/avr-gcc
CPP=/usr/bin/avr-g++
AVR_OBJCOPY=/usr/bin/avr-objcopy 
AVRDUDE=/usr/bin/avrdude
CC_FLAGS=-g -Os -w -Wall -ffunction-sections -fdata-sections -fno-exceptions \
	 -std=gnu99
CPP_FLAGS=-g -Os -w -Wall -ffunction-sections -fdata-sections -fno-exceptions
AVRDUDE_CONF=/etc/avrdude.conf
CORE_C_FILES=pins_arduino WInterrupts wiring_analog wiring wiring_digital \
	     wiring_pulse wiring_shift
CORE_CPP_FILES=HardwareSerial main Print Tone WMath WString


all:		clean compile upload

clean:
		@echo '# *** Cleaning...'
		rm -rf "$(TMP_DIR)"


compile:
		@echo '# *** Compiling...'

		mkdir $(TMP_DIR)
		echo '#include "WProgram.h"' > "$(TMP_DIR)/$(SKETCH_NAME).cpp"
		cat $(SKETCH_NAME) >> "$(TMP_DIR)/$(SKETCH_NAME).cpp"

		@#$(CPP) -MM -mmcu=$(MCU) -DF_CPU=$(DF_CPU) $(INCLUDE) \
		#         $(CPP_FLAGS) "$(TMP_DIR)/$(SKETCH_NAME).cpp" \
		#	 -MF "$(TMP_DIR)/$(SKETCH_NAME).d" \
		#	 -MT "$(TMP_DIR)/$(SKETCH_NAME).o"

		@#Compiling the sketch file:
		$(CPP) -c -mmcu=$(MCU) -DF_CPU=$(DF_CPU) $(INCLUDE) \
		       $(CPP_FLAGS) "$(TMP_DIR)/$(SKETCH_NAME).cpp" \
		       -o "$(TMP_DIR)/$(SKETCH_NAME).o"
		
		@#Compiling Arduino core .c dependecies:
		for core_c_file in ${CORE_C_FILES}; do \
		    $(CC) -c -mmcu=$(MCU) -DF_CPU=$(DF_CPU) $(INCLUDE) \
		          $(CC_FLAGS) $(ARDUINO_CORE)/$$core_c_file.c \
			  -o $(TMP_DIR)/$$core_c_file.o; \
		done

		@#Compiling Arduino core .cpp dependecies:
		for core_cpp_file in ${CORE_CPP_FILES}; do \
		    $(CPP) -c -mmcu=$(MCU) -DF_CPU=$(DF_CPU) $(INCLUDE) \
		           $(CPP_FLAGS) $(ARDUINO_CORE)/$$core_cpp_file.cpp \
			   -o $(TMP_DIR)/$$core_cpp_file.o; \
		done

		@#TODO: compile external libraries here
		@#TODO: use .d files to track dependencies and compile them
		@#      change .c by -MM and use -MF to generate .d

		$(CC) -mmcu=$(MCU) -lm -Wl,--gc-sections -Os \
		      -o $(TMP_DIR)/$(SKETCH_NAME).elf $(TMP_DIR)/*.o
		$(AVR_OBJCOPY) -O ihex -R .eeprom \
		               $(TMP_DIR)/$(SKETCH_NAME).elf \
			       $(TMP_DIR)/$(SKETCH_NAME).hex
		@echo '# *** Compiled successfully! \o/'


reset:
		@echo '# *** Resetting...'
		stty --file $(PORT) hupcl
		sleep 0.1
		stty --file $(PORT) -hupcl
		

upload:
		@echo '# *** Uploading...'
		$(AVRDUDE) -q -V -p $(MCU) -C $(AVRDUDE_CONF) -c $(BOARD_TYPE) \
		           -b $(BAUD_RATE) -P $(PORT) \
			   -U flash:w:$(TMP_DIR)/$(SKETCH_NAME).hex:i
		@echo '# *** Done - enjoy your sketch!'
