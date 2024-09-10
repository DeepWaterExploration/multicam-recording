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

Install Python Packages
```bash
cd backend/
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
WorkingDirectory=/home/ubuntu/Github/MultiCam-Record
ExecStart=/usr/bin/python3 /home/ubuntu/Github/MultiCam-Record/run.py

[Install]
WantedBy=multi-user.target
```
