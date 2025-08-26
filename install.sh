#!/bin/bash

# MultiCam Recording Software Installer
# This script installs the MultiCam software to a predictable location

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default configuration
DEFAULT_INSTALL_DIR="/opt/multicam"
DEFAULT_USER="multicam"
CREATE_USER=false
INSTALL_DIR=""
INSTALL_USER=""

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

print_question() {
    echo -e "${BLUE}[QUESTION]${NC} $1"
}

# Show help
show_help() {
    echo "MultiCam Recording Software Installer"
    echo "======================================"
    echo
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  -d, --dir DIR          Installation directory (default: $DEFAULT_INSTALL_DIR)"
    echo "  -u, --user USER        User to run the service (default: current user)"
    echo "  --create-user          Create a dedicated system user for the service"
    echo "  --system-install       Install system-wide with dedicated user (same as --create-user -d $DEFAULT_INSTALL_DIR)"
    echo "  -h, --help            Show this help message"
    echo
    echo "Examples:"
    echo "  $0                                    # Install to $DEFAULT_INSTALL_DIR as current user"
    echo "  $0 -d /home/\$USER/multicam          # Install to user's home directory"
    echo "  $0 --system-install                  # System-wide installation with dedicated user"
    echo "  $0 -d /custom/path -u myuser         # Custom directory and user"
    echo
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -d|--dir)
                INSTALL_DIR="$2"
                shift 2
                ;;
            -u|--user)
                INSTALL_USER="$2"
                shift 2
                ;;
            --create-user)
                CREATE_USER=true
                shift
                ;;
            --system-install)
                INSTALL_DIR="$DEFAULT_INSTALL_DIR"
                INSTALL_USER="$DEFAULT_USER"
                CREATE_USER=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Set defaults if not specified
    if [[ -z "$INSTALL_DIR" ]]; then
        INSTALL_DIR="$DEFAULT_INSTALL_DIR"
    fi
    
    if [[ -z "$INSTALL_USER" ]]; then
        if [[ "$CREATE_USER" == true ]]; then
            INSTALL_USER="$DEFAULT_USER"
        else
            INSTALL_USER="$(whoami)"
        fi
    fi
}

# Check if running as root when needed
check_permissions() {
    local needs_root=false
    
    # Check if we need root for directory creation
    local parent_dir=$(dirname "$INSTALL_DIR")
    if [[ ! -w "$parent_dir" ]] && [[ ! -d "$INSTALL_DIR" ]]; then
        needs_root=true
    fi
    
    # Check if we need root for user creation
    if [[ "$CREATE_USER" == true ]]; then
        needs_root=true
    fi
    
    if [[ "$needs_root" == true ]] && [[ $EUID -ne 0 ]]; then
        print_error "This installation requires root privileges."
        print_status "Please run with sudo: sudo $0 $*"
        exit 1
    fi
}

# Create system user if requested
create_system_user() {
    if [[ "$CREATE_USER" == true ]]; then
        if id "$INSTALL_USER" &>/dev/null; then
            print_status "User '$INSTALL_USER' already exists."
        else
            print_status "Creating system user '$INSTALL_USER'..."
            useradd --system --home "$INSTALL_DIR" --shell /bin/bash \
                    --comment "MultiCam Recording Service" "$INSTALL_USER"
        fi
    fi
}

# Create installation directory
create_install_dir() {
    print_status "Creating installation directory: $INSTALL_DIR"
    
    if [[ ! -d "$INSTALL_DIR" ]]; then
        mkdir -p "$INSTALL_DIR"
    fi
    
    # Set ownership
    if [[ "$CREATE_USER" == true ]] || [[ "$(whoami)" != "$INSTALL_USER" ]]; then
        chown -R "$INSTALL_USER:$INSTALL_USER" "$INSTALL_DIR"
    fi
    
    chmod 755 "$INSTALL_DIR"
}

# Copy files to installation directory
install_files() {
    print_status "Installing MultiCam files..."
    
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # Files and directories to copy
    local items_to_copy=(
        "src/"
        "run.py"
        "run.sh"
        "requirements.txt"
        "README.md"
    )
    
    for item in "${items_to_copy[@]}"; do
        if [[ -e "$script_dir/$item" ]]; then
            print_status "Copying $item..."
            cp -r "$script_dir/$item" "$INSTALL_DIR/"
        else
            print_warning "Item not found: $item (skipping)"
        fi
    done
    
    # Make run.sh executable
    chmod +x "$INSTALL_DIR/run.sh"
    
    # Set ownership
    if [[ "$CREATE_USER" == true ]] || [[ "$(whoami)" != "$INSTALL_USER" ]]; then
        chown -R "$INSTALL_USER:$INSTALL_USER" "$INSTALL_DIR"
    fi
}

# Create Python virtual environment
setup_python_env() {
    print_status "Setting up Python virtual environment..."
    
    local venv_dir="$INSTALL_DIR/.env"
    
    # Create virtual environment as the target user
    if [[ "$(whoami)" == "$INSTALL_USER" ]]; then
        python3 -m venv "$venv_dir"
    else
        sudo -u "$INSTALL_USER" python3 -m venv "$venv_dir"
    fi
    
    # Install requirements
    print_status "Installing Python dependencies..."
    if [[ -f "$INSTALL_DIR/requirements.txt" ]]; then
        if [[ "$(whoami)" == "$INSTALL_USER" ]]; then
            "$venv_dir/bin/pip" install -r "$INSTALL_DIR/requirements.txt"
        else
            sudo -u "$INSTALL_USER" "$venv_dir/bin/pip" install -r "$INSTALL_DIR/requirements.txt"
        fi
    else
        print_warning "requirements.txt not found, skipping Python dependencies installation"
    fi
}

# Create configuration file with installation paths
create_config() {
    print_status "Creating installation configuration..."
    
    local config_file="$INSTALL_DIR/.install_config"
    
    cat > "$config_file" << EOF
# MultiCam Installation Configuration
# This file is generated automatically by the installer

INSTALL_DIR="$INSTALL_DIR"
INSTALL_USER="$INSTALL_USER"
PYTHON_VENV="$INSTALL_DIR/.env"
CREATED_USER="$CREATE_USER"
INSTALL_DATE="$(date)"
EOF
    
    chmod 644 "$config_file"
    if [[ "$(whoami)" != "$INSTALL_USER" ]]; then
        chown "$INSTALL_USER:$INSTALL_USER" "$config_file"
    fi
}

# Create symlinks for easy access
create_symlinks() {
    print_status "Creating system symlinks..."
    
    # Create symlink to main script
    if [[ -w "/usr/local/bin" ]]; then
        ln -sf "$INSTALL_DIR/run.py" "/usr/local/bin/multicam"
        chmod +x "/usr/local/bin/multicam"
        print_status "Created symlink: /usr/local/bin/multicam"
    else
        print_warning "Cannot create symlink in /usr/local/bin (no write access)"
    fi
}

# Show installation summary
show_summary() {
    echo
    print_status "Installation Summary:"
    echo "  Installation directory: $INSTALL_DIR"
    echo "  Service user: $INSTALL_USER"
    echo "  Python virtual env: $INSTALL_DIR/.env"
    if [[ "$CREATE_USER" == true ]]; then
        echo "  Created system user: Yes"
    else
        echo "  Created system user: No"
    fi
    echo
    
    print_status "Next Steps:"
    echo "  1. Test the installation:"
    echo "     cd $INSTALL_DIR && ./run.sh"
    echo
    echo "  2. Install as a system service:"
    echo "     cd $INSTALL_DIR && sudo ./install_service.sh"
    echo
    
    if [[ -L "/usr/local/bin/multicam" ]]; then
        echo "  3. Or run from anywhere using:"
        echo "     multicam"
        echo
    fi
    
    print_status "Installation completed successfully!"
}

# Uninstall function
uninstall() {
    if [[ "$1" == "--uninstall" ]]; then
        print_warning "Uninstalling MultiCam Recording Software..."
        
        # Read configuration if it exists
        local config_file="$INSTALL_DIR/.install_config"
        if [[ -f "$config_file" ]]; then
            source "$config_file"
        fi
        
        # Stop and remove service if it exists
        if systemctl is-enabled multicam.service &>/dev/null; then
            print_status "Stopping and disabling service..."
            systemctl stop multicam.service 2>/dev/null || true
            systemctl disable multicam.service 2>/dev/null || true
            rm -f /etc/systemd/system/multicam.service
            systemctl daemon-reload
        fi
        
        # Remove symlinks
        if [[ -L "/usr/local/bin/multicam" ]]; then
            rm -f "/usr/local/bin/multicam"
            print_status "Removed symlink: /usr/local/bin/multicam"
        fi
        
        # Remove installation directory
        if [[ -d "$INSTALL_DIR" ]]; then
            rm -rf "$INSTALL_DIR"
            print_status "Removed installation directory: $INSTALL_DIR"
        fi
        
        # Remove user if we created it
        if [[ -f "$config_file" ]] && [[ "$CREATED_USER" == "true" ]]; then
            if id "$INSTALL_USER" &>/dev/null; then
                userdel "$INSTALL_USER" 2>/dev/null || true
                print_status "Removed system user: $INSTALL_USER"
            fi
        fi
        
        print_status "Uninstallation completed!"
        exit 0
    fi
}

# Main installation function
main() {
    echo "MultiCam Recording Software Installer"
    echo "======================================"
    echo
    
    # Handle uninstall
    uninstall "$1"
    
    # Parse arguments
    parse_args "$@"
    
    # Check permissions
    check_permissions "$@"
    
    # Show configuration
    print_status "Installation Configuration:"
    echo "  Installation directory: $INSTALL_DIR"
    echo "  Service user: $INSTALL_USER"
    echo "  Create system user: $CREATE_USER"
    echo
    
    # Confirm installation
    read -p "Do you want to proceed with the installation? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Installation cancelled."
        exit 0
    fi
    
    # Perform installation steps
    create_system_user
    create_install_dir
    install_files
    setup_python_env
    create_config
    create_symlinks
    show_summary
}

# Run main function with all arguments
main "$@"