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

function check_network {
    if ! getent hosts download.proxmox.com >/dev/null 2>&1; then
    echo "ERROR: DNS resolution failed."
    return 1
    fi

    if ! timeout 5 bash -c '</dev/tcp/download.proxmox.com/443' 2>/dev/null; then
        echo "ERROR: Cannot connect to Proxmox repository."
        return 1
    fi
    return 0
}

echo "[1/10] Installing required packages..."

if ! check_network; then
    echo "ERROR: Network requirements not satisfied."
    exit 1
fi

apt-get update

apt-get install -y \
    ca-certificates \
    wget \
    ifupdown2 \
    openssh-client \
    openssh-server

echo "[2/10] Installing Proxmox GPG key..."

if ! check_network; then
    echo "ERROR: Network requirements not satisfied."
    exit 1
fi

GPG_KEY="/tmp/proxmox-archive-keyring-trixie.gpg"

EXPECTED_SHA256="136673be77aba35dcce385b28737689ad64fd785a797e57897589aed08db6e45"

wget -O "$GPG_KEY" \
    https://enterprise.proxmox.com/debian/proxmox-archive-keyring-trixie.gpg

echo "$EXPECTED_SHA256  $GPG_KEY" | sha256sum -c -

install -m 0644 "$GPG_KEY" \
    /usr/share/keyrings/proxmox-archive-keyring.gpg

rm -f "$GPG_KEY"

echo "[3/10] Configuring Proxmox repository..."

cat > /etc/apt/sources.list.d/proxmox.sources <<'EOF'
Types: deb
URIs: http://download.proxmox.com/debian/pve
Suites: trixie
Components: pve-no-subscription
Architectures: arm64
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
EOF

echo "[3.1/10] Disabling Proxmox Enterprise repository..."

ENTERPRISE_FILE="/etc/apt/sources.list.d/pve-enterprise.sources"

if [ -f "$ENTERPRISE_FILE" ]; then
    sed -i '/^[[:space:]]*#/! s/^/#/' "$ENTERPRISE_FILE"
    echo "Proxmox Enterprise repository disabled."
else
    echo "Proxmox Enterprise repository not found. Skipping."
fi

echo "[4/10] Configuring Proxmox kernel protection..."

cat > /etc/apt/preferences.d/proxmox-kernel-pin <<'EOF'
Package: proxmox-kernel-*
Pin: origin download.proxmox.com
Pin-Priority: -1
EOF

echo "[5/10] Configuring Proxmox network bridge"

INTERFACES_FILE="/etc/network/interfaces"

mapfile -t PHYSICAL_INTERFACES < <(
    for path in /sys/class/net/*; do
        interface=$(basename "$path")

        [[ "$interface" == "lo" ]] && continue
        [[ -d "$path/device" ]] || continue

        echo "$interface"
    done
)

if [[ ${#PHYSICAL_INTERFACES[@]} -eq 0 ]]; then
    echo "ERROR: No physical network interfaces found."
    exit 1
fi

echo "Available physical interfaces:"

for interface in "${PHYSICAL_INTERFACES[@]}"; do
    echo " - $interface"
done

read -r -p "Select physical interface: " PHYSICAL_INTERFACE

if [[ ! " ${PHYSICAL_INTERFACES[*]} " =~ " ${PHYSICAL_INTERFACE} " ]]; then
    echo "ERROR: Invalid physical interface."
    exit 1
fi

read -r -p "Bridge name [vmbr0]: " BRIDGE_NAME
BRIDGE_NAME=${BRIDGE_NAME:-vmbr0}

if [[ ! "$BRIDGE_NAME" =~ ^vmbr[0-9]+$ ]]; then
    echo "ERROR: Invalid bridge name."
    exit 1
fi

if [[ -e "/sys/class/net/$BRIDGE_NAME" ]] ||
   grep -Eq "^(auto|iface) ${BRIDGE_NAME}([[:space:]]|$)" "$INTERFACES_FILE"; then
    echo "ERROR: Bridge already exists."
    exit 1
fi

read -r -p "Static IP with CIDR: " STATIC_IP
read -r -p "Gateway: " GATEWAY
read -r -p "DNS server: " DNS_SERVER

if [[ ! "$STATIC_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/[0-9]+$ ]] ||
   [[ ! "$GATEWAY" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] ||
   [[ ! "$DNS_SERVER" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "ERROR: Invalid network configuration."
    exit 1
fi

echo ""
echo "Bridge configuration:"
echo "Physical interface: $PHYSICAL_INTERFACE"
echo "Bridge: $BRIDGE_NAME"
echo "IP: $STATIC_IP"
echo "Gateway: $GATEWAY"
echo "DNS: $DNS_SERVER"
echo ""

read -r -p "Create and apply bridge? (y/n): " CONFIRM

if [[ "$CONFIRM" =~ ^[yY]$ ]]; then

    BACKUP_FILE="${INTERFACES_FILE}.backup.$(date +%Y%m%d%H%M%S)"
    cp -a "$INTERFACES_FILE" "$BACKUP_FILE"

    sed -i -E "/^auto / {
        s/(^|[[:space:]])${PHYSICAL_INTERFACE}([[:space:]]|$)/ /g
    }" "$INTERFACES_FILE"

    if grep -Eq "^iface ${PHYSICAL_INTERFACE} inet " "$INTERFACES_FILE"; then
        echo "ERROR: Physical interface already has an IPv4 configuration."
        cp -a "$BACKUP_FILE" "$INTERFACES_FILE"
        exit 1
    fi

    cat >> "$INTERFACES_FILE" <<EOF

iface ${PHYSICAL_INTERFACE} inet manual

auto ${BRIDGE_NAME}
iface ${BRIDGE_NAME} inet static
    address ${STATIC_IP}
    gateway ${GATEWAY}
    bridge-ports ${PHYSICAL_INTERFACE}
    bridge-stp off
    bridge-fd 0
    dns-nameservers ${DNS_SERVER}
EOF

    echo "Bridge configuration created."

    if ifreload -a; then
        echo "Network bridge applied successfully."
    else
        echo "ERROR: Failed to apply network configuration."
        cp -a "$BACKUP_FILE" "$INTERFACES_FILE"
        ifreload -a || true
        exit 1
    fi

else
    echo "Bridge configuration cancelled."
    exit 1
fi

echo "[6/10] Configuring hostname resolution..."

HOSTNAME=$(hostname)
IP_ADDRESS=$(ip -4 -o addr show dev "$BRIDGE_NAME" scope global |
    awk '{split($4,a,"/"); print a[1]}')

if [ -z "$IP_ADDRESS" ]; then
    echo "ERROR: Could not detect bridge IP."
    exit 1
fi

if ! grep -qE "^[[:space:]]*${IP_ADDRESS}[[:space:]]" /etc/hosts; then
    echo "${IP_ADDRESS} ${HOSTNAME}.local ${HOSTNAME}" >> /etc/hosts
fi

if ! getent hosts "$HOSTNAME" | grep -qvE '127\.|::1'; then
    echo "ERROR: Hostname resolution failed."
    echo "Please check /etc/hosts and your network configuration."
    exit 1
fi

echo "[7/10] Installing Proxmox VE components..."

if ! check_network; then
    echo "ERROR: Network requirements not satisfied."
    exit 1
fi

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

echo "[8/10] Generating SSH host keys..."

ssh-keygen -A

echo "[9/10] Initializing Proxmox services..."

systemctl reset-failed pve-cluster || true
systemctl enable pve-cluster
systemctl restart pve-cluster

sleep 3

if ! systemctl is-active --quiet pve-cluster; then
    echo "ERROR: pve-cluster failed to start."
    journalctl -u pve-cluster -n 30 --no-pager
    exit 1
fi

echo "[10/10] Generating Proxmox certificates..."

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
