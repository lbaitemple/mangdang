#!/bin/bash
#
# install_ros2_jazzy.sh
# Install ROS 2 Jazzy (ros-base) on Raspberry Pi running Ubuntu 24.04
#
# Robust fix for:
#   liblz4-dev : Depends: liblz4-1 (= 1.9.4-1build1) but 1.9.4-1build1.1 is to be installed
#   libzstd-dev : Depends: libzstd1 (= 1.5.5+dfsg2-2build1) but 1.5.5+dfsg2-2build1.1 is to be installed
#
# Root cause: your apt sources are missing noble-updates and/or noble-security,
# so apt only sees the *old* -dev package (build1) but already has the *new*
# runtime libs (build1.1) installed. The -dev package pins an exact version
# match with `=`, so the upgrade is unsatisfiable until you enable the update
# pockets so the new -dev versions become visible.

set -euo pipefail

# ---------- helpers ----------
log()  { echo -e "\033[1;32m[+]\033[0m $*"; }
warn() { echo -e "\033[1;33m[!]\033[0m $*"; }
err()  { echo -e "\033[1;31m[x]\033[0m $*" >&2; }

if [[ $EUID -eq 0 ]]; then
    SUDO=""
else
    SUDO="sudo"
    $SUDO -v
fi

# ---------- preflight ----------
log "Checking Ubuntu version..."
if ! grep -q 'VERSION_ID="24.04"' /etc/os-release; then
    err "This script targets Ubuntu 24.04 (Noble). Aborting."
    exit 1
fi

ARCH="$(dpkg --print-architecture)"
UBUNTU_CODENAME="$(. /etc/os-release && echo "$UBUNTU_CODENAME")"
log "Architecture: $ARCH | Codename: $UBUNTU_CODENAME"

# ---------- ensure noble-updates and noble-security are enabled ----------
log "Checking which apt pockets are enabled..."

ALL_SOURCES="$(cat /etc/apt/sources.list 2>/dev/null || true; \
              cat /etc/apt/sources.list.d/*.list 2>/dev/null || true; \
              cat /etc/apt/sources.list.d/*.sources 2>/dev/null || true)"

has_pocket() {
    echo "$ALL_SOURCES" | grep -qE "(^|[[:space:]])${1}([[:space:]]|$)"
}

NEED_UPDATES=false
NEED_SECURITY=false

if ! has_pocket "noble-updates"; then
    warn "noble-updates pocket is NOT enabled — this is the cause of your error."
    NEED_UPDATES=true
fi
if ! has_pocket "noble-security"; then
    warn "noble-security pocket is NOT enabled."
    NEED_SECURITY=true
fi

if $NEED_UPDATES || $NEED_SECURITY; then
    if [[ "$ARCH" == "arm64" || "$ARCH" == "armhf" ]]; then
        MIRROR="http://ports.ubuntu.com/ubuntu-ports"
    else
        MIRROR="http://archive.ubuntu.com/ubuntu"
    fi
    log "Adding missing pockets via mirror: $MIRROR"

    TMPFILE="$(mktemp)"
    {
        if $NEED_UPDATES; then
            echo "deb $MIRROR noble-updates main restricted universe multiverse"
        fi
        if $NEED_SECURITY; then
            echo "deb $MIRROR noble-security main restricted universe multiverse"
        fi
    } > "$TMPFILE"
    $SUDO mv "$TMPFILE" /etc/apt/sources.list.d/ros2-fix-pockets.list
    $SUDO chmod 644 /etc/apt/sources.list.d/ros2-fix-pockets.list
fi

# ---------- refresh and diagnose ----------
log "Refreshing apt index..."
$SUDO apt-get update

log "Current candidate versions for the conflicting packages:"
apt-cache policy liblz4-1 liblz4-dev libzstd1 libzstd-dev | sed 's/^/   /'

# ---------- locale ----------
log "Configuring UTF-8 locale..."
$SUDO apt-get install -y locales
$SUDO locale-gen en_US en_US.UTF-8
$SUDO update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
export LANG=en_US.UTF-8

# ---------- universe ----------
log "Ensuring 'universe' is enabled..."
$SUDO apt-get install -y software-properties-common
$SUDO add-apt-repository -y universe
$SUDO apt-get update

# ---------- THE ACTUAL FIX ----------
log "Resolving exact candidate versions..."
LZ4_DEV_VER="$(apt-cache policy liblz4-dev  | awk '/Candidate:/ {print $2}')"
ZSTD_DEV_VER="$(apt-cache policy libzstd-dev | awk '/Candidate:/ {print $2}')"

log "  liblz4-dev  candidate -> $LZ4_DEV_VER"
log "  libzstd-dev candidate -> $ZSTD_DEV_VER"

if [[ -z "$LZ4_DEV_VER" || "$LZ4_DEV_VER" == "(none)" ]] || \
   [[ -z "$ZSTD_DEV_VER" || "$ZSTD_DEV_VER" == "(none)" ]]; then
    err "Could not find -dev candidate versions even after enabling pockets."
    err "Run 'apt-cache policy liblz4-dev libzstd-dev' to debug."
    exit 1
fi

log "Installing runtime + dev packages with pinned, matching versions..."
$SUDO apt-get install -y \
    "liblz4-1=$LZ4_DEV_VER"   "liblz4-dev=$LZ4_DEV_VER" \
    "libzstd1=$ZSTD_DEV_VER"  "libzstd-dev=$ZSTD_DEV_VER" \
    || {
        warn "Pinned install failed; falling back to aptitude resolver..."
        $SUDO apt-get install -y aptitude
        $SUDO aptitude install -y liblz4-dev libzstd-dev
    }

# ---------- general system upgrade ----------
log "Running dist-upgrade to align the rest of the system..."
$SUDO apt-get -y dist-upgrade

# ---------- prerequisites ----------
log "Installing prerequisites..."
$SUDO apt-get install -y curl gnupg lsb-release ca-certificates

# ---------- ROS 2 apt repo ----------
log "Adding ROS 2 GPG key and apt source..."
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
    log "Initializing rosdep..."
    $SUDO rosdep init
fi
rosdep update || warn "rosdep update failed — retry later as your user."

# ---------- shell setup ----------
BASHRC="$HOME/.bashrc"
SOURCE_LINE="source /opt/ros/jazzy/setup.bash"
if ! grep -Fxq "$SOURCE_LINE" "$BASHRC"; then
    log "Adding ROS 2 source line to $BASHRC..."
    {
        echo ""
        echo "# ROS 2 Jazzy"
        echo "$SOURCE_LINE"
    } >> "$BASHRC"
fi

log "Done. Open a new shell or run: source ~/.bashrc"
log "Then test with: ros2 --help"
