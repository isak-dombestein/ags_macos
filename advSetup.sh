#!/bin/bash

# --- AGS Sfor macOS: Advanced Setup Script ---
# This script automates the steps required to set up the
# portable AGS editor on macOS through Wine and builds
# the AGS Game engine for macOS on your system.
# 
# This script will install the following on your Mac:
# - Homebrew (brew.sh)
# - Wine
# - Winetricks
# - .NET Framework 4.8 (within the Wine install itself)
# 
# The AGS build installed through this script should always
# be the latest version and should be fetched from the official
# AGS website. 
#
# Author: Isak Dombestein (isak@dombesteindata.net)
# Date: 18.08.2025

set -e

# --- Config ---
# URL for the current latest version of the portable AGS build
AGS_URL="https://www.adventuregamestudio.co.uk/releases/finals/AGS-3.6.2P2/AGS-3.6.2.12-P2.zip"
# The directory AGS will be installed into.
INSTALL_DIR="/Applications/ags_macos"
# The directory we'll build the AGS Engine in
AGS_SRC_DIR="/tmp/ags_src"

# --- Pretty stuff ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_message() {
    COLOR=$1
    MESSAGE=$2
    echo -e "\n${COLOR}--- ${MESSAGE} ---${NC}"
}

# --- Script Start ---
clear
print_message $BLUE "======================================="
print_message $BLUE " AGS for macOS - Advanced Setup Script "
print_message $BLUE "======================================="
echo "This script will guide you through installing everything needed to run the"
echo "Adventure Gane Studio (AGS) Editor on your Mac as well as building the native"
echo "AGS Engine for macOS. This script will take some time to run, it's recommended"
echo "that you connect your charger before you continue."
echo "You may be asked to enter your password to install some of the software."
read -p "Press [Enter] to begin"

# --- Step 1: Install Homebrew ---
print_message $YELLOW "Checking if Homebrew is already installed..."
if ! command -v brew &> /dev/null; then
    echo "Homebrew not installed, installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo "Homebrew installed!"
else
    print_message $GREEN "Homebrew already installed, running update..."
    brew update
fi

# --- Step 2: Install Wine ---
print_message $YELLOW "Checking if Wine is already installed..."
if !brew list wine-stable &> /dev/bull; then
    echo "Wine not installed. Installing via Homebrew."
    echo "This may take several minutes, you may use your Mac as normal."
    brew install wine-stable
    echo "Wine installed!"
else 
    print_message $GREEN "Wine already installed!"
fi

# --- Step 3: Install Winetricks ---
print_message $YELLOW "Checking for Winetricks..."
if ! command -v winetricks &> /dev/null; then
    echo "Winetricks not found. Installing via Homebrew."
    brew install winetricks
else 
    print_message $GREEN "Winetricks already installed!"
fi

# --- Step 4: Install .NET Framework 4.8 ---
print_message $YELLOW "Installing Microsoft .NET Framework 4.8..."
echo "This is a critical dependency needed to run the AGS Editor."
echo "This step will take several minutes and may open one or more installer windows."
echo "Please follow any on-screen instructions in the installer(s)."
# The -q flaf should run the installation quietly without asking for user confirmation
winetricks -q dotnet48

# --- Step 5: Download and Install AGS ---
print_message $YELLOW "Downloading and configuring the AGS Editor..."

# Clean up any previous installs
if [ -d "$INSTALL_DIR" ]; then
    echo "An existing AGS directory was found. THIS DIRECTORY WILL BE REPLACED!"
    rm -rf "$INSTALL_DIR"
fi

echo "Creating install directory at ${INSTALL_DIR}"
mkdir -p "$INSTALL_DIR"

# Create a temporary file for the download
TEMP_ZIP_FILE="/tmp/ags.zip"

echo "Downloading the portable build of AGS..."
curl -L "$AGS_URL" -o "$TEMP_ZIP_FILE"

echo "Unzipping files to install target..."
unzip -q "$TEMP_ZIP_FILE" -d "$INSTALL_DIR"

echo "Cleaning up temporary files..."
rm "$TEMP_ZIP_FILE"

# --- Step 6: Preparation for building engine ---
print_message $YELLOW "Checking if Git is already installed..."
if ! command --v git &> /dev/null; then
    echo "Git not installed. Installing via Homebrew..."
    brew install git
else 
    echo "Git already installed!"
fi

# --- Step 7: Clone and build the AGS engine ---
print_message $YELLOW "Building AGS Engine for macOS..."

# Install deps
print_message $YELLOW "Installing build dependencies..."
brew install cmake sdl2 freetype libogg libvorbis

# Clone AGS Source
print_message $YELLOW "Cloning AGS Source code from Github..."
if [ -d "$AGS_SRC_DIR" ]; then
    rm -rf "$AGS_SRC_DIR"
fi

git clone https://github.com/adventuregamestudio/ags.git "$AGS_SRC_DIR"
cd "$AGS_SRC_DIR"

# Run CMake and Make
print_message $YELLOW "Preparing build with CMake..."
cmake .

print_message $YELLOW "Compiling the engine with Make..."
echo "NOTE: This is the longest step and will take a significant amount of time!"
make

# Copy the compiled engine to the install dir
print_message $YELLOW "Build Complete, installing to target directory..."
NATIVE_ENGINE_DIR="${INSTALL_DIR}/native_engine"
mkdir -p "$NATIVE_ENGINE_DIR"
cp ags "$NATIVE_ENGINE_DIR/"

# Perform cleanup
print_message $YELLOW "Cleaning up source code files..."
cd ~
rm -rf "$AGS_SRC_DIR"

# --- Installation finished ---
print_message $GREEN "======================================="
print_message $GREEN "         Setup Complete!               "
print_message $GREEN "======================================="
echo "Congrats! Adventure Game Studio has successfully been installed to your Applications folder!"
echo -e "\nTo run the AGS Editor, follow these steps:"
echo -e "1. Open your ${YELLOW}Terminal${NC} application."
echo -e "2. copy and paste this command, then press enter:"
echo -e "${BLUE}cd ${INSTALL_DIR} && wine AGSEditor.exe${NC}"
echo -e "\nTo run games using the ${YELLOW}native macOS engine${NC}:"
echo -e "1. Compile your game in the Editor (Build Menu)"
echo -e "2. Run the following command in your terminal, replacing the path:"
echo -e "${BLUE}${NATIVE_ENGINE_DIR}/ags /path/to/your/game/Compiled/yourgame.ags${NC}"
echo -e "\nEnjoy using AGS! If you encounter any issues, open an issue in the git repository!"