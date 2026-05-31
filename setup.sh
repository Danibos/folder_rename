#!/bin/bash

###############################################################################
# Movie Folder Renamer - Setup Script for macOS and Linux
#
# This script:
# 1. Checks system compatibility (macOS or Linux)
# 2. Verifies/installs Python 3.8+
# 3. On macOS: detects architecture, installs Xcode (via xcodes) if needed
# 4. Installs system Qt6 dependencies
# 5. Creates a virtual environment and installs Python dependencies
# 6. Creates an executable application launcher
# 7. Sets up desktop entry (Linux) or app bundle (macOS)
###############################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ─── Utility functions ────────────────────────────────────────────────────────

print_header() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_success() { echo -e "  ${GREEN}✓ $1${NC}"; }
print_error()   { echo -e "  ${RED}✗ $1${NC}"; }
print_info()    { echo -e "  ${YELLOW}ℹ $1${NC}"; }

command_exists() { command -v "$1" >/dev/null 2>&1; }

# ─── Detect OS ────────────────────────────────────────────────────────────────

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

# ─── Detect macOS version + architecture ─────────────────────────────────────

detect_macos_info() {
    MACOS_VERSION=$(sw_vers -productVersion)
    MACOS_MAJOR=$(echo "$MACOS_VERSION" | cut -d. -f1)
    MACOS_MINOR=$(echo "$MACOS_VERSION" | cut -d. -f2)
    MACOS_PATCH=$(echo "$MACOS_VERSION" | cut -d. -f3)
    MACOS_PATCH=${MACOS_PATCH:-0}

    case "$MACOS_MAJOR" in
        15) MACOS_NAME="Sequoia" ;;
        14) MACOS_NAME="Sonoma" ;;
        13) MACOS_NAME="Ventura" ;;
        12) MACOS_NAME="Monterey" ;;
        11) MACOS_NAME="Big Sur" ;;
        26) MACOS_NAME="Tahoe" ;;
        *)  MACOS_NAME="macOS $MACOS_MAJOR" ;;
    esac

    ARCH=$(uname -m)
    if [[ "$ARCH" == "arm64" ]]; then
        ARCH_LABEL="Apple silicon"
        ARCH_SUFFIX="Apple_silicon"
    else
        ARCH_LABEL="Intel (x86_64)"
        ARCH_SUFFIX="Intel"
    fi

    print_success "macOS $MACOS_NAME $MACOS_VERSION ($ARCH_LABEL)"
}

# ─── Version comparator: returns 0 if $1 >= $2 ───────────────────────────────

version_ge() {
    local IFS=.
    local v1=($1) v2=($2)
    for i in 0 1 2; do
        local a=${v1[$i]:-0}
        local b=${v2[$i]:-0}
        if (( a > b )); then return 0; fi
        if (( a < b )); then return 1; fi
    done
    return 0
}

# ─── Xcode compatibility table (Apple docs, updated May 2026) ────────────────
# Format: "xcodes_version|min_macos|path_arm|path_intel"

build_xcode_compat_table() {
    XCODE_COMPAT_TABLE=(
        # Xcode 26.x — macOS Sequoia 15.6+ or Tahoe
        "26.3|15.6.0|/Developer_Tools/Xcode_26.3/Xcode_26.3_Apple_silicon.xip|/Developer_Tools/Xcode_26.3/Xcode_26.3.xip"
        "26.2|15.6.0|/Developer_Tools/Xcode_26.2/Xcode_26.2_Apple_silicon.xip|/Developer_Tools/Xcode_26.2/Xcode_26.2.xip"
        # Xcode 16.x — macOS Sonoma 14.5+
        "16.4|14.5.0|/Developer_Tools/Xcode_16.4/Xcode_16.4_Apple_silicon.xip|/Developer_Tools/Xcode_16.4/Xcode_16.4.xip"
        "16.3|15.2.0|/Developer_Tools/Xcode_16.3/Xcode_16.3_Apple_silicon.xip|/Developer_Tools/Xcode_16.3/Xcode_16.3.xip"
        "16.2|14.5.0|/Developer_Tools/Xcode_16.2/Xcode_16.2_Apple_silicon.xip|/Developer_Tools/Xcode_16.2/Xcode_16.2.xip"
        "16.1|14.5.0|/Developer_Tools/Xcode_16.1/Xcode_16.1_Apple_silicon.xip|/Developer_Tools/Xcode_16.1/Xcode_16.1.xip"
        "16.0|14.5.0|/Developer_Tools/Xcode_16/Xcode_16_Apple_silicon.xip|/Developer_Tools/Xcode_16/Xcode_16.xip"
        # Xcode 15.x — macOS Ventura 13.5+
        "15.4|14.0.0|/Developer_Tools/Xcode_15.4/Xcode_15.4_Apple_silicon.xip|/Developer_Tools/Xcode_15.4/Xcode_15.4.xip"
        "15.2|13.5.0|/Developer_Tools/Xcode_15.2/Xcode_15.2_Apple_silicon.xip|/Developer_Tools/Xcode_15.2/Xcode_15.2.xip"
        "15.0|13.5.0|/Developer_Tools/Xcode_15/Xcode_15_Apple_silicon.xip|/Developer_Tools/Xcode_15/Xcode_15.xip"
        # Xcode 14.x — macOS Monterey 12.5+
        "14.3|13.0.0|/Developer_Tools/Xcode_14.3.1/Xcode_14.3.1_Apple_silicon.xip|/Developer_Tools/Xcode_14.3.1/Xcode_14.3.1.xip"
        "14.2|12.5.0|/Developer_Tools/Xcode_14.2/Xcode_14.2_Apple_silicon.xip|/Developer_Tools/Xcode_14.2/Xcode_14.2.xip"
    )
}

select_best_xcode() {
    SELECTED_XCODE=""
    SELECTED_XCODE_PATH=""

    for entry in "${XCODE_COMPAT_TABLE[@]}"; do
        IFS='|' read -r xver min_macos path_arm path_intel <<< "$entry"
        if version_ge "$MACOS_VERSION" "$min_macos"; then
            SELECTED_XCODE="$xver"
            if [[ "$ARCH_SUFFIX" == "Apple_silicon" ]]; then
                SELECTED_XCODE_PATH="$path_arm"
            else
                SELECTED_XCODE_PATH="$path_intel"
            fi
            break
        fi
    done
}

# ─── Ensure xcodes CLI is available ──────────────────────────────────────────
# Downloads the prebuilt universal binary from GitHub Releases — no Xcode,
# no CLT, no compilation required. Works on Intel and Apple silicon.

XCODES_VERSION="1.6.2"
XCODES_INSTALL_DIR="$HOME/.local/bin"
XCODES_BIN="$XCODES_INSTALL_DIR/xcodes"
XCODES_DOWNLOAD_URL="https://github.com/XcodesOrg/xcodes/releases/download/${XCODES_VERSION}/xcodes.zip"

ensure_xcodes_cli() {
    # Already on PATH?
    if command_exists xcodes; then
        print_success "xcodes already on PATH: $(xcodes version 2>/dev/null || echo 'ok')"
        return 0
    fi

    # Already downloaded to our install dir but not on PATH?
    if [[ -x "$XCODES_BIN" ]]; then
        export PATH="$XCODES_INSTALL_DIR:$PATH"
        print_success "xcodes found at $XCODES_BIN"
        return 0
    fi

    print_info "Downloading xcodes ${XCODES_VERSION} prebuilt binary (no compilation needed)..."
    mkdir -p "$XCODES_INSTALL_DIR"

    local tmp_zip
    tmp_zip=$(mktemp /tmp/xcodes_XXXXXX.zip)

    curl -L --progress-bar \
        -H "Accept: application/octet-stream" \
        -o "$tmp_zip" \
        "$XCODES_DOWNLOAD_URL"

    if [[ $? -ne 0 ]] || [[ $(wc -c < "$tmp_zip") -lt 10000 ]]; then
        rm -f "$tmp_zip"
        print_error "Failed to download xcodes binary. Check your internet connection."
        print_error "Manual install: https://github.com/XcodesOrg/xcodes/releases"
        exit 1
    fi

    print_info "Extracting xcodes..."
    unzip -q "$tmp_zip" -d "$XCODES_INSTALL_DIR"
    rm -f "$tmp_zip"

    chmod +x "$XCODES_BIN"
    export PATH="$XCODES_INSTALL_DIR:$PATH"

    print_success "xcodes ${XCODES_VERSION} installed to $XCODES_BIN"
}

# ─── Install or verify Xcode.app ─────────────────────────────────────────────

install_xcode_macos() {
    print_header "🔨 Checking Xcode.app"

    detect_macos_info
    build_xcode_compat_table
    select_best_xcode

    if [[ -z "$SELECTED_XCODE" ]]; then
        print_error "No compatible Xcode version found for $MACOS_NAME $MACOS_VERSION."
        print_error "Please upgrade macOS and re-run this script."
        exit 1
    fi

    print_info "Best compatible Xcode: $SELECTED_XCODE ($ARCH_LABEL)"

    # Check if Xcode.app is already installed and has the right version
    if [[ -d "/Applications/Xcode.app" ]]; then
        INSTALLED_XCODE_VER=$(defaults read /Applications/Xcode.app/Contents/Info.plist \
            CFBundleShortVersionString 2>/dev/null || echo "unknown")
        print_success "Xcode.app already installed: version $INSTALLED_XCODE_VER"

        # If it's already good enough, skip download
        if version_ge "$INSTALLED_XCODE_VER" "$SELECTED_XCODE"; then
            print_success "Xcode version is sufficient. Skipping download."
            _xcode_post_install_steps
            return 0
        else
            print_info "Installed version ($INSTALLED_XCODE_VER) is older than required ($SELECTED_XCODE). Upgrading..."
        fi
    else
        # Warn if only CLT is present
        if xcode-select -p &>/dev/null 2>&1; then
            CLT_PATH=$(xcode-select -p)
            if [[ "$CLT_PATH" == *"CommandLineTools"* ]]; then
                print_info "Only Command Line Tools found at: $CLT_PATH"
                print_info "Full Xcode.app required for Qt6 compilation. Installing..."
            fi
        fi
    fi

    echo ""

    # Install via xcodes (handles Apple ID auth automatically)
    ensure_xcodes_cli
    echo ""

    # Prompt for Apple ID credentials if not already in environment.
    # xcodes reads XCODES_USERNAME and XCODES_PASSWORD automatically — no
    # interactive prompt will appear mid-download.
    if [[ -z "$XCODES_USERNAME" ]] || [[ -z "$XCODES_PASSWORD" ]]; then
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${BOLD}  🔐 Apple ID required to download Xcode${NC}"
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        print_info "Credentials go directly to Apple. Not stored by this script."
        print_info "Tip: set XCODES_USERNAME and XCODES_PASSWORD env vars to skip this prompt."
        echo ""
        read -r  -p "  Apple ID (email): " XCODES_USERNAME
        read -rs -p "  Password:         " XCODES_PASSWORD
        echo ""
        export XCODES_USERNAME XCODES_PASSWORD
        echo ""
    else
        print_info "Using Apple ID from environment: $XCODES_USERNAME"
        echo ""
    fi

    print_info "Running: xcodes install $SELECTED_XCODE --select"
    echo ""

    if XCODES_USERNAME="$XCODES_USERNAME" XCODES_PASSWORD="$XCODES_PASSWORD" \
       xcodes install "$SELECTED_XCODE" --select; then
        echo ""
        print_success "Xcode $SELECTED_XCODE installed and selected."
        _xcode_post_install_steps
    else
        echo ""
        print_info "xcodes failed. Trying direct curl fallback..."
        _xcode_curl_fallback
    fi
}

_xcode_curl_fallback() {
    local filename
    filename=$(basename "$SELECTED_XCODE_PATH")
    local dest="$HOME/Downloads/$filename"
    local url="https://developer.apple.com/services-account/download?path=${SELECTED_XCODE_PATH}"

    print_info "Downloading: $url"
    echo ""

    curl -L --progress-bar -H "User-Agent: Xcode" -o "$dest" "$url"

    # Validate: a real .xip is several GB; anything under 1MB is an auth error page
    if [[ $? -ne 0 ]] || [[ ! -f "$dest" ]] || [[ $(wc -c < "$dest") -lt 1000000 ]]; then
        echo ""
        print_error "Download failed or file is invalid (auth required)."
        echo ""
        echo -e "    Manual options:"
        echo -e "    a) ${CYAN}xcodes install $SELECTED_XCODE --select${NC}"
        echo -e "    b) Download from: ${CYAN}https://developer.apple.com/download/all/?q=Xcode+$SELECTED_XCODE${NC}"
        echo -e "       then run: ${CYAN}xip --expand <file.xip> -C /Applications/${NC}"
        exit 1
    fi

    echo ""
    print_success "Download complete: $dest"
    print_info "Expanding .xip into /Applications/ (this may take several minutes)..."
    xip --expand "$dest" -C /Applications/

    _xcode_post_install_steps
}

_xcode_post_install_steps() {
    print_info "Configuring xcode-select..."
    sudo xcode-select -s /Applications/Xcode.app

    print_info "Accepting Xcode license..."
    sudo xcodebuild -license accept

    print_info "Running first launch (installs extra components)..."
    sudo xcodebuild -runFirstLaunch

    FINAL_VER=$(defaults read /Applications/Xcode.app/Contents/Info.plist \
        CFBundleShortVersionString 2>/dev/null || echo "unknown")
    print_success "Xcode $FINAL_VER ready."
}

# ─── Install Python 3 ─────────────────────────────────────────────────────────

install_python() {
    print_header "🐍 Checking Python 3"

    if command_exists python3; then
        PYTHON_VERSION=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
        print_success "Python 3 already installed: $PYTHON_VERSION"
        return 0
    fi

    if [[ "$OS_TYPE" == "macos" ]]; then
        if command_exists brew; then
            print_info "Installing Python 3 via Homebrew..."
            brew install python3
        else
            print_error "Homebrew not found. Install from https://brew.sh"
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

    print_success "Python 3 installation complete."
}

# ─── Install system Qt6 dependencies ─────────────────────────────────────────

install_system_dependencies() {
    print_header "📦 Installing System Dependencies"

    if [[ "$OS_TYPE" == "macos" ]]; then
        if ! command_exists brew; then
            print_error "Homebrew not found. Install from https://brew.sh"
            exit 1
        fi
        print_info "Installing macOS Qt6 dependencies via Homebrew..."
        brew install qt6 libxkbcommon
        print_success "macOS dependencies installed."

    elif [[ "$OS_TYPE" == "linux" ]]; then
        print_info "Installing Linux Qt6 dependencies..."
        if command_exists apt-get; then
            sudo apt-get update
            sudo apt-get install -y \
                libqt6gui6 libqt6core6 libqt6widgets6 \
                libxkbcommon0 libdbus-1-3 \
                libfontconfig1 libfreetype6
        elif command_exists dnf; then
            sudo dnf install -y qt6-qtbase qt6-qtbase-gui \
                libxkbcommon dbus libfontconfig freetype
        elif command_exists yum; then
            sudo yum install -y qt6-qtbase qt6-qtbase-gui \
                libxkbcommon dbus libfontconfig freetype
        elif command_exists pacman; then
            sudo pacman -S --noconfirm qt6-base libxkbcommon
        fi
        print_success "Linux dependencies installed."
    fi
}

# ─── Virtual environment ──────────────────────────────────────────────────────

create_venv() {
    print_header "🔧 Creating Virtual Environment"

    VENV_DIR="venv"

    if [ -d "$VENV_DIR" ]; then
        print_info "Virtual environment already exists at $VENV_DIR"
        return 0
    fi

    print_info "Creating virtual environment..."
    python3 -m venv "$VENV_DIR"
    print_success "Virtual environment created."
}

activate_venv() {
    source "venv/bin/activate"
    print_success "Virtual environment activated."
}

install_dependencies() {
    print_header "📥 Installing Python Dependencies"

    if [ ! -f "requirements.txt" ]; then
        print_error "requirements.txt not found"
        exit 1
    fi

    print_info "Upgrading pip..."
    pip install --upgrade pip setuptools wheel

    print_info "Installing dependencies from requirements.txt..."
    pip install -r requirements.txt

    print_success "Dependencies installed successfully."
}

# ─── Launchers ────────────────────────────────────────────────────────────────

create_wrapper_script() {
    print_header "🚀 Creating Application Wrapper Script"

    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    cat > "movie-folder-renamer" << 'EOF'
#!/bin/bash
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

    chmod +x "movie-folder-renamer"
    print_success "Wrapper script created: movie-folder-renamer"
}

create_macos_app() {
    print_header "🍎 Creating macOS Application Bundle"

    APP_NAME="Movie Folder Renamer"
    APP_BUNDLE="$APP_NAME.app"
    CONTENTS_DIR="$APP_BUNDLE/Contents"
    MACOS_DIR="$CONTENTS_DIR/MacOS"
    RESOURCES_DIR="$CONTENTS_DIR/Resources"

    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

    cat > "$MACOS_DIR/launcher.sh" << 'EOF'
#!/bin/bash
APP_BUNDLE="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT_DIR="$(dirname "$APP_BUNDLE")/../../"
VENV_PATH="$SCRIPT_DIR/venv"

if [ ! -d "$VENV_PATH" ]; then
    osascript -e 'display notification "Virtual environment not found. Please run setup.sh first." with title "Movie Folder Renamer Error"'
    exit 1
fi

source "$VENV_PATH/bin/activate"
cd "$SCRIPT_DIR"
python3 gui_app.py "$@"
EOF

    chmod +x "$MACOS_DIR/launcher.sh"

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
    print_info "Move it to Applications: mv 'Movie Folder Renamer.app' ~/Applications/"
}

create_linux_desktop_entry() {
    print_header "🐧 Creating Linux Desktop Entry"

    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    DESKTOP_DIR="$HOME/.local/share/applications"
    ICON_DIR="$HOME/.local/share/icons/hicolor/256x256/apps"

    mkdir -p "$DESKTOP_DIR" "$ICON_DIR"

    cat > "$DESKTOP_DIR/movie-folder-renamer.desktop" << EOF
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
EOF

    chmod +x "$DESKTOP_DIR/movie-folder-renamer.desktop"

    cat > "$ICON_DIR/movie-folder-renamer.svg" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 256 256">
  <rect width="256" height="256" fill="#1E88E5" rx="32"/>
  <text x="128" y="140" font-size="80" font-weight="bold" text-anchor="middle" fill="white" font-family="Arial">🎬</text>
  <text x="128" y="200" font-size="24" font-weight="bold" text-anchor="middle" fill="white" font-family="Arial">Renamer</text>
</svg>
EOF

    print_success "Desktop entry created."
}

create_linux_executable() {
    print_header "🐧 Creating Linux Executable"

    BIN_DIR="$HOME/.local/bin"
    mkdir -p "$BIN_DIR"

    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    cat > "$BIN_DIR/movie-folder-renamer" << 'EOF'
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")"/.. && pwd)"
VENV_PATH="$SCRIPT_DIR/venv"

if [ ! -d "$VENV_PATH" ]; then
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

    chmod +x "$BIN_DIR/movie-folder-renamer"
    print_success "Linux executable created: $BIN_DIR/movie-folder-renamer"
}

# ─── Main ─────────────────────────────────────────────────────────────────────

main() {
    echo ""
    print_header "🎬 Movie Folder Renamer - Setup Script"
    echo ""

    detect_os

    # macOS: Xcode must come before Qt6/pip install (pip builds Qt6 from source if needed)
    if [[ "$OS_TYPE" == "macos" ]]; then
        install_xcode_macos
    fi

    install_python
    install_system_dependencies

    create_venv
    activate_venv
    install_dependencies

    create_wrapper_script

    if [[ "$OS_TYPE" == "macos" ]]; then
        create_macos_app
    elif [[ "$OS_TYPE" == "linux" ]]; then
        create_linux_desktop_entry
        create_linux_executable
    fi

    echo ""
    print_header "✅ Setup Complete!"
    echo ""

    if [[ "$OS_TYPE" == "macos" ]]; then
        print_success "Your macOS app is ready!"
        echo ""
        echo -e "    Run directly:    ${CYAN}./movie-folder-renamer${NC}"
        echo -e "    Open as app:     ${CYAN}open 'Movie Folder Renamer.app'${NC}"
        echo -e "    Move to Apps:    ${CYAN}mv 'Movie Folder Renamer.app' ~/Applications/${NC}"
    elif [[ "$OS_TYPE" == "linux" ]]; then
        print_success "Your Linux app is ready!"
        echo ""
        echo -e "    Run from terminal: ${CYAN}movie-folder-renamer${NC}"
        echo -e "    Or launch from application menu."
    fi

    echo ""
    echo "  First time setup:"
    echo "    1. Get your TMDB API key from https://www.themoviedb.org/settings/api"
    echo "    2. Enter your API key in the application"
    echo "    3. Select your movie folder and click 'Iniciar procesamiento'"
    echo ""
    print_success "Done!"
}

main
