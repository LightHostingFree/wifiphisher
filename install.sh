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
#    - scapy needs to be >= 2.5.0 because 2.4.5 vendors a six without
#      importlib find_spec support and breaks on Python 3.12+.
# ---------------------------------------------------------------------------
echo "[*] Installing roguehostapd (from GitHub, compiled C extension)..."
# Upstream roguehostapd imports configparser.SafeConfigParser, an alias that
# was removed in Python 3.14 (and is identical to ConfigParser), so patch the
# source before installing to keep the build working on Python 3.14.
ROGUEHOSTAPD_SRC="$(mktemp -d)"
git clone --depth 1 https://github.com/wifiphisher/roguehostapd.git "${ROGUEHOSTAPD_SRC}"
python3 - "${ROGUEHOSTAPD_SRC}" <<'PYEOF'
import pathlib
import sys

path = pathlib.Path(sys.argv[1]) / "roguehostapd" / "config" / "hostapdconfig.py"
text = path.read_text()
text = text.replace(
    "try:\n"
    "    from configparser import SafeConfigParser  # Python 3\n"
    "except ImportError:\n"
    "    from ConfigParser import SafeConfigParser  # Python 2",
    "from configparser import ConfigParser",
)
text = text.replace("config = SafeConfigParser()", "config = ConfigParser()")
path.write_text(text)
PYEOF
pip_install "${ROGUEHOSTAPD_SRC}"

echo "[*] Installing pyric (from GitHub)..."
pip_install "git+https://github.com/sophron/pyric.git"

echo "[*] Installing Python dependencies (scapy, tornado, pbkdf2, six)..."
pip_install "scapy>=2.5.0" tornado pbkdf2 six

# ---------------------------------------------------------------------------
# 4) Install wifiphisher itself
# ---------------------------------------------------------------------------
echo "[*] Installing wifiphisher..."
# The installer works both when run from inside a repository checkout and
# when piped straight from the web (e.g. `curl ... | sudo bash`), in which
# case there is no setup.py in the current directory.
if [ -f ./setup.py ]; then
  pip_install .
else
  git clone --depth 1 https://github.com/LightHostingFree/wifiphisher.git /opt/wifiphisher
  cd /opt/wifiphisher
  pip_install .
fi

echo "[+] Done. Run it with: sudo wifiphisher"
