#!/bin/bash

# MultiCam Recording Service Installation Script
# This script creates and installs a systemd service for MultiCam Recording Software

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
SERVICE_NAME="multicam"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"

# Detect installation directory and configuration
detect_installation() {
    local config_file
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # Check if we're in an installed location
    if [[ -f "$script_dir/.install_config" ]]; then
        # We're in an installed directory, load config
        source "$script_dir/.install_config"
        SCRIPT_DIR="$INSTALL_DIR"
        INSTALL_USER_CONFIG="$INSTALL_USER"
    else
        # We're in development directory, use current location
        SCRIPT_DIR="$script_dir"
        INSTALL_USER_CONFIG="$(whoami)"
    fi
    
    RUN_SCRIPT="${SCRIPT_DIR}/run.sh"
}

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should not be run as root directly."
        print_status "Please run as a regular user. The script will prompt for sudo when needed."
        exit 1
    fi
}

# Check if systemd is available
check_systemd() {
    if ! command -v systemctl &> /dev/null; then
        print_error "systemctl not found. This system doesn't appear to use systemd."
        exit 1
    fi
}

# Check if run.sh exists and is executable
check_run_script() {
    if [[ ! -f "$RUN_SCRIPT" ]]; then
        print_error "run.sh not found in $SCRIPT_DIR"
        print_status "Please make sure you're running this script from the MultiCam project directory."
        exit 1
    fi
    
    if [[ ! -x "$RUN_SCRIPT" ]]; then
        print_warning "run.sh is not executable. Making it executable..."
        chmod +x "$RUN_SCRIPT"
    fi
}

# Create the systemd service file content
create_service_content() {
    local service_user="$INSTALL_USER_CONFIG"
    
    cat << EOF
[Unit]
Description=MultiCam Recording Service
Documentation=https://github.com/your-repo/MultiCam-Record
After=network.target graphical-session.target
Wants=network.target

[Service]
Type=simple
User=$service_user
Group=$service_user
WorkingDirectory=$SCRIPT_DIR
ExecStart=$RUN_SCRIPT
ExecReload=/bin/kill -HUP \$MAINPID
Restart=always
RestartSec=10
TimeoutStartSec=30
TimeoutStopSec=30

# Environment
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
Environment=HOME=/home/$service_user

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ReadWritePaths=$SCRIPT_DIR

# Logging
StandardOutput=journal
StandardError=journal
SyslogIdentifier=multicam

[Install]
WantedBy=multi-user.target
EOF
}

# Install the service
install_service() {
    print_status "Creating systemd service file..."
    
    # Create temporary file with service content
    local temp_service=$(mktemp)
    create_service_content > "$temp_service"
    
    # Copy to systemd directory (requires sudo)
    print_status "Installing service file (requires sudo)..."
    sudo cp "$temp_service" "$SERVICE_FILE"
    sudo chmod 644 "$SERVICE_FILE"
    sudo chown root:root "$SERVICE_FILE"
    
    # Clean up temp file
    rm "$temp_service"
    
    print_status "Reloading systemd daemon..."
    sudo systemctl daemon-reload
    
    print_status "Service installed successfully!"
}

# Enable and start service
enable_service() {
    print_status "Enabling ${SERVICE_NAME} service..."
    sudo systemctl enable "$SERVICE_NAME.service"
    
    echo
    read -p "Do you want to start the service now? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Starting ${SERVICE_NAME} service..."
        sudo systemctl start "$SERVICE_NAME.service"
        
        # Check status
        sleep 2
        if sudo systemctl is-active --quiet "$SERVICE_NAME.service"; then
            print_status "Service started successfully!"
        else
            print_error "Service failed to start. Checking status..."
            sudo systemctl status "$SERVICE_NAME.service"
        fi
    else
        print_status "Service enabled but not started."
        print_status "You can start it manually with: sudo systemctl start ${SERVICE_NAME}.service"
    fi
}

# Show service management commands
show_commands() {
    echo
    print_status "Service Management Commands:"
    echo "  Start service:    sudo systemctl start ${SERVICE_NAME}.service"
    echo "  Stop service:     sudo systemctl stop ${SERVICE_NAME}.service"
    echo "  Restart service:  sudo systemctl restart ${SERVICE_NAME}.service"
    echo "  Check status:     sudo systemctl status ${SERVICE_NAME}.service"
    echo "  View logs:        sudo journalctl -u ${SERVICE_NAME}.service -f"
    echo "  Disable service:  sudo systemctl disable ${SERVICE_NAME}.service"
    echo
}

# Uninstall service (if requested)
uninstall_service() {
    if [[ "$1" == "--uninstall" ]]; then
        print_warning "Uninstalling ${SERVICE_NAME} service..."
        
        # Stop and disable service
        sudo systemctl stop "$SERVICE_NAME.service" 2>/dev/null || true
        sudo systemctl disable "$SERVICE_NAME.service" 2>/dev/null || true
        
        # Remove service file
        sudo rm -f "$SERVICE_FILE"
        sudo systemctl daemon-reload
        
        print_status "Service uninstalled successfully!"
        exit 0
    fi
}

# Main function
main() {
    echo "MultiCam Recording Service Installer"
    echo "======================================"
    echo
    
    # Handle uninstall
    uninstall_service "$1"
    
    # Show help
    if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
        echo "Usage: $0 [OPTIONS]"
        echo
        echo "Options:"
        echo "  --help, -h     Show this help message"
        echo "  --uninstall    Uninstall the service"
        echo
        echo "This script will:"
        echo "  1. Auto-detect MultiCam installation (installed vs development)"
        echo "  2. Create a systemd service file for MultiCam Recording"
        echo "  3. Install it to /etc/systemd/system/"
        echo "  4. Enable the service to start on boot"
        echo "  5. Optionally start the service immediately"
        echo
        exit 0
    fi
    
    # Detect installation
    detect_installation
    
    # Run checks
    check_root
    check_systemd
    check_run_script
    
    # Show current configuration
    print_status "Configuration:"
    echo "  Service name: ${SERVICE_NAME}"
    echo "  Working directory: ${SCRIPT_DIR}"
    echo "  Executable: ${RUN_SCRIPT}"
    echo "  Service user: ${INSTALL_USER_CONFIG}"
    if [[ -f "${SCRIPT_DIR}/.install_config" ]]; then
        echo "  Installation type: Installed"
    else
        echo "  Installation type: Development"
    fi
    echo
    
    # Confirm installation
    read -p "Do you want to proceed with the installation? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Installation cancelled."
        exit 0
    fi
    
    # Install and enable service
    install_service
    enable_service
    show_commands
    
    print_status "Installation complete!"
}

# Run main function with all arguments
main "$@"