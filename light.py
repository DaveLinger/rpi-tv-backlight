#!/usr/bin/env python3
import sys
import time
from rpi_ws281x import *
import argparse

# LED strip configuration:
LED_COUNT      = 60      # Number of LED pixels.
LED_PIN        = 18      # GPIO pin connected to the pixels (18 uses PWM!).
LED_FREQ_HZ    = 800000  # LED signal frequency in hertz (usually 800khz)
LED_DMA        = 10      # DMA channel to use for generating signal (try 10)
LED_BRIGHTNESS = 250     # Set to 0 for darkest and 255 for brightest
LED_INVERT     = False   # True to invert the signal (when using NPN transistor level shift)
LED_CHANNEL    = 0       # set to '1' for GPIOs 13, 19, 41, 45 or 53

def colorWipeOn(strip, ledrange, green, red, blue, speed):
    for r in range(ledrange):
        redval = (r*red)//ledrange
        greenval = (r*green)//ledrange
        blueval = (r*blue)//ledrange
        thecolor = Color(redval,greenval,blueval)
        for i in range(strip.numPixels()):
            strip.setPixelColor(i, thecolor)
        strip.show()
	time.sleep(speed)

def colorWipeOff(strip, ledrange, green, red, blue, speed):
    for r in range(ledrange,-1,-1):
        redval = (r*red)//ledrange
        greenval = (r*green)//ledrange
        blueval = (r*blue)//ledrange
        thecolor = Color(redval,greenval,blueval)
        for i in range(strip.numPixels()):
            strip.setPixelColor(i, thecolor)
        strip.show()
        time.sleep(speed)

# Main program logic follows:
if __name__ == '__main__':

    strip = Adafruit_NeoPixel(LED_COUNT, LED_PIN, LED_FREQ_HZ, LED_DMA, LED_INVERT, LED_BRIGHTNESS, LED_CHANNEL)
    strip.begin()

    if sys.argv[1] == "on":
        colorWipeOn(strip, 50, 0, 0, 50, 0.1)

    if sys.argv[1] == "off":
        colorWipeOff(strip, 50, 0, 0, 50, 0.05)
