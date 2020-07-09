#!/usr/bin/env python3
import time
#from neopixel import *
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

# Define functions which animate LEDs in various ways.
def colorWipe(strip, ledrange, green, red, blue, speed):
    for r in range(ledrange,-1,-1):
        redval = (r*red)/ledrange
        greenval = (r*green)/ledrange
        blueval = (r*blue)/ledrange
        thecolor = Color(redval,greenval,blueval)
        for i in range(strip.numPixels()):
            strip.setPixelColor(i, thecolor)
        strip.show()
	time.sleep(speed)

def shutOff():
    for i in range(strip.numPixels()):
        strip.setPixelColor(i, Color(0, 0, 0))
    strip.show()

# Main program logic follows:
if __name__ == '__main__':
    # Process arguments
    parser = argparse.ArgumentParser()
    parser.add_argument('-c', '--clear', action='store_true', help='clear the display on exit')
    args = parser.parse_args()

    # Create NeoPixel object with appropriate configuration.
    strip = Adafruit_NeoPixel(LED_COUNT, LED_PIN, LED_FREQ_HZ, LED_DMA, LED_INVERT, LED_BRIGHTNESS, LED_CHANNEL)
    # Intialize the library (must be called once before other functions).
    strip.begin()

    print ('Press Ctrl-C to quit.')
    if not args.clear:
        print('Use "-c" argument to clear LEDs on exit')

    try:
        colorWipe(strip, 50, 0, 0, 50, 0.05)
        #function inputs are fade range (set to the same as your highest R/G/B value), green, red, blue, speed delay (more is slower)

#50 0 0 = green
#0 50 0 = red
#0 0 50 = blue
#50 50 0 = yellow
#50 0 50 = aqua

    except KeyboardInterrupt:
        if args.clear:
            shutOff()
