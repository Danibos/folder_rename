#!/bin/bash

###############################################################################
# Movie Folder Renamer - Setup Script for macOS and Linux
# 
# This script:
# 1. Checks system compatibility (macOS or Linux)
# 2. Verifies/installs Python 3.8+
# 3. Creates a virtual environment
# 4. Installs all dependencies
# 5. Creates an executable application launcher
# 6. Sets up desktop entry (Linux) or app bundle (macOS)
###############################################################################

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Utility functions
print_header() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS_TYPE="linux"
        OS_NAME=$(lsb_release -si 2>/dev/null || echo "Linux")
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS_TYPE="macos"
        OS_NAME="macOS"
    else
        print_error "Unsupported operating system: $OSTYPE"
        exit 1
    fi
    print_success "Detected OS: $OS_NAME"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install Python 3
install_python() {
    print_header "Installing Python 3"
    
    if command_exists python3; then
        PYTHON_VERSION=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
        print_success "Python 3 is already installed: $PYTHON_VERSION"
        return 0
    fi
    
    if [[ "$OS_TYPE" == "macos" ]]; then
        if command_exists brew; then
            print_info "Installing Python 3 via Homebrew..."
            brew install python3
        else
            print_error "Homebrew not found. Please install Homebrew from https://brew.sh"
            exit 1
        fi
    elif [[ "$OS_TYPE" == "linux" ]]; then
        print_info "Installing Python 3 via system package manager..."
        if command_exists apt-get; then
            sudo apt-get update
            sudo apt-get install -y python3 python3-venv python3-dev
        elif command_exists dnf; then
            sudo dnf install -y python3 python3-venv python3-devel
        elif command_exists yum; then
            sudo yum install -y python3 python3-venv python3-devel
        elif command_exists pacman; then
            sudo pacman -S --noconfirm python
        else
            print_error "Unsupported package manager. Please install Python 3 manually."
            exit 1
        fi
    fi
    
    print_success "Python 3 installation complete"
}

# Install required system dependencies
install_system_dependencies() {
    print_header "Installing System Dependencies"
    
    if [[ "$OS_TYPE" == "macos" ]]; then
        if ! command_exists brew; then
            print_error "Homebrew not found. Please install from https://brew.sh"
            exit 1
        fi
        print_info "Installing macOS dependencies via Homebrew..."
        brew install qt6 libxkbcommon
        print_success "macOS dependencies installed"
    elif [[ "$OS_TYPE" == "linux" ]]; then
        print_info "Installing Linux dependencies..."
        if command_exists apt-get; then
            sudo apt-get update
            sudo apt-get install -y \
                libqt6gui6 libqt6core6 libqt6widgets6 \
                libxkbcommon0 libdbus-1-3 \
                libfontconfig1 libfreetype6
        elif command_exists dnf; then
            sudo dnf install -y \
                qt6-qtbase qt6-qtbase-gui \
                libxkbcommon dbus libfontconfig freetype
        elif command_exists yum; then
            sudo yum install -y \
                qt6-qtbase qt6-qtbase-gui \
                libxkbcommon dbus libfontconfig freetype
        elif command_exists pacman; then
            sudo pacman -S --noconfirm qt6-base libxkbcommon
        fi
        print_success "Linux dependencies installed"
    fi
}

# Create virtual environment
create_venv() {
    print_header "Creating Virtual Environment"
    
    VENV_DIR="venv"
    
    if [ -d "$VENV_DIR" ]; then
        print_info "Virtual environment already exists at $VENV_DIR"
        return 0
    fi
    
    print_info "Creating virtual environment..."
    python3 -m venv "$VENV_DIR"
    print_success "Virtual environment created"
}

# Activate virtual environment
activate_venv() {
    VENV_DIR="venv"
    if [[ "$OS_TYPE" == "macos" ]]; then
        source "$VENV_DIR/bin/activate"
    else
        source "$VENV_DIR/bin/activate"
    fi
    print_success "Virtual environment activated"
}

# Install Python dependencies
install_dependencies() {
    print_header "Installing Python Dependencies"
    
    if [ ! -f "requirements.txt" ]; then
        print_error "requirements.txt not found"
        exit 1
    fi
    
    print_info "Upgrading pip..."
    pip install --upgrade pip setuptools wheel
    
    print_info "Installing dependencies from requirements.txt..."
    pip install -r requirements.txt
    
    print_success "Dependencies installed successfully"
}

# Create standalone executable wrapper script
create_wrapper_script() {
    print_header "Creating Application Wrapper Script"
    
    SCRIPT_NAME="movie-folder-renamer"
    
    if [[ "$OS_TYPE" == "macos" ]]; then
        WRAPPER_PATH="/usr/local/bin/$SCRIPT_NAME"
    else
        WRAPPER_PATH="$HOME/.local/bin/$SCRIPT_NAME"
    fi
    
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    VENV_PATH="$SCRIPT_DIR/venv"
    PYTHON_PATH="$VENV_PATH/bin/python3"
    GUI_SCRIPT="$SCRIPT_DIR/gui_app.py"
    
    # Create the wrapper script
    cat > "$SCRIPT_NAME" << 'EOF'
#!/bin/bash
# Movie Folder Renamer - Application Launcher
# This script activates the virtual environment and runs the GUI

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_PATH="$SCRIPT_DIR/venv"

if [ ! -d "$VENV_PATH" ]; then
    echo "Error: Virtual environment not found at $VENV_PATH"
    echo "Please run ./setup.sh first"
    exit 1
fi

source "$VENV_PATH/bin/activate"
python3 "$SCRIPT_DIR/gui_app.py" "$@"
EOF
    
    chmod +x "$SCRIPT_NAME"
    print_success "Wrapper script created: $SCRIPT_NAME"
}

# Create macOS app bundle
create_macos_app() {
    print_header "Creating macOS Application Bundle"
    
    APP_NAME="Movie Folder Renamer"
    APP_BUNDLE="$APP_NAME.app"
    CONTENTS_DIR="$APP_BUNDLE/Contents"
    MACOS_DIR="$CONTENTS_DIR/MacOS"
    RESOURCES_DIR="$CONTENTS_DIR/Resources"
    
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # Create directory structure
    mkdir -p "$MACOS_DIR"
    mkdir -p "$RESOURCES_DIR"
    
    # Create launcher script
    cat > "$MACOS_DIR/launcher.sh" << 'EOF'
#!/bin/bash
APP_BUNDLE="$(cd "$(dirname "$0")/.." && pwd)"
VENV_PATH="$(dirname "$APP_BUNDLE")/../../venv"
SCRIPT_DIR="$(dirname "$APP_BUNDLE")/../../"

if [ ! -d "$VENV_PATH" ]; then
    VENV_PATH="$SCRIPT_DIR/venv"
fi

if [ ! -d "$VENV_PATH" ]; then
    open -a "System Events" -e 'display notification "Virtual environment not found. Please run setup.sh first." with title "Movie Folder Renamer Error"'
    exit 1
fi

source "$VENV_PATH/bin/activate"
cd "$SCRIPT_DIR"
python3 gui_app.py "$@"
EOF
    
    chmod +x "$MACOS_DIR/launcher.sh"
    
    # Create Info.plist
    cat > "$CONTENTS_DIR/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>es_ES</string>
    <key>CFBundleExecutable</key>
    <string>launcher.sh</string>
    <key>CFBundleIdentifier</key>
    <string>com.danibos.moviefolderrenamer</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Movie Folder Renamer</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.13</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2026 Daniele Bosco. MIT License.</string>
    <key>NSRequiresIPhoneOS</key>
    <false/>
</dict>
</plist>
EOF
    
    print_success "macOS app bundle created: $APP_BUNDLE"
    print_info "You can now find the app in Finder and move it to Applications folder"
}

# Create Linux desktop entry
create_linux_desktop_entry() {
    print_header "Creating Linux Desktop Entry"
    
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    DESKTOP_DIR="$HOME/.local/share/applications"
    DESKTOP_FILE="$DESKTOP_DIR/movie-folder-renamer.desktop"
    
    mkdir -p "$DESKTOP_DIR"
    
    # Create icon directory
    ICON_DIR="$HOME/.local/share/icons/hicolor/256x256/apps"
    mkdir -p "$ICON_DIR"
    
    # Create desktop entry
    cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Movie Folder Renamer
Comment=Rename your movie folders with director and year information
Icon=movie-folder-renamer
Exec=$SCRIPT_DIR/movie-folder-renamer
Categories=Utility;
Terminal=false
StartupNotify=true
X-AppImage-Version=1.0.0
EOF
    
    chmod +x "$DESKTOP_FILE"
    
    # Create a simple SVG icon
    cat > "$ICON_DIR/movie-folder-renamer.svg" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 256 256">
  <rect width="256" height="256" fill="#1E88E5" rx="32"/>
  <text x="128" y="140" font-size="80" font-weight="bold" text-anchor="middle" fill="white" font-family="Arial">🎬</text>
  <text x="128" y="200" font-size="24" font-weight="bold" text-anchor="middle" fill="white" font-family="Arial">Renamer</text>
</svg>
EOF
    
    print_success "Desktop entry created: $DESKTOP_FILE"
    print_info "Application will appear in your application menu"
}

# Create executable wrapper for Linux
create_linux_executable() {
    print_header "Creating Linux Executable"
    
    BIN_DIR="$HOME/.local/bin"
    mkdir -p "$BIN_DIR"
    
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    EXECUTABLE="$BIN_DIR/movie-folder-renamer"
    
    cat > "$EXECUTABLE" << 'EOF'
#!/bin/bash
# Movie Folder Renamer - Linux Executable
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")"/.. && pwd)"
VENV_PATH="$SCRIPT_DIR/venv"

if [ ! -d "$VENV_PATH" ]; then
    # Try to find venv in common locations
    if [ -d "$HOME/movie_folder_renamer/venv" ]; then
        VENV_PATH="$HOME/movie_folder_renamer/venv"
    else
        notify-send -u critical "Movie Folder Renamer Error" "Virtual environment not found. Please run setup.sh first."
        exit 1
    fi
fi

source "$VENV_PATH/bin/activate"
cd "$SCRIPT_DIR"
python3 gui_app.py "$@"
EOF
    
    chmod +x "$EXECUTABLE"
    
    print_success "Linux executable created: $EXECUTABLE"
    print_info "You can now run: movie-folder-renamer"
}

# Main setup flow
main() {
    print_header "🎬 Movie Folder Renamer - Setup Script"
    
    # Step 1: Detect OS
    detect_os
    
    # Step 2: Install Python
    install_python
    
    # Step 3: Install system dependencies
    install_system_dependencies
    
    # Step 4: Create virtual environment
    create_venv
    
    # Step 5: Activate and install Python dependencies
    activate_venv
    install_dependencies
    
    # Step 6: Create application launchers
    create_wrapper_script
    
    if [[ "$OS_TYPE" == "macos" ]]; then
        create_macos_app
    elif [[ "$OS_TYPE" == "linux" ]]; then
        create_linux_desktop_entry
        create_linux_executable
    fi
    
    print_header "✅ Setup Complete!"
    
    echo ""
    if [[ "$OS_TYPE" == "macos" ]]; then
        print_success "Your macOS app is ready!"
        echo ""
        echo "You can now:"
        echo "  1. Open the app from current directory:"
        echo "     open Movie\\ Folder\\ Renamer.app"
        echo ""
        echo "  2. Move the app to Applications:"
        echo "     mv 'Movie Folder Renamer.app' ~/Applications/"
        echo ""
    elif [[ "$OS_TYPE" == "linux" ]]; then
        print_success "Your Linux app is ready!"
        echo ""
        echo "You can now:"
        echo "  1. Run from terminal:"
        echo "     movie-folder-renamer"
        echo ""
        echo "  2. Launch from application menu"
        echo ""
    fi
    
    echo "First time setup:"
    echo "  1. Launch the application"
    echo "  2. Get your TMDB API key from https://www.themoviedb.org/settings/api"
    echo "  3. Enter your API key in the application"
    echo "  4. Select your movie folder"
    echo "  5. Click 'Iniciar procesamiento'"
    echo ""
    print_success "Setup completed successfully!"
}

# Run main setup
main
