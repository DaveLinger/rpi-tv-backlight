# rpi-tv-backlight
Software for controlling an LED strip connected to a raspberry pi's GPIO based on time of day and TV state determined via HDMI-CEC

# How to configure hardware

This assumes you are running a raspberry pi with "Raspberry Pi OS" (Raspbian) Buster. You will need to connect an HDMI cable to an HDMI port on your TV or AVR. If you don't want the TV switching to the pi's input when it turns on (you probably don't want this), you can disable this by adding "hdmi_ignore_cec_init=1" to your /boot/config.txt file.

This assumes you have a WS2812B 60-led strand connected to GPIO pin 12, (GPIO 18, PWM). In my case, I am also powering and grounding the LED strip via the pi's GPIO. You can do this or power it externally. You can control more or less LEDs easily just by changing the number from "60" to anything you want in on/off.py.

# How to install software

- Install Raspbian Buster. Sudo apt-get update/upgrade.
- Install cec-utils.
- Add your user to sudoers file to ensure they can sudo without password (required to control LED strip with python and to set clock)
- Install python and install rpi-ws281x with pip
- Install node.js and install pm2 with npm
- "npm startup" to get the command to ensure pm2 starts at boot
- If you aren't going to make your filesystem read-only, you can start the script with "pm2 start ledstrip_manager.sh", then use "pm2 save".

You can now reboot any time and pm2 should be running.

If you wish to run this on a read-only filesystem (recommended), follow these instructions: https://medium.com/swlh/make-your-raspberry-pi-file-system-read-only-raspbian-buster-c558694de79

I added an additional tmpfs (ram) mount in /etc/fstab just for this script's temporary files: "tmpfs        /trash          tmpfs   nosuid,nodev         0       0 "

You will need to kill pm2, remove ~/.pm2 directory, and make a symbolic link pointing that directory to your new tmpfs mount with "ln -s /trash/ ~/.pm2 (This way when pm2 starts with a read-only filesystem, it can still write to this folder in RAM)

To make pm2 start your script at boot, you need to edit /etc/systemd/system/pm2-pi.service and change your "ExecStart" to start your script with pm2: ExecStart=/usr/lib/node_modules/pm2/bin/pm2 start /home/pi/ledstrip_manager.sh

Now reboot and use "pm2 list" and the script should be running. "npm logs" to see live log output.
