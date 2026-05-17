#!/bin/bash
#
# setup_jupyterlab.sh
# Installs JupyterLab, configures it with a password, and sets it up as a
# systemd service that listens on 0.0.0.0:8888.
#
# Usage:  sudo ./setup_jupyterlab.sh [password]
#         (defaults password to "mangdang" if none is given)
#

set -euo pipefail

# ---------- Configuration ----------
JUPYTER_PASSWORD="${1:-mangdang}"
SERVICE_USER="${SUDO_USER:-ubuntu}"
USER_HOME=$(getent passwd "$SERVICE_USER" | cut -d: -f6)
JUPYTER_DIR="$USER_HOME/.jupyter"
CONFIG_FILE="$JUPYTER_DIR/jupyter_server_config.py"
SERVICE_FILE="/etc/systemd/system/jupyterlab.service"
PORT=8888

echo "==> Installing JupyterLab for user: $SERVICE_USER"
echo "==> Home directory: $USER_HOME"

# ---------- 1. Install packages ----------
echo "==> Installing jupyter-core via apt..."
sudo apt update
sudo apt install -y jupyter-core python3-pip

echo "==> Upgrading pip and installing JupyterLab..."
pip3 install --upgrade pip --break-system-packages
pip3 install --upgrade jupyterlab notebook jupyter_server --break-system-packages

# ---------- 2. Generate hashed password ----------
echo "==> Generating hashed password..."
HASHED_PASSWORD=$(python3 -c "from jupyter_server.auth import passwd; print(passwd('${JUPYTER_PASSWORD}'))")
echo "    Hash generated: ${HASHED_PASSWORD}"

# ---------- 3. Write Jupyter config ----------
echo "==> Writing Jupyter config to $CONFIG_FILE"
sudo -u "$SERVICE_USER" mkdir -p "$JUPYTER_DIR"

sudo -u "$SERVICE_USER" tee "$CONFIG_FILE" > /dev/null <<EOF
c.ServerApp.ip = "0.0.0.0"
c.ServerApp.port = ${PORT}
c.ServerApp.open_browser = False
c.IdentityProvider.token = ""
c.PasswordIdentityProvider.hashed_password = "${HASHED_PASSWORD}"
EOF

# ---------- 4. Create systemd service ----------
echo "==> Creating systemd service at $SERVICE_FILE"

# Find absolute path to jupyter-lab (pip-installed binaries usually live in /usr/local/bin)
JUPYTER_LAB_BIN=$(command -v jupyter-lab || echo "/home/ubuntu.local/bin/jupyter-lab")

sudo tee "$SERVICE_FILE" > /dev/null <<EOF
[Unit]
Description=JupyterLab Service
After=network.target

[Service]
Type=simple
User=${SERVICE_USER}
WorkingDirectory=${USER_HOME}
ExecStart=${JUPYTER_LAB_BIN} --config=${CONFIG_FILE}
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# ---------- 5. Enable & start service ----------
echo "==> Reloading systemd and starting JupyterLab service..."
sudo systemctl daemon-reload
sudo systemctl enable jupyterlab.service
sudo systemctl restart jupyterlab.service

sleep 2
sudo systemctl status jupyterlab.service --no-pager || true

echo ""
echo "============================================================"
echo " JupyterLab is now running on port ${PORT}"
echo " Login password: ${JUPYTER_PASSWORD}"
echo " Access it at:   http://<your-server-ip>:${PORT}"
echo "============================================================"
