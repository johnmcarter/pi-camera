# Pi Camera Setup for Raspberry Pi 5

This script configures your **Raspberry Pi 5** as a headless camera streamer using the `motion` daemon and a USB webcam or supported CSI camera module.

---

## ✅ Features

- Automatically installs and configures `motion`
- Enables high-resolution (1080p @ 30fps) MJPEG streaming
- Enables streaming and control from other devices (not just localhost)
- Adds overlay with timestamp and camera name
- Ensures log and video directories exist and have correct permissions
- Runs as a background (daemon) service
- Configures `motion` to run successfully via `systemd`

---

## 🖥️ Live Access

After installation, access your stream and control interface:

- **Stream:** `http://<RaspberryPiIP>:8081`
- **Web Control:** `http://<RaspberryPiIP>:8080`

You can find your IP using:

```bash
hostname -I
```

---

## 📦 Requirements

- Raspberry Pi 5
- Raspberry Pi OS (Bookworm recommended)
- USB Webcam or supported Raspberry Pi camera module
- Internet access for package installation

---

## 🚀 Installation

1. Download and make the script executable:

```bash
chmod +x install-motion.sh
```

2. Run the script as root:

```bash
sudo ./install-motion.sh
```

---

## 🔍 Troubleshooting

- If the stream does not appear at `http://<your-pi-ip>:8081`, run:

```bash
sudo systemctl status motion
sudo journalctl -u motion -f
```

- To test manually in foreground:

```bash
sudo motion -n
```

- To confirm camera is detected:

```bash
v4l2-ctl --list-devices
```

---

## 🧪 Verified On

- **Raspberry Pi 5**
- Raspberry Pi OS Bookworm (64-bit)
- Motion 4.5.1+
- USB UVC-compatible webcam

---

## 📁 Directories

- **Logs:** `/var/log/motion/motion.log`
- **Captured videos:** `/var/lib/motion/`

---

## 🛠️ Customization

You can edit `/etc/motion/motion.conf` directly to change:
- Resolution
- Frame rate
- Text overlays
- Output file formats
- Motion detection sensitivity

After making changes:

```bash
sudo systemctl restart motion
```
