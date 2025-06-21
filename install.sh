#!/bin/bash
set -e

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
apt-get update
apt-get install -y vim motion

echo "[${GRN}INFO${END}] Configuring motion and setting up service"
if ! grep -q "bcm2835-v4l2" /etc/modules; then
    echo "bcm2835-v4l2" >> /etc/modules
fi
modprobe bcm2835-v4l2

# turning on daemon
cat > /etc/default/motion <<EOF
start_motion_daemon=yes
EOF

sed -i 's/^daemon .*/daemon on/' /etc/motion/motion.conf 

# allowing streaming to devices besides localhost
sed -i 's/^stream_localhost .*/stream_localhost off/' /etc/motion/motion.conf
sed -i 's/^webcontrol_localhost .*/webcontrol_localhost off/' /etc/motion/motion.conf

# Set high resolution and framerate
sed -i 's/^width .*/width 1920/' /etc/motion/motion.conf
sed -i 's/^height .*/height 1080/' /etc/motion/motion.conf
sed -i 's/^framerate .*/framerate 30/' /etc/motion/motion.conf

# Set pixel format to MJPG for high resolution support
if ! grep -q "^video_params " /etc/motion/motion.conf; then
    echo "video_params pixelformat=MJPG" >> /etc/motion/motion.conf
else
    sed -i 's/^video_params .*/video_params pixelformat=MJPG/' /etc/motion/motion.conf
fi

# Set camera name idempotently
if ! grep -q "^camera_name " /etc/motion/motion.conf; then
    echo "camera_name PiCam" >> /etc/motion/motion.conf
else
    sed -i 's/^camera_name .*/camera_name PiCam/' /etc/motion/motion.conf
fi

# Ensure overlay text shows the camera name and timestamp
# Remove comment semicolon and whitespace before setting
sed -i 's/^[;#]\?\s*text_left.*/text_left PiCam/' /etc/motion/motion.conf
sed -i 's/^[;#]\?\s*text_right.*/text_right %Y-%m-%d\\n%T/' /etc/motion/motion.conf

# Add motion user to video group to access camera
usermod -a -G video motion

# Create log directory and set permissions
mkdir -p /var/log/motion
chown motion:motion /var/log/motion
chmod 755 /var/log/motion

# Create output directory and set permissions
mkdir -p /var/lib/motion
chown motion:motion /var/lib/motion
chmod 755 /var/lib/motion

service motion restart
service motion status

echo "[${GRN}INFO${END}] Rebooting for all changes to take effect"
#reboot
