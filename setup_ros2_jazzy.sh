#!/bin/bash
#
# install_ros2_jazzy.sh
# Install ROS 2 Jazzy (ros-base) on Raspberry Pi running Ubuntu 24.04
#
# Fixes the held-broken-packages error caused by missing 'noble-updates' suite
# in /etc/apt/sources.list.d/ubuntu.sources, which leaves liblz4-dev/libzstd-dev
# stuck at the old -build1 while the runtime libs are at -build1.1.

set -euo pipefail

log()  { echo -e "\033[1;32m[+]\033[0m $*"; }
warn() { echo -e "\033[1;33m[!]\033[0m $*"; }
err()  { echo -e "\033[1;31m[x]\033[0m $*" >&2; }

if [[ $EUID -eq 0 ]]; then SUDO=""; else SUDO="sudo"; $SUDO -v; fi

# ---------- preflight ----------
if ! grep -q 'VERSION_ID="24.04"' /etc/os-release; then
    err "This script targets Ubuntu 24.04 (Noble)."
    exit 1
fi
ARCH="$(dpkg --print-architecture)"
UBUNTU_CODENAME="$(. /etc/os-release && echo "$UBUNTU_CODENAME")"
log "Architecture: $ARCH | Codename: $UBUNTU_CODENAME"

# ---------- patch ubuntu.sources to include noble-updates ----------
SOURCES_FILE="/etc/apt/sources.list.d/ubuntu.sources"

if [[ -f "$SOURCES_FILE" ]]; then
    # Look at every line that starts with "Suites:" and check whether any of
    # them already mentions noble-updates.
    if ! grep -E '^Suites:' "$SOURCES_FILE" | grep -qw "noble-updates"; then
        log "noble-updates is missing from $SOURCES_FILE — patching..."
        $SUDO cp "$SOURCES_FILE" "${SOURCES_FILE}.bak.$(date +%s)"
        # Append ' noble-updates noble-backports' to any Suites line that has
        # exactly 'noble' (and not already the longer form).
        $SUDO sed -i -E 's/^(Suites:[[:space:]]+noble)$/\1 noble-updates noble-backports/' "$SOURCES_FILE"
        log "Patched. New Suites lines:"
        grep -E '^Suites:' "$SOURCES_FILE" | sed 's/^/   /'
    else
        log "noble-updates is already enabled."
    fi
else
    warn "$SOURCES_FILE not found — falling back to a standalone .list file."
    MIRROR="http://ports.ubuntu.com/ubuntu-ports"
    [[ "$ARCH" == "amd64" || "$ARCH" == "i386" ]] && MIRROR="http://archive.ubuntu.com/ubuntu"
    echo "deb $MIRROR noble-updates main restricted universe multiverse" \
        | $SUDO tee /etc/apt/sources.list.d/noble-updates.list > /dev/null
fi

$SUDO apt-get update

log "Candidate versions after enabling noble-updates:"
apt-cache policy liblz4-dev libzstd-dev | sed 's/^/   /'

# ---------- fix the broken deps ----------
log "Installing matched runtime+dev pairs..."
LZ4_VER="$(apt-cache policy liblz4-dev  | awk '/Candidate:/ {print $2}')"
ZSTD_VER="$(apt-cache policy libzstd-dev | awk '/Candidate:/ {print $2}')"
$SUDO apt-get install -y \
    "liblz4-1=$LZ4_VER"  "liblz4-dev=$LZ4_VER" \
    "libzstd1=$ZSTD_VER" "libzstd-dev=$ZSTD_VER"

# ---------- locale ----------
log "Configuring UTF-8 locale..."
$SUDO apt-get install -y locales
$SUDO locale-gen en_US en_US.UTF-8
$SUDO update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
export LANG=en_US.UTF-8

# ---------- universe + general upgrade ----------
$SUDO apt-get install -y software-properties-common
$SUDO add-apt-repository -y universe
$SUDO apt-get update
$SUDO apt-get -y dist-upgrade

# ---------- ROS 2 repo ----------
log "Adding ROS 2 apt source..."
$SUDO apt-get install -y curl gnupg lsb-release ca-certificates
$SUDO install -d -m 0755 /usr/share/keyrings
$SUDO curl -sSL \
    https://raw.githubusercontent.com/ros/rosdistro/master/ros.key \
    -o /usr/share/keyrings/ros-archive-keyring.gpg
echo "deb [arch=$ARCH signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $UBUNTU_CODENAME main" \
    | $SUDO tee /etc/apt/sources.list.d/ros2.list > /dev/null
$SUDO apt-get update

# ---------- ROS 2 Jazzy ros-base ----------
log "Installing ros-jazzy-ros-base..."
$SUDO apt-get install -y ros-jazzy-ros-base

# ---------- dev tools ----------
log "Installing colcon, rosdep, vcstool..."
$SUDO apt-get install -y \
    python3-colcon-common-extensions \
    python3-rosdep \
    python3-vcstool \
    python3-argcomplete \
    build-essential \
    git

if [[ ! -f /etc/ros/rosdep/sources.list.d/20-default.list ]]; then
    $SUDO rosdep init
fi
rosdep update || warn "rosdep update failed — retry later as your user."

# ---------- shell setup ----------
BASHRC="$HOME/.bashrc"
SOURCE_LINE="source /opt/ros/jazzy/setup.bash"
if ! grep -Fxq "$SOURCE_LINE" "$BASHRC"; then
    { echo ""; echo "# ROS 2 Jazzy"; echo "$SOURCE_LINE"; } >> "$BASHRC"
fi

log "Done. Run: source ~/.bashrc && ros2 --help"
