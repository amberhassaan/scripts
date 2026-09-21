#!/bin/bash
# =============================================================================
# Colossus 2U1G-B650 Setup Script — P4 + CUDA Driver + CUDA Toolkit
# Machine: Ubuntu 26.04, RTX 5070 (Blackwell GB205)
# Author: Auto-generated for idemeshko
# Date: 2026-09-15
#
# Usage:
#   chmod +x colossus-setup.sh
#   ./colossus-setup.sh          # Run all steps
#   ./colossus-setup.sh p4       # P4 only
#   ./colossus-setup.sh driver   # Driver only
#   ./colossus-setup.sh cuda     # CUDA Toolkit only
# =============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

# ---------------------------------------------------------------------------
# 1. PERFORCE (P4) CLIENT
# ---------------------------------------------------------------------------
install_p4() {
    info "=== Installing Perforce (P4) CLI ==="

    # Check if already installed
    if command -v p4 &>/dev/null; then
        warn "p4 already installed: $(p4 -V 2>&1 | head -1)"
        read -rp "Reinstall? [y/N] " ans
        [[ "$ans" =~ ^[Yy] ]] || { info "Skipping P4 install."; configure_p4; return; }
    fi

    # Download latest P4 client (r24.2)
    info "Downloading P4 client r24.2..."
    sudo wget -q https://cdist2.perforce.com/perforce/r24.2/bin.linux26x86_64/p4 \
        -O /usr/local/bin/p4
    sudo chmod 755 /usr/local/bin/p4

    info "P4 installed: $(p4 -V 2>&1 | head -1)"
    configure_p4
}

configure_p4() {
    info "=== Configuring P4 environment ==="

    # Create .p4config if it doesn't exist
    if [[ ! -f "$HOME/.p4config" ]]; then
        info "Creating $HOME/.p4config..."

        # Determine P4 proxy — choose closest to your location
        # USA-CA → use p4proxy-sc (Santa Clara) or p4sw
        cat > "$HOME/.p4config" <<EOF
P4USER=${USER}
P4CLIENT=${USER}_colossus
P4PORT=p4sw:2006
P4EDITOR=vim
EOF
        info "Created .p4config with P4PORT=p4sw:2006 (Santa Clara)"
        info "  Other proxies: p4proxy-pdx:2006 (Portland), p4proxy-pune:2006 (Pune),"
        info "  p4proxy-taipei:2006 (Taipei), p4proxy-redmond:2006 (Redmond)"
    else
        warn ".p4config already exists:"
        cat "$HOME/.p4config"
    fi

    # Set P4CONFIG in shell profile
    if ! grep -q 'P4CONFIG' "$HOME/.bashrc" 2>/dev/null; then
        info "Adding P4 env vars to .bashrc..."
        cat >> "$HOME/.bashrc" <<'EOF'

# --- Perforce ---
export P4CONFIG=$HOME/.p4config
export P4ROOT=$HOME/p4
EOF
    fi

    export P4CONFIG="$HOME/.p4config"

    # Create P4ROOT
    mkdir -p "$HOME/p4"
    export P4ROOT="$HOME/p4"

    info "P4 setup complete."
    info "Next steps:"
    info "  1) source ~/.bashrc"
    info "  2) p4 login -a          # Use your Windows/AD password"
    info "  3) p4 client -t minimal_build_template \${USER}_colossus"
    info "     → Set Root: to $HOME/p4"
    info "     → Delete the Host: line"
    info "  4) p4 sync"
}

# ---------------------------------------------------------------------------
# 2. NVIDIA GPU DRIVER (open kernel modules for Blackwell)
# ---------------------------------------------------------------------------
install_driver() {
    info "=== Installing NVIDIA GPU Driver (open kernel modules) ==="

    # Check current driver
    if nvidia-smi &>/dev/null; then
        CURRENT_VER=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null || echo "unknown")
        warn "Driver already working: $CURRENT_VER"
        read -rp "Reinstall? [y/N] " ans
        [[ "$ans" =~ ^[Yy] ]] || { info "Skipping driver install."; return; }
    fi

    # Install build dependencies
    info "Installing build dependencies..."
    sudo apt-get update -qq
    sudo apt-get install -y -qq build-essential dkms linux-headers-$(uname -r)

    # Determine driver version — use 595.91.07 (matches CUDA 13.2)
    DRIVER_VER="${DRIVER_VER:-595.91.07}"
    RUN_FILE="NVIDIA-Linux-x86_64-${DRIVER_VER}.run"
    RUN_URL="https://us.download.nvidia.com/XFree86/Linux-x86_64/${DRIVER_VER}/${RUN_FILE}"

    # Download if not present
    if [[ ! -f "/tmp/${RUN_FILE}" ]]; then
        info "Downloading driver ${DRIVER_VER}..."
        wget -q --show-progress -O "/tmp/${RUN_FILE}" "${RUN_URL}" || \
            error "Download failed. Check version at https://www.nvidia.com/en-us/drivers/unix/"
        chmod +x "/tmp/${RUN_FILE}"
    else
        info "Using existing /tmp/${RUN_FILE}"
    fi

    # Stop display manager if running
    if systemctl is-active --quiet gdm3 2>/dev/null; then
        warn "Stopping display manager..."
        sudo systemctl stop gdm3 || true
    fi

    # Unload existing modules
    info "Unloading existing nvidia modules..."
    sudo rmmod nvidia_uvm nvidia_drm nvidia_modeset nvidia 2>/dev/null || true

    # Install with OPEN kernel modules (CRITICAL for Blackwell/GB205!)
    info "Installing driver ${DRIVER_VER} with --kernel-module-type=open ..."
    sudo bash "/tmp/${RUN_FILE}" \
        --dkms \
        --no-cc-version-check \
        --kernel-module-type=open \
        --no-x-check \
        --silent

    # Load and verify
    sudo modprobe nvidia
    info "Driver installed. Verifying..."
    nvidia-smi || error "nvidia-smi failed after install!"

    # Enable persistence mode
    sudo nvidia-smi -pm 1
    info "Driver install complete. Persistence mode enabled."
}

# ---------------------------------------------------------------------------
# 3. CUDA TOOLKIT (toolkit only — driver already installed separately)
# ---------------------------------------------------------------------------
install_cuda_toolkit() {
    info "=== Installing CUDA Toolkit ==="

    # Verify driver is working first
    nvidia-smi &>/dev/null || error "nvidia-smi not working. Install driver first."

    CUDA_VER="${CUDA_VER:-13-2}"  # dash-separated for apt
    CUDA_DOT="${CUDA_VER//-/.}"   # dot-separated for paths

    # Check if already installed
    if command -v nvcc &>/dev/null; then
        warn "nvcc already installed: $(nvcc --version 2>&1 | tail -1)"
        read -rp "Reinstall? [y/N] " ans
        [[ "$ans" =~ ^[Yy] ]] || { info "Skipping CUDA Toolkit."; return; }
    fi

    # Determine Ubuntu codename for repo
    # Ubuntu 26.04 → might need ubuntu2604 or fall back to ubuntu2404
    DISTRO="ubuntu2604"
    ARCH="x86_64"

    # Install CUDA keyring
    info "Adding CUDA repository..."
    KEYRING_URL="https://developer.download.nvidia.com/compute/cuda/repos/${DISTRO}/${ARCH}/cuda-keyring_1.1-1_all.deb"

    # Try ubuntu2604 first, fall back to ubuntu2404
    if ! wget -q --spider "${KEYRING_URL}" 2>/dev/null; then
        warn "No repo for ubuntu2604, trying ubuntu2404..."
        DISTRO="ubuntu2404"
        KEYRING_URL="https://developer.download.nvidia.com/compute/cuda/repos/${DISTRO}/${ARCH}/cuda-keyring_1.1-1_all.deb"
    fi

    wget -q -O /tmp/cuda-keyring.deb "${KEYRING_URL}" || \
        error "Failed to download CUDA keyring from ${KEYRING_URL}"
    sudo dpkg -i /tmp/cuda-keyring.deb
    sudo apt-get update -qq

    # Install CUDA Toolkit ONLY (no driver — we already have it via .run)
    # As of CUDA 13.4+, 'apt install cuda' does NOT pull the driver.
    # For older branches, use 'cuda-toolkit' explicitly.
    info "Installing cuda-toolkit-${CUDA_VER}..."
    sudo apt-get install -y cuda-toolkit-${CUDA_VER} || {
        warn "Versioned package failed, trying unversioned cuda-toolkit..."
        sudo apt-get install -y cuda-toolkit
    }

    # Set up environment
    if ! grep -q 'cuda' "$HOME/.bashrc" 2>/dev/null; then
        info "Adding CUDA to .bashrc..."
        cat >> "$HOME/.bashrc" <<EOF

# --- CUDA Toolkit ---
export PATH=/usr/local/cuda/bin\${PATH:+:\${PATH}}
export LD_LIBRARY_PATH=/usr/local/cuda/lib64\${LD_LIBRARY_PATH:+:\${LD_LIBRARY_PATH}}
EOF
    fi

    export PATH=/usr/local/cuda/bin${PATH:+:${PATH}}
    export LD_LIBRARY_PATH=/usr/local/cuda/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}

    info "CUDA Toolkit installed."
    nvcc --version 2>/dev/null || warn "nvcc not found — check /usr/local/cuda/bin"

    info "Verifying with deviceQuery..."
    if [[ -d /usr/local/cuda/extras/demo_suite ]]; then
        /usr/local/cuda/extras/demo_suite/deviceQuery || true
    else
        info "demo_suite not found. Quick compile test:"
        cat > /tmp/cuda_hello.cu <<'CUEOF'
#include <stdio.h>
__global__ void hello() { printf("Hello from GPU thread %d!\n", threadIdx.x); }
int main() {
    hello<<<1, 4>>>();
    cudaDeviceSynchronize();
    return 0;
}
CUEOF
        nvcc -o /tmp/cuda_hello /tmp/cuda_hello.cu && /tmp/cuda_hello || \
            warn "CUDA compile test failed — check your setup"
    fi

    info "CUDA Toolkit setup complete."
    rm -rf NVIDIA-Linux-x86_64-595* cuda-keyring*
    echo 'export PATH=/usr/local/cuda/bin:$PATH' >> ~/.bashrc
}

# ---------------------------------------------------------------------------
# 4. BUILD DEPENDENCIES (common for GPU driver development)
# ---------------------------------------------------------------------------
install_build_deps() {
    info "=== Installing common build dependencies ==="
    sudo apt-get update -qq
    sudo apt-get install -y \
        build-essential cmake ninja-build git curl wget \
        gcc g++ g++-multilib gcc-multilib \
        dkms linux-headers-$(uname -r) \
        libssl-dev libffi-dev \
        python3-dev python3-pip python3-venv \
        libc6-dev libncurses-dev \
        pkg-config autoconf automake libtool \
        flex bison bc \
        vim tmux htop tree
    info "Build dependencies installed."
}

# ---------------------------------------------------------------------------
# 5. FIX UNPRIVILEGED USER NAMESPACES (required for unix-build on Ubuntu 23.10+)
# ---------------------------------------------------------------------------
fix_userns() {
    info "=== Fixing unprivileged user namespaces for unix-build ==="
    sudo sysctl -w kernel.apparmor_restrict_unprivileged_unconfined=0
    sudo sysctl -w kernel.apparmor_restrict_unprivileged_userns=0
    # Persist across reboots
    sudo sh -c 'echo kernel.apparmor_restrict_unprivileged_unconfined=0 >> /etc/sysctl.d/10-unix-build.conf'
    sudo sh -c 'echo kernel.apparmor_restrict_unprivileged_userns=0 >> /etc/sysctl.d/10-unix-build.conf'
    info "User namespace restrictions disabled (persisted via /etc/sysctl.d/10-unix-build.conf)."
}

# ---------------------------------------------------------------------------
# MAIN
# ---------------------------------------------------------------------------
main() {
    local target="${1:-all}"

    info "Colossus Setup — $(hostname) — $(date)"
    info "Target: $target"
    echo ""

    case "$target" in
        p4|perforce)
            install_p4
            ;;
        driver)
            install_driver
            ;;
        cuda|toolkit)
            install_cuda_toolkit
            ;;
        deps)
            install_build_deps
            ;;
        userns|namespace)
            fix_userns
            ;;
        all)
            install_build_deps
            fix_userns
            install_p4
            install_driver
            install_cuda_toolkit
            echo ""
            info "============================================"
            info "  Setup complete! Run: source ~/.bashrc"
            info "  Then: p4 login -a"
            info "============================================"
            ;;
        *)
            echo "Usage: $0 [all|p4|driver|cuda|deps]"
            exit 1
            ;;
    esac
}

main "$@"
