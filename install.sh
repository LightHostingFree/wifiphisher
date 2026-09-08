#!/usr/bin/env bash
#
# Wifiphisher - one-shot installer for Debian/Kali Linux
#
# Installs every required package that may be missing from a fresh system,
# then builds and installs the forked wifiphisher (including the two
# non-PyPI dependencies roguehostapd and pyric that upstream used to fetch
# via the now-removed pip `dependency_links` mechanism).
#
# Usage:
#   sudo ./install.sh
#
set -euo pipefail

echo "[*] Wifiphisher installer starting (apt + pip)..."

# pip on modern Debian/Ubuntu refuses to write into an externally-managed
# Python environment (PEP 668). Kali is unaffected, so add the override
# automatically only on Debian/Ubuntu based systems.
PIP_FLAGS=()
if [[ -f /etc/os-release ]] && grep -qiE "debian|ubuntu" /etc/os-release; then
  PIP_FLAGS+=(--break-system-packages)
fi

pip_install() {
  python3 -m pip install "${PIP_FLAGS[@]}" "$@"
}

# ---------------------------------------------------------------------------
# 1) System (apt) dependencies required by wifiphisher / roguehostapd
# ---------------------------------------------------------------------------
APT_PACKAGES=(
  build-essential
  python3-pip
  python3-setuptools
  python3-dev
  libnl-3-dev
  libnl-genl-3-dev
  libssl-dev
  dnsmasq
  hostapd
  aircrack-ng
  iw
  rfkill
  net-tools
)

echo "[*] Updating apt package lists..."
apt-get update -y

echo "[*] Installing system packages: ${APT_PACKAGES[*]}"
DEBIAN_FRONTEND=noninteractive apt-get install -y "${APT_PACKAGES[@]}"

# ---------------------------------------------------------------------------
# 2) Python packaging tooling (setuptools >= 60 vendors distutils, which let
#    roguehostapd's legacy build keep working on Python 3.12+)
# ---------------------------------------------------------------------------
echo "[*] Upgrading pip/setuptools/wheel..."
pip_install --upgrade pip setuptools wheel

# ---------------------------------------------------------------------------
# 3) Python dependencies
#    - roguehostapd & pyric live only on GitHub (not on PyPI), so they are
#      installed from source. roguehostapd compiles a C extension and needs
#      the libnl-3/openssl dev packages installed in step (1).
#    - scapy is pinned to 2.4.5 which matches the wifiphisher source.
# ---------------------------------------------------------------------------
echo "[*] Installing roguehostapd (from GitHub, compiled C extension)..."
pip_install "git+https://github.com/wifiphisher/roguehostapd.git"

echo "[*] Installing pyric (from GitHub)..."
pip_install "git+https://github.com/sophron/pyric.git"

echo "[*] Installing Python dependencies (scapy, tornado, pbkdf2, six)..."
pip_install "scapy==2.4.5" tornado pbkdf2 six

# ---------------------------------------------------------------------------
# 4) Install wifiphisher itself
# ---------------------------------------------------------------------------
echo "[*] Installing wifiphisher..."
pip_install .

echo "[+] Done. Run it with: sudo wifiphisher"
