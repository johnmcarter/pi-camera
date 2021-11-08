#!/bin/bash

# Author: John Carter
# Created: 2021/10/17 19:27:01
# Last modified: 2021/11/07 8:36:54

# NOTE: Must be run as root
# https://raspberrypi.stackexchange.com/questions/78715/motion-daemon-var-log-motion-motion-log-permission-denied

GRN=$'\e[1;32m'
RED=$'\e[1;31m'
END=$'\e[0m'


if (( EUID != 0 )); then
   echo "[${RED}ERROR${END}] This script must be run as root" 
   exit 1
fi

echo "[${GRN}INFO${END}] Changing hostname to picamera"
cat > /etc/hostname <<EOF
picamera
EOF
sed -i 's/127.0.0.1 raspberrypi/127.0.0.1 picamera/' /etc/hosts

echo "[${GRN}INFO${END}] Updating and installing necessary packages"
apt update
apt install vim
apt-get install motion

echo "[${GRN}INFO${END}] Configuring motion and setting up service"
modprobe bcm2835-v4l2

# turning on daemon
cat > /etc/default/motion <<EOF
start_motion_daemon=yes
EOF

sed -i 's/daemon off/daemon on/' /etc/motion/motion.conf 

# allowing streaming to devices besides localhost
sed -i 's/stream_localhost on/stream_localhost off/' /etc/motion/motion.conf
sed -i 's/webcontrol_localhost off/webcontrol_localhost on/' /etc/motion/motion.conf

service motion start
service motion status

echo "[${GRN}INFO${END}] Rebooting for all changes to take effect"
reboot
