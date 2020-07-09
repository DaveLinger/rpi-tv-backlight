# rpi-tv-backlight
Software for controlling an LED strip connected to a raspberry pi's GPIO based on time of day and TV state determined via HDMI-CEC

# How to install

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
