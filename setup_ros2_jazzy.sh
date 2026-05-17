#!/bin/bash
#
# install_ros2_jazzy.sh
# Install ROS 2 Jazzy (ros-base) on Raspberry Pi running Ubuntu 24.04
# Handles the liblz4-dev / libzstd-dev unmet-dependency errors.
#
# Usage:
#   chmod +x install_ros2_jazzy.sh
#   ./install_ros2_jazzy.sh
#

set -euo pipefail

# ---------- helpers ----------
log()  { echo -e "\033[1;32m[+]\033[0m $*"; }
warn() { echo -e "\033[1;33m[!]\033[0m $*"; }
err()  { echo -e "\033[1;31m[x]\033[0m $*" >&2; }

require_sudo() {
    if [[ $EUID -eq 0 ]]; then
        SUDO=""
    else
        SUDO="sudo"
        # Prime sudo so it doesn't prompt mid-script
        $SUDO -v
    fi
}

# ---------- preflight ----------
log "Checking Ubuntu version..."
if ! grep -q "VERSION_ID=\"24.04\"" /etc/os-release; then
    err "This script targets Ubuntu 24.04 (Noble). Aborting."
    exit 1
fi

ARCH="$(dpkg --print-architecture)"
log "Detected architecture: $ARCH"
if [[ "$ARCH" != "arm64" && "$ARCH" != "amd64" ]]; then
    warn "ROS 2 Jazzy officially supports arm64/amd64. Your arch is '$ARCH'."
fi

require_sudo

# ---------- locale ----------
log "Configuring UTF-8 locale..."
$SUDO apt-get update
$SUDO apt-get install -y locales
$SUDO locale-gen en_US en_US.UTF-8
$SUDO update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
export LANG=en_US.UTF-8

# ---------- universe repo ----------
log "Enabling universe repository..."
$SUDO apt-get install -y software-properties-common
$SUDO add-apt-repository -y universe

# ---------- FIX FOR liblz4-dev / libzstd-dev ----------
# Root cause: the security pocket ships -1build1.1 while the main pocket still
# has -1build1 for the runtime libs (liblz4-1, libzstd1). When you install
# the -dev packages they pull the .1 versions and apt refuses because the
# runtime libs you already have don't match. Fix is to refresh the index from
# all pockets and let apt upgrade the runtime libs first.
log "Refreshing package lists from all pockets (main, updates, security)..."
$SUDO apt-get update

log "Upgrading runtime libs that commonly cause the lz4/zstd dev mismatch..."
# Upgrade the runtime libs to whatever the security/updates pocket offers
# BEFORE we try to install anything that depends on the matching -dev versions.
$SUDO apt-get install -y --only-upgrade \
    liblz4-1 \
    libzstd1 || warn "Could not upgrade liblz4-1/libzstd1 — continuing anyway."

# General upgrade to keep everything in lockstep. Use dist-upgrade so apt is
# allowed to add/remove packages to resolve dependencies (this is what fixes
# 'held broken packages').
log "Running full dist-upgrade to align package versions..."
$SUDO apt-get -y dist-upgrade

# ---------- prerequisites ----------
log "Installing prerequisites (curl, gnupg, etc.)..."
$SUDO apt-get install -y \
    curl \
    gnupg \
    lsb-release \
    ca-certificates

# ---------- ROS 2 apt repo ----------
log "Adding ROS 2 GPG key and apt source..."
$SUDO install -d -m 0755 /usr/share/keyrings
$SUDO curl -sSL \
    https://raw.githubusercontent.com/ros/rosdistro/master/ros.key \
    -o /usr/share/keyrings/ros-archive-keyring.gpg

UBUNTU_CODENAME="$(. /etc/os-release && echo "$UBUNTU_CODENAME")"
echo "deb [arch=$ARCH signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $UBUNTU_CODENAME main" \
    | $SUDO tee /etc/apt/sources.list.d/ros2.list > /dev/null

$SUDO apt-get update

# ---------- ROS 2 Jazzy ros-base ----------
log "Installing ros-jazzy-ros-base..."
# If apt still complains about lz4/zstd here, force it to recompute by
# explicitly listing the dev libs first so they get resolved together with
# their runtime siblings in a single transaction.
$SUDO apt-get install -y liblz4-dev libzstd-dev || {
    warn "liblz4-dev/libzstd-dev still failed — attempting --fix-broken..."
    $SUDO apt-get -y --fix-broken install
    $SUDO apt-get install -y liblz4-dev libzstd-dev
}

$SUDO apt-get install -y ros-jazzy-ros-base

# ---------- dev tools (optional but recommended) ----------
log "Installing ROS 2 dev tools (colcon, rosdep, vcstool)..."
$SUDO apt-get install -y \
    python3-colcon-common-extensions \
    python3-rosdep \
    python3-vcstool \
    python3-argcomplete \
    build-essential \
    git

# ---------- rosdep init ----------
if [[ ! -f /etc/ros/rosdep/sources.list.d/20-default.list ]]; then
    log "Initializing rosdep..."
    $SUDO rosdep init
fi
rosdep update || warn "rosdep update failed — you can retry later as your user."

# ---------- shell setup ----------
BASHRC="$HOME/.bashrc"
SOURCE_LINE="source /opt/ros/jazzy/setup.bash"
if ! grep -Fxq "$SOURCE_LINE" "$BASHRC"; then
    log "Adding ROS 2 source line to $BASHRC..."
    echo "" >> "$BASHRC"
    echo "# ROS 2 Jazzy" >> "$BASHRC"
    echo "$SOURCE_LINE" >> "$BASHRC"
fi

# ---------- done ----------
log "Installation complete."
echo
echo "Next steps:"
echo "  source ~/.bashrc"
echo "  ros2 --help"
echo
echo "Quick sanity check (in two terminals after sourcing):"
echo "  ros2 run demo_nodes_cpp talker      # may require ros-jazzy-demo-nodes-cpp"
echo "  ros2 run demo_nodes_cpp listener"
