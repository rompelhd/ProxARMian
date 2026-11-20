#!/bin/bash
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "ERROR: Please run this script as root."
    exit 1
fi

if [ "$(dpkg --print-architecture)" != "arm64" ]; then
    echo "ERROR: This script is intended for ARM64 systems."
    exit 1
fi

HOSTNAME=$(hostname)
IP_ADDRESS=$(hostname -I | awk '{print $1}')

if [ -z "$IP_ADDRESS" ]; then
    echo "ERROR: Could not detect the system IP address."
    exit 1
fi

echo "[1/9] Installing required packages..."

apt-get update

apt-get install -y \
    ca-certificates \
    wget \
    openssh-client \
    openssh-server

echo "[2/9] Installing Proxmox GPG key..."

wget -O /tmp/proxmox-release-trixie.gpg \
    https://enterprise.proxmox.com/debian/proxmox-release-trixie.gpg

install -m 0644 \
    /tmp/proxmox-release-trixie.gpg \                                                               
    /usr/share/keyrings/proxmox-archive-keyring.gpg

rm -f /tmp/proxmox-release-trixie.gpg

echo "[3/9] Configuring Proxmox repository..."

cat > /etc/apt/sources.list.d/proxmox.sources <<'EOF'
Types: deb
URIs: http://download.proxmox.com/debian/pve
Suites: trixie
Components: pve-no-subscription
Architectures: arm64
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
EOF

echo "[4/9] Configuring Proxmox kernel protection..."

cat > /etc/apt/preferences.d/proxmox-kernel-pin <<'EOF'
Package: proxmox-kernel-*
Pin: origin download.proxmox.com
Pin-Priority: -1
EOF

echo "[5/9] Configuring hostname resolution..."

if ! grep -qE "^[[:space:]]*${IP_ADDRESS}[[:space:]]" /etc/hosts; then
    echo "${IP_ADDRESS} ${HOSTNAME}.local ${HOSTNAME}" >> /etc/hosts
fi

if ! getent hosts "$HOSTNAME" | grep -qvE '127\.|::1'; then
    echo "ERROR: Hostname resolution failed."
    echo "Please check /etc/hosts and your network configuration."
    exit 1
fi

echo "[6/9] Installing Proxmox VE components..."

apt-get update

apt-get install -y --no-install-recommends \
    pve-manager \
    pve-cluster \
    pve-container \
    pve-qemu-kvm \
    qemu-server \
    pve-ha-manager \
    pve-firewall \
    novnc-pve

echo "[7/9] Generating SSH host keys..."

ssh-keygen -A

echo "[8/9] Initializing Proxmox services..."

systemctl reset-failed pve-cluster || true
systemctl enable pve-cluster
systemctl restart pve-cluster

sleep 3

if ! systemctl is-active --quiet pve-cluster; then
    echo "ERROR: pve-cluster failed to start."
    journalctl -u pve-cluster -n 30 --no-pager
    exit 1
fi

echo "[9/9] Generating Proxmox certificates..."

pvecm updatecerts --force

systemctl enable pvedaemon pveproxy
systemctl restart pvedaemon
systemctl restart pveproxy

echo ""
echo "Checking Proxmox web interface..."

sleep 3

if systemctl is-active --quiet pveproxy && \
   ss -tln | grep -q ':8006'; then

    echo "=================================================="
    echo " Proxmox VE configuration completed!"
    echo "=================================================="
    echo ""
    echo " Web interface:"
    echo " https://${IP_ADDRESS}:8006"
    echo ""
    echo " Username: root"
    echo " Authentication: Linux PAM"
    echo ""
else
    echo "WARN: The Proxmox web interface is not listening."
    echo "Check the logs:"
    echo "journalctl -u pveproxy -n 50 --no-pager"
fi
