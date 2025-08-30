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
sudo apt install python3
```

Install Repository
```bash
git clone https://github.com/DeepWaterExploration/MultiCam-Record.git/
cd MultiCam-Record
```

Create Python Virtual Environment
```bash
python -m venv .env
```

Activate Python Virtual Environment
```bash
source .env/bin/activate
```

Install Python Packages
```bash
pip install -r requirements.txt
```

## Development

### Running Program

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
ExecStart=path_to_multicam_record/MultiCam-Record/.env/bin/python3 path_to_multicam_record/MultiCam-Record/src/run.py

[Install]
WantedBy=multi-user.target
```
