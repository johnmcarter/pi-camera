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
echo "picamera" > /etc/hostname
sed -i 's/127.0.1.1 .*/127.0.1.1 picamera/' /etc/hosts

echo "[${GRN}INFO${END}] Installing required packages..."
apt-get update
apt-get install -y vim motion

echo "[${GRN}INFO${END}] Loading camera module..."
if ! grep -q "bcm2835-v4l2" /etc/modules; then
    echo "bcm2835-v4l2" >> /etc/modules
fi
modprobe bcm2835-v4l2

echo "[${GRN}INFO${END}] Ensuring motion user has camera access..."
usermod -aG video motion

echo "[${GRN}INFO${END}] Creating log/output directories with proper ownership..."
mkdir -p /var/log/motion /var/lib/motion
chown motion:motion /var/log/motion /var/lib/motion
chmod 755 /var/log/motion /var/lib/motion

echo "[${GRN}INFO${END}] Updating motion configuration..."
CONF="/etc/motion/motion.conf"
sed -i 's/^daemon .*/daemon on/' "$CONF"
sed -i 's/^stream_localhost .*/stream_localhost off/' "$CONF"
sed -i 's/^webcontrol_localhost .*/webcontrol_localhost off/' "$CONF"
sed -i 's/^width .*/width 1920/' "$CONF"
sed -i 's/^height .*/height 1080/' "$CONF"
sed -i 's/^framerate .*/framerate 30/' "$CONF"
sed -i 's/^[;#]*\s*text_left.*/text_left PiCam/' "$CONF"
sed -i 's/^[;#]*\s*text_right.*/text_right %Y-%m-%d\\n%T/' "$CONF"

# Set MJPEG pixel format
if grep -q "^video_params " "$CONF"; then
    sed -i 's/^video_params .*/video_params pixelformat=MJPG/' "$CONF"
else
    echo "video_params pixelformat=MJPG" >> "$CONF"
fi

# Set camera name
if grep -q "^camera_name " "$CONF"; then
    sed -i 's/^camera_name .*/camera_name PiCam/' "$CONF"
else
    echo "camera_name PiCam" >> "$CONF"
fi

echo "[${GRN}INFO${END}] Writing custom systemd unit to run as motion user..."

cat > /etc/systemd/system/motion.service <<EOF
[Unit]
Description=Motion detection video capture daemon
Documentation=man:motion(1)

[Service]
User=motion
Group=motion
ExecStart=/usr/bin/motion -c /etc/motion/motion.conf
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

echo "[${GRN}INFO${END}] Enabling and starting motion service..."
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable motion
systemctl restart motion
sleep 2

systemctl restart motion

# Wait up to 5 seconds for motion to become active
for i in {1..5}; do
    if systemctl is-active --quiet motion; then
        IP_ADDRESS=$(hostname -I | awk '{print $1}')
        echo "[${GRN}✓${END}] Motion service is running"
        echo "[${GRN}INFO${END}] Stream:       http://${IP_ADDRESS}:8081"
        echo "[${GRN}INFO${END}] Web control:  http://${IP_ADDRESS}:8080"
        exit 0
    fi
    sleep 1
done

echo "[${RED}✗${END}] Motion failed to start. Check logs:"
echo "    sudo journalctl -u motion -f"