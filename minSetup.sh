#!/bin/bash

# --- AGS for macOS: Minimal Setup Script + App Bundler ---
# This script automates the steps required to set up the
# portable AGS editor on macOS through Wine.
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
# This script also bundles everything into AGS Editor.app, which can be launched as normal
# from your ~/Applications folder and Spotlight / Launchpad
# 
# Author: Isak Dombestein (isak@dombesteindata.net)
# Creation Date: 18.08.2025
# Last Update Date: 03.09.2025

set -euo pipefail

# --- Config ---
# URL for the current latest version of the portable AGS build
AGS_URL="https://www.adventuregamestudio.co.uk/releases/finals/AGS-3.6.2P2/AGS-3.6.2.12-P2.zip"

APP_NAME="AGS Editor"

# AGS will be bundled into the User's Applications directory.
APP_PARENT_DIR="${HOME}/Applications"
APP_BUNDLE="${APP_PARENT_DIR}/${APP_NAME}.app"
CONTENTS_DIR="${APP_BUNDLE}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"
AGS_PAYLOAD_DIR="${RESOURCES_DIR}/ags_macos"
TEMP_ZIP_FILE="/tmp/ags.zip"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ICON_URL="https://learn.dombesteindata.net/assets/ags.png"
ICNS_TARGET="${RESOURCES_DIR}/agseditor.icns"

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

cleanup() {
    rm -rf "${TMP_ICONSET:-}" "${TMP_PNG:-}" "${TEMP_ZIP_FILE:-}" 2>/dev/null || true;
}
trap cleanup EXIT

# --- Script Start ---
clear
print_message $BLUE "=========================================="
print_message $BLUE " AGS for macOS - Minimal Setup + Bundler  "
print_message $BLUE "=========================================="
cat <<'EOT'
This script will:
    * Install Homebrew, Wine and Winetricks if missing
    * Install Microsoft .NET Framework 4.8 (inside of the Wine environment)
    * Download the portable AGS Editor build
    * Create a new "AGS Editor.app" file that launches AGS via Wine
EOT
: "${INTERACTIVE:=1}"
[ "$INTERACTIVE" -eq 1 ] && read -p "Press [Enter] to begin"

mkdir -p "$APP_PARENT_DIR"

# --- Step 1: Install Homebrew ---
print_message $YELLOW "Checking if Homebrew is already installed..."

if ! command -v brew &>/dev/null; then
    echo "Homebrew not found, installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    print_message $GREEN "Homebrew already installed. Updating..."
    brew update
fi

# --- Step 2: Install Wine ---
print_message $YELLOW "Checking if Wine is already installed..."
if ! command -v wine &> /dev/null && ! command -v wine64 &>/dev/null; then
    echo "Wine not installed. Installing wine-stable via Homebrew (this might take a moment)..."
    brew install --cask wine-stable || brew install wine-stable || true
    echo "Wine installed!"
else 
    print_message $GREEN "Wine already installed!"
fi

# Ensure we check the common candidates for Wine install locations for both
# Apple Silicon (M-Series) systems and Intel systems
CANDIDATES=(
    /opt/homebrew/bin/wine64
    /opt/homebrew/bin/wine
    /usr/local/bin/wine64
    /usr/local/bin/wine
)

WINE=""
# Check each candidate and set our WINE var to a valid path if found
for c in "${CANDIDATES[@]}"; do
  if [ -x "$c" ]; then WINE="$c"; break; fi
done

# Fallback to PATH
if [ -z "${WINE:-}" ]; then
  if command -v wine64 &>/dev/null; then WINE="$(command -v wine64)"; fi
fi
if [ -z "${WINE:-}" ]; then
  if command -v wine &>/dev/null; then WINE="$(command -v wine)"; fi
fi

if [ -z "${WINE:-}" ]; then
  echo "ERROR: Could not locate Wine binary. Aborting." >&2
  exit 1
fi

# --- Step 3: Install Winetricks ---
print_message $YELLOW "Checking for Winetricks..."
if ! command -v winetricks &>/dev/null; then
    echo "Installing Winetricks..."
    brew install winetricks
else
    print_message $GREEN "Winetricks is already installed."
fi

# --- Step 4: Install .NET Framework 4.8 ---
print_message $YELLOW "Installing Microsoft .NET Framework 4.8..."
echo "This is a critical dependency needed to run the AGS Editor."
# The -q flag should run the installation quietly without asking for user confirmation
winetricks -q dotnet48 || {
    echo ".NET 4.8 installation reported an error; continuing anyway (This often misreports completion).";
}

# --- Step 5: Download and Install AGS ---
print_message $YELLOW "Downloading and configuring the AGS Editor..."

# Cleanup if script has already been run
rm -f "$TEMP_ZIP_FILE"

curl -fsSL "$AGS_URL" -o "$TEMP_ZIP_FILE"

print_message $YELLOW "Creating App Bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR" "$AGS_PAYLOAD_DIR"

print_message $YELLOW "Unzipping AGS into Resources/ags_macos..."
unzip -q "$TEMP_ZIP_FILE" -d "$AGS_PAYLOAD_DIR"

# Verify editor executable location
DEFAULT_EXE="${AGS_PAYLOAD_DIR}/AGSEditor.exe"
if [ ! -f "$DEFAULT_EXE" ]; then
    FOUND_EXE="$(/usr/bin/find "$AGS_PAYLOAD_DIR" -type f -iname 'AGSEditor.exe' -print -quit || true)"
    if [ -n "$FOUND_EXE" ]; then
        # normalize path to expected location
        mv -f "$FOUND_EXE" "$DEFAULT_EXE" 2>/dev/null || true
    fi
fi

if [ ! -f "$DEFAULT_EXE" ]; then
    echo "ERROR: AGSEditor.exe not found after unzip! Aborting..." >&2
    exit 1
fi

rm -f "$TEMP_ZIP_FILE"

# --- Step 5.1: Write to Info.plist ---
cat >"$CONTENTS_DIR/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key>            <string>AGS Editor</string>
  <key>CFBundleDisplayName</key>     <string>AGS Editor</string>
  <key>CFBundleIdentifier</key>      <string>net.dombesteindata.agseditor</string>
  <key>CFBundleVersion</key>         <string>1.0.0</string>
  <key>CFBundleShortVersionString</key><string>1.0.0</string>
  <key>CFBundlePackageType</key>     <string>APPL</string>
  <key>CFBundleExecutable</key>      <string>AGS-Editor</string>
  <key>NSHighResolutionCapable</key> <true/>
  <key>CFBundleIconFile</key>        <string>agseditor.icns</string>
  <key>LSMinimumSystemVersion</key>  <string>11.0</string>
  <key>LSApplicationCategoryType</key><string>public.app-category.developer-tools</string>
</dict>
</plist>
PLIST

# --- Step 5.2: Write launcher script ---
cat >"$MACOS_DIR/AGS-Editor" <<'LAUNCH'
#!/bin/bash
set -euo pipefail
APP_DIR="$(cd "$(dirname "$0")/.." && pwd)"
RESOURCES="${APP_DIR}/Resources"
EXE="${RESOURCES}/ags_macos/AGSEditor.exe"

CANDIDATES=(
  /opt/homebrew/bin/wine64
  /opt/homebrew/bin/wine
  /usr/local/bin/wine64
  /usr/local/bin/wine
)

WINE=""
for c in "${CANDIDATES[@]}"; do
  if [ -x "$c" ]; then WINE="$c"; break; fi
done

# Fallback to PATH
if [ -z "${WINE:-}" ]; then
  if command -v wine64 &>/dev/null; then WINE="$(command -v wine64)"; fi
fi

if [ -z "${WINE:-}" ]; then
  if command -v wine &>/dev/null; then WINE="$(command -v wine)"; fi
fi

if [ -z "${WINE:-}" ]; then
  echo "ERROR: Could not locate Wine binary. Aborting." >&2
  exit 1
fi

exec "$WINE" "$EXE"
LAUNCH

chmod +x "$MACOS_DIR/AGS-Editor"

# --- Step 5.3: Fetch icon from repo, skip if link fails. ---
if [ -n "${ICON_URL:-}" ]; then
  print_message $YELLOW "Fetching icon PNG from ${ICON_URL}..."
  TMP_ICONSET="/tmp/agseditor.iconset"
  TMP_PNG="/tmp/agseditor.png"

  curl -fsSL "$ICON_URL" -o "$TMP_PNG" || {
    echo "WARNING: Could not download icon PNG. Continuing without custom icon."
    ICON_URL=""
  }

  # Verify img checksum is correct
  echo "8a8507a4e74bf5cf851e55a75ee90f35f6c41c7fccdae4acd3671f5c14d2dc14  $TMP_PNG" | shasum -a 256 -c - || {
    echo "WARNING: ICON CHECKSUM MISMATCH! Skipping icon."
    ICON_URL=""
  }

  if [ -n "${ICON_URL:-}" ]; then
    print_message $YELLOW "Generating .icns bundle..."
    rm -rf "$TMP_ICONSET" && mkdir -p "$TMP_ICONSET"

    # Generate all required sizes:
    sips -z 16 16     "$TMP_PNG" --out "$TMP_ICONSET/icon_16x16.png" >/dev/null
    sips -z 32 32     "$TMP_PNG" --out "$TMP_ICONSET/icon_16x16@2x.png" >/dev/null
    sips -z 32 32     "$TMP_PNG" --out "$TMP_ICONSET/icon_32x32.png" >/dev/null
    sips -z 64 64     "$TMP_PNG" --out "$TMP_ICONSET/icon_32x32@2x.png" >/dev/null
    sips -z 128 128   "$TMP_PNG" --out "$TMP_ICONSET/icon_128x128.png" >/dev/null
    sips -z 256 256   "$TMP_PNG" --out "$TMP_ICONSET/icon_128x128@2x.png" >/dev/null
    sips -z 256 256   "$TMP_PNG" --out "$TMP_ICONSET/icon_256x256.png" >/dev/null
    sips -z 512 512   "$TMP_PNG" --out "$TMP_ICONSET/icon_256x256@2x.png" >/dev/null
    sips -z 512 512   "$TMP_PNG" --out "$TMP_ICONSET/icon_512x512.png" >/dev/null
    sips -z 1024 1024 "$TMP_PNG" --out "$TMP_ICONSET/icon_512x512@2x.png" >/dev/null

    iconutil -c icns "$TMP_ICONSET" -o "$ICNS_TARGET" || {
      echo "WARNING: iconutil failed; proceeding without custom icon."
    }
  fi
else 
    print_message $YELLOW "ICON_URL is not set. Skipping icon."
fi

# --- Step 5.4: Remove quarantine + ad-hoc sign ---
print_message $YELLOW "Finalizing App Bundle..."
xattr -dr com.apple.quarantine "$APP_BUNDLE" || true
codesign --force --deep --sign - "$APP_BUNDLE" || true

# --- Installation finished ---
print_message $GREEN "======================================="
print_message $GREEN "         Setup Complete!               "
print_message $GREEN "======================================="
cat <<EON
Congratulations! Adventure Game Studio has been installed on your system!
BundlePath;
    ${APP_BUNDLE}
Double click the installed application in your ~/Applications folder.
You can also launch the app via Launchpad or Spotlight. 
Good luck, if you have any issues, please reach out to isak@dombesteindata.net for support!
EON
