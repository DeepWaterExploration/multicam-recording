# MultiCam Recording Software

A multi-camera recording solution for testing purposes and data collection.

## Table of Contents
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Development](#development)
- [Deployment](#deployment)

## Prerequisites

### System Requirements
- Linux-based operating system
- GStreamer 1.0 or higher
- Python 3.6 or higher
- V4L2 compatible cameras

### GStreamer Dependencies

Install the required GStreamer packages:

```bash
sudo apt install -y libx264-dev libjpeg-dev \
    libglib2.0-dev libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
    gstreamer1.0-tools gstreamer1.0-x gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-libav \
    libgstreamer-plugins-bad1.0-dev gstreamer1.0-plugins-ugly \
    gstreamer1.0-gl v4l-utils
```

## Installation

### Automated Installation (Recommended)

The easiest way to install MultiCam is using the automated installer:

```bash
# Download and extract MultiCam
# Then run the installer
./install.sh
```

**Installation Options:**

```bash
# Default installation (to /opt/multicam as current user)
./install.sh

# Install to custom directory
./install.sh -d /home/$USER/multicam

# System-wide installation with dedicated user
./install.sh --system-install

# Custom installation with specific user
./install.sh -d /custom/path -u myuser

# Create a dedicated system user
./install.sh --create-user

# Show help
./install.sh --help
```

The installer will:
- Create the installation directory
- Copy all necessary files
- Set up a Python virtual environment
- Install Python dependencies
- Create configuration files
- Set proper permissions
- Create system symlinks (if possible)

### Manual Installation

If you prefer to install manually:

1. **Update your system:**
   ```bash
   sudo apt update && sudo apt upgrade
   ```

2. **Install Python and pip:**
   ```bash
   sudo apt install python3 python3-pip python3-venv
   ```

3. **Choose installation directory and copy files:**
   ```bash
   sudo mkdir -p /opt/multicam
   sudo cp -r * /opt/multicam/
   sudo chown -R $USER:$USER /opt/multicam
   ```

4. **Set up Python environment:**
   ```bash
   cd /opt/multicam
   python3 -m venv .env
   source .env/bin/activate
   pip install -r requirements.txt
   chmod +x run.sh
   ```

## Development

### Running MultiCam

After installation, you can run MultiCam in several ways:

**If installed with the installer:**
```bash
# From installation directory
cd /opt/multicam  # or your custom directory
./run.sh

# Or using the system symlink (if created)
multicam
```

**For development:**
```bash
# From the source directory
python run.py
# or
./run.sh
```

### Testing the Installation

Test your installation:

```bash
# Check if MultiCam starts without errors
cd /opt/multicam && ./run.sh --test  # if supported
# or
cd /opt/multicam && timeout 10 ./run.sh
```

## Deployment

### System Service Setup

MultiCam can be configured to run as a systemd service that automatically starts on boot.

#### Automated Service Installation (Recommended)

After installing MultiCam, use the service installer to create a systemd service:

```bash
# From the installation directory
cd /opt/multicam  # or your installation directory
sudo ./install_service.sh
```

The service installer will:
- **Auto-detect** your installation (installed vs development mode)
- Create a properly configured systemd service file
- Use the correct paths and user from your installation
- Install it with appropriate permissions
- Enable the service to start on boot
- Optionally start the service immediately

**Service Installer Options:**
```bash
sudo ./install_service.sh           # Install the service
sudo ./install_service.sh --help    # Show help information
sudo ./install_service.sh --uninstall  # Remove the service
```

**Installation Detection:**
- If run from an installed location (with `.install_config`), uses installation settings
- If run from source directory, uses current directory and user
- Automatically configures paths, users, and permissions

#### Manual Installation

If you prefer to set up the service manually:

1. Create a systemd service file at `/etc/systemd/system/multicam.service`:

   ```ini
   [Unit]
   Description=MultiCam Recording Service
   Documentation=https://github.com/your-repo/MultiCam-Record
   After=network.target graphical-session.target
   Wants=network.target

   [Service]
   Type=simple
   User=your-username
   Group=your-username
   WorkingDirectory=/opt/multicam
   ExecStart=/opt/multicam/run.sh
   ExecReload=/bin/kill -HUP $MAINPID
   Restart=always
   RestartSec=10
   TimeoutStartSec=30
   TimeoutStopSec=30

   # Security settings
   NoNewPrivileges=true
   PrivateTmp=true
   ProtectSystem=strict
   ReadWritePaths=/opt/multicam

   # Logging
   StandardOutput=journal
   StandardError=journal
   SyslogIdentifier=multicam

   [Install]
   WantedBy=multi-user.target
   ```

2. Enable and start the service:
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl enable multicam.service
   sudo systemctl start multicam.service
   ```

#### Service Management

Once installed, use these commands to manage the service:

```bash
# Check service status
sudo systemctl status multicam.service

# Start the service
sudo systemctl start multicam.service

# Stop the service
sudo systemctl stop multicam.service

# Restart the service
sudo systemctl restart multicam.service

# View service logs
sudo journalctl -u multicam.service -f

# Disable service (prevent auto-start)
sudo systemctl disable multicam.service
```

## Uninstallation

### Complete Removal

To completely remove MultiCam from your system:

```bash
# If installed using the installer
sudo /opt/multicam/install.sh --uninstall

# Or from the original source directory
sudo ./install.sh --uninstall
```

This will:
- Stop and remove the systemd service
- Remove the installation directory
- Remove system symlinks
- Remove the dedicated user (if created during installation)

### Manual Removal

If you need to remove MultiCam manually:

```bash
# Stop and disable the service
sudo systemctl stop multicam.service
sudo systemctl disable multicam.service
sudo rm /etc/systemd/system/multicam.service
sudo systemctl daemon-reload

# Remove installation directory
sudo rm -rf /opt/multicam

# Remove symlinks
sudo rm -f /usr/local/bin/multicam

# Remove dedicated user (if created)
sudo userdel multicam
```
