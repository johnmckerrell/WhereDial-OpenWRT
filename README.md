WhereDial - OpenWRT
-------------------

A set of scripts and code for an OpenWRT based WhereDial.
Currently tested on an TP-Link WR-703N only. Requires an
Arduino (Leonardo so far) plugged in and running code
for controlling the motor and lights.

The files included are as follows:

 * `bin/wheredial.sh`
  * Installed in `/root/wheredial.sh`
  * Must be made executable using `chmod 755 /root/wheredial.sh`
  * Main script that performs the HTTP requests to mapme.at and sends
    commands to the Arduino to turn the motor and change the LED status.
 * `init/wheredial`
  * Installed in `/etc/init.d/wheredial`
  * Must be made executable using `chmod 755 /etc/init.d/wheredial`
  * Must be enabled using: `/etc/init.d/wheredial enable`
  * Daemonising script, starts wheredial.sh on boot
 * `system/tplink_install.sh`
 * `system/update.sh`
  * Installed in `/root/tplink_install.sh` and `/root/update.sh`
  * Is used to upgrade openwrt and install the required packages.
