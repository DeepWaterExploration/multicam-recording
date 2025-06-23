# MultiCam Recording Software

software developed for testing purposes and data collection


## Pre-requisites

### Gstreamer/V4l2

```bash
sudo apt install -y libx264-dev libjpeg-dev \
libglib2.0-dev libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
gstreamer1.0-tools gstreamer1.0-x gstreamer1.0-plugins-base gstreamer1.0-plugins-good \
gstreamer1.0-plugins-bad gstreamer1.0-libav libgstreamer-plugins-bad1.0-dev \
gstreamer1.0-plugins-ugly gstreamer1.0-gl \
v4l-utils
```

### Python

Install Python
```bash
sudo apt update
sudo apt upgrade
sudo apt install python3 python3-pip
```

Install Repository
```bash
git clone https://github.com/DeepWaterExploration/MultiCam-Record.git/
cd MultiCam-Record
```

Install Python Packages
```bash
pip install -r requirements.txt
```

## Development

### Running Backend

```bash
python run.py # dev mode
```

### Create Services for Booting on Startup

#### MultiCam service

```bash
[Unit]
Description=MultiCam Service
After=network.target

[Service]
User=ubuntu
Group=www-data
WorkingDirectory=path_to_multicam_record/MultiCam-Record/src
ExecStart=/usr/bin/python3 path_to_multicam_record/MultiCam-Record/src/run.py

[Install]
WantedBy=multi-user.target
```

## Installing to NVME Drive
1. run ```sudo raspi-config```,
then navigate to Advanced Options > Boot > Boot Order,
highlight 'NVMe/USB Boot' and press enter, and
follow the prompts
2. clone contents of SD card to NVME drive
```bash
# Install rpi-clone.
git clone https://github.com/geerlingguy/rpi-clone.git
cd rpi-clone
sudo cp rpi-clone rpi-clone-setup /usr/local/sbin

# Clone to the NVMe drive (usually nvme0n1, but check with `lsblk`).
sudo rpi-clone nvme0n1
```
