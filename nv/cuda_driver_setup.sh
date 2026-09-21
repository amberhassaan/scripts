#!/bin/bash
# =============================================================================
# bugfix_main — Full Linux Setup, Build, and Validation
# Based on: bugfix_main_onboarding.md (2026-09-08)
#
# Machine: Colossus 2U1G-B650, Ubuntu 26.04, RTX 5070 (Blackwell GB205)
# User:    idemeshko
#
# Usage:
#   chmod +x bugfix_main_setup.sh
#   ./bugfix_main_setup.sh                # Interactive — runs all steps
#   ./bugfix_main_setup.sh p4             # P4 client config + sync only
#   ./bugfix_main_setup.sh compiler       # Download GPGPU compiler export
#   ./bugfix_main_setup.sh build          # Build driver + runtime + tests
#   ./bugfix_main_setup.sh build-driver   # Build debug + release driver only
#   ./bugfix_main_setup.sh build-runtime  # Build CUDA runtime + tools only
#   ./bugfix_main_setup.sh build-tests    # Build smcTest + perf_bugs only
#   ./bugfix_main_setup.sh test           # Run smcTest sanity
#   ./bugfix_main_setup.sh env            # Print/verify environment only
#   ./bugfix_main_setup.sh record         # Record validated baseline identity
#
# Placeholders (auto-filled from $USER):
#   <username>   = idemeshko
#   <clientname> = idemeshko-cuda
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration — edit these if needed
# ---------------------------------------------------------------------------
USERNAME="${USER}"
CLIENTNAME="${USERNAME}_colossus"
DEV_BASE="/var/tmp/${USERNAME}/cuda"
SW="${DEV_BASE}"
COMPILER_BASE="${DEV_BASE}/gpgpu_compiler"
P4PORT_VAL="p4sw.nvidia.com:2006"
BUILD_JOBS=16
SHELL_RC="$HOME/.zshrc"    # Change to .bashrc if you use bash

# Derived paths
DEBUG_DRIVER="${SW}/dev/gpu_drv/bugfix_main/drivers/gpgpu/_out/Linux_amd64_debug"
RELEASE_DRIVER="${SW}/dev/gpu_drv/bugfix_main/drivers/gpgpu/_out/Linux_amd64_release"
CUDA_BIN="${SW}/gpgpu/bin/x86_64_Linux_debug"

# ---------------------------------------------------------------------------
# Colors / helpers
# ---------------------------------------------------------------------------
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; CYAN='\033[0;36m'; NC='\033[0m'
info()    { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }
section() { echo -e "\n${CYAN}════════════════════════════════════════════════════════════${NC}"; echo -e "${CYAN}  $*${NC}"; echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}\n"; }
ask_continue() { read -rp "Continue? [Y/n] " ans; [[ "$ans" =~ ^[Nn] ]] && { info "Skipped."; return 1; }; return 0; }

# ---------------------------------------------------------------------------
# 0. Prerequisites check
# ---------------------------------------------------------------------------
check_prerequisites() {
    section "0. Checking prerequisites"

    # p4 client
    if ! command -v p4 &>/dev/null; then
        error "p4 not found in PATH. Install it first (see colossus-setup.sh p4)."
    fi
    info "p4 client: $(p4 -V 2>&1 | head -1)"

    # Disk space (warn if < 100 GB free)
    local free_gb
    free_gb=$(df -BG --output=avail "${DEV_BASE%/*}" 2>/dev/null | tail -1 | tr -d ' G' || echo 0)
    if (( free_gb < 100 )); then
        warn "Only ${free_gb} GB free on $(df -h --output=target "${DEV_BASE%/*}" | tail -1). Large sync ahead."
    else
        info "Disk space: ${free_gb} GB free — OK"
    fi

    # nvidia-smi
    if nvidia-smi &>/dev/null; then
        info "GPU driver: $(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null)"
    else
        warn "nvidia-smi not working — driver builds will succeed but tests won't run."
    fi

    # Build tools
    for tool in gcc g++ make python3; do
        command -v "$tool" &>/dev/null && info "$tool: $(command -v $tool)" || warn "$tool not found"
    done
}

# ---------------------------------------------------------------------------
# 1. Configure P4 connection
# ---------------------------------------------------------------------------
configure_p4() {
    section "1. Configuring Perforce connection"

    mkdir -p "${DEV_BASE}"
    mkdir -p "${SW}"
    cd "${DEV_BASE}"

    info "Created workspace directories:"
    info "  DEV_BASE: ${DEV_BASE}"
    info "  SW (P4 root): ${SW}"

    # Set P4CONFIG globally
    p4 set P4CONFIG=.p4config
    info "P4CONFIG set to .p4config"

    # Create .p4config in the workspace root
    if [[ -f "${DEV_BASE}/.p4config" ]]; then
        warn "Existing .p4config found:"
        cat "${DEV_BASE}/.p4config"
        echo ""
        ask_continue || return
    fi

    cat > "${DEV_BASE}/.p4config" <<EOF
P4PORT=${P4PORT_VAL}
P4USER=${USERNAME}
P4CLIENT=${CLIENTNAME}
EOF

    info "Created ${DEV_BASE}/.p4config"
    cat "${DEV_BASE}/.p4config"
    echo ""

    # Verify P4 reads the config
    cd "${DEV_BASE}"
    info "P4 settings:"
    p4 set

    # Login
    info "Authenticating to Perforce..."
    p4 login
    p4 login -s

    # Verify connection
    info "Server info:"
    p4 info
}

# ---------------------------------------------------------------------------
# 2. Create the P4 client
# ---------------------------------------------------------------------------

create_p4_client() {
    section "2. Creating Perforce client"

    cd "${DEV_BASE}"

    # Check if client already exists
    if p4 client -o "${CLIENTNAME}" 2>/dev/null | grep -q "^Update:"; then
        warn "Client '${CLIENTNAME}' already exists."
        info "Current root:"
        p4 client -o "${CLIENTNAME}" | sed -n '/^Root:/p'
        echo ""
        info "To edit: p4 client ${CLIENTNAME}"
        ask_continue || return
    fi

    info "Creating client from template 'idemeshko'..."
    info ""
    info "  In the editor that opens, verify/set:"
    info "    Client: ${CLIENTNAME}"
    info "    Owner:  ${USERNAME}"
    info "    Root:   ${SW}"
    info "    (Delete the Host: line)"
    info ""
    info "  The View will be copied from the idemeshko template."
    info ""
    read -rp "Press Enter to open the client editor..." _

    p4 client -t idemeshko "${CLIENTNAME}"

    # Validate the saved client
    info "Validating client..."
    local saved_root
    saved_root=$(p4 client -o "${CLIENTNAME}" | sed -n 's/^Root:\s*//p' | xargs)

    if [[ "${saved_root}" != "${SW}" ]]; then
        warn "Client root is '${saved_root}', expected '${SW}'"
        warn "Run: p4 client ${CLIENTNAME}  — and fix Root:"
    else
        info "Client root: ${saved_root} ✓"
    fi

    # Verify key path mappings
    verify_required_mappings

    info "All required paths are mapped ✓"
}

# ---------------------------------------------------------------------------
# 2b. Verify required path mappings
# ---------------------------------------------------------------------------
verify_required_mappings() {
    info "Verifying depot-to-local mappings..."
    local paths_ok=true
    for depot_path in \
        "//sw/dev/gpu_drv/bugfix_main/drivers/gpgpu/..." \
        "//sw/gpgpu/build/config/driver_root.mk" \
        "//sw/tools/linux/unix-build/..." \
        "//sw/dev/gpu_drv/bugfix_main/drivers/gpgpu/makefileAltSourceOld.nvmk" \
        "//sw/gpgpu/cuda/apps/perf_bugs/..." \
        "//sw/pvt/ebendler/dvsfetch.py"; do

        local where_out
        where_out=$(p4 where "${depot_path}" 2>&1 || true)
        if echo "${where_out}" | grep -qi "not in client view\|no such file"; then
            warn "NOT MAPPED: ${depot_path}"
            paths_ok=false
        else
            local local_path
            local_path=$(echo "${where_out}" | awk '{print $3}' | head -1)
            info "  ${depot_path} → ${local_path}"
        fi
    done

    if [[ "${paths_ok}" == "false" ]]; then
        error "Some required paths are not in the client view. Fix with: p4 client ${CLIENTNAME}"
    fi
}

# ---------------------------------------------------------------------------
# 3. Sync the workspace
# ---------------------------------------------------------------------------
sync_workspace() {
    section "3. Syncing workspace"

    mkdir -p "${SW}"
    cd "${SW}"

    # Check for any opened files
    local opened
    opened=$(p4 opened 2>&1 || true)
    if [[ "${opened}" != *"not opened"* && "${opened}" != *"file(s) not opened"* && -n "${opened}" ]]; then
        warn "You have opened files:"
        echo "${opened}"
        warn "Shelve or save them before continuing."
        ask_continue || return
    fi

    info "Starting p4 sync (this may take a long time on first run)..."
    info "Working directory: ${SW}"
    p4 sync

    # Verify synced trees
    info "Verifying synced trees..."
    local all_ok=true

    test -f "${SW}/gpgpu/build/config/driver_root.mk" && \
        info "  CUDA build tree present ✓" || { warn "  CUDA build tree MISSING"; all_ok=false; }

    test -d "${SW}/dev/gpu_drv/bugfix_main/drivers/gpgpu" && \
        info "  Driver tree present ✓" || { warn "  Driver tree MISSING"; all_ok=false; }

    test -x "${SW}/tools/linux/unix-build/unix-build" && \
        info "  unix-build present ✓" || { warn "  unix-build MISSING"; all_ok=false; }

    test -d "${SW}/gpgpu/cuda/apps/perf_bugs" && \
        info "  perf_bugs present ✓" || { warn "  perf_bugs MISSING — will try targeted sync"; sync_perf_bugs; }

    if [[ "${all_ok}" == "false" ]]; then
        error "Sync incomplete. Check p4 sync errors above."
    fi

    # Confirm files are current
    info "Checking for pending updates..."
    p4 sync -n //sw/dev/gpu_drv/bugfix_main/... 2>&1 | tail -3
    p4 sync -n //sw/gpgpu/... 2>&1 | tail -3

    info "Workspace sync complete ✓"
}

# Targeted sync for perf_bugs in case the template view didn't include it
sync_perf_bugs() {
    info "Attempting targeted sync of perf_bugs..."
    # Check if it's mapped
    local where_out
    where_out=$(p4 where "//sw/gpgpu/cuda/apps/perf_bugs/..." 2>&1 || true)
    if echo "${where_out}" | grep -qi "not in client view"; then
        warn "perf_bugs is NOT in your client view."
        warn "Add this line to your client view (p4 client ${CLIENTNAME}):"
        warn "  //sw/gpgpu/cuda/apps/perf_bugs/... //${CLIENTNAME}/gpgpu/cuda/apps/perf_bugs/..."
        warn "Then re-run: p4 sync //sw/gpgpu/cuda/apps/perf_bugs/..."
    else
        p4 sync "//sw/gpgpu/cuda/apps/perf_bugs/..." || warn "perf_bugs sync failed"
        test -d "${SW}/gpgpu/cuda/apps/perf_bugs" && info "  perf_bugs present ✓"
    fi
}

# ---------------------------------------------------------------------------
# 4. Configure persistent shell environment
# ---------------------------------------------------------------------------
configure_shell_env() {
    section "4. Configuring shell environment"

    local marker="# --- bugfix_main dev environment ---"

    if grep -qF "${marker}" "${SHELL_RC}" 2>/dev/null; then
        warn "Shell environment block already in ${SHELL_RC}"
        ask_continue || return
    fi

    info "Appending environment to ${SHELL_RC}..."
    cat >> "${SHELL_RC}" <<EOF

${marker}
export SW="${SW}"
export PATH="\$SW/tools/linux/unix-build:\$PATH"
# Set after compiler export is downloaded (step 5):
# export GPGPU_COMPILER_EXPORT="${COMPILER_BASE}/x86_64_Linux_release"
EOF

    # Source it
    export SW="${SW}"
    export PATH="${SW}/tools/linux/unix-build:${PATH}"

    info "Verifying unix-build..."
    if command -v unix-build &>/dev/null; then
        unix-build --version
    else
        warn "unix-build not found — will be available after sync"
    fi
}

# ---------------------------------------------------------------------------
# 5. Download GPGPU compiler export
# ---------------------------------------------------------------------------
download_compiler() {
    section "5. Downloading GPGPU compiler export"

    mkdir -p "${COMPILER_BASE}"

    if [[ -d "${COMPILER_BASE}/x86_64_Linux_release/bin" ]] && \
       [[ -f "${COMPILER_BASE}/x86_64_Linux_release/bin/nvcc.profile" ]]; then
        warn "Compiler export already present at ${COMPILER_BASE}/x86_64_Linux_release"
        ask_continue || return
    fi

    local dvsfetch="${SW}/pvt/ebendler/dvsfetch.py"
    if [[ ! -f "${dvsfetch}" ]]; then
        error "dvsfetch.py not found at ${dvsfetch}. Sync the workspace first."
    fi

    info "Running dvsfetch.py (this downloads the gpu_drv_bugfix_main release compiler)..."
    python3 "${dvsfetch}" "${COMPILER_BASE}"

    # Verify
    if [[ -d "${COMPILER_BASE}/x86_64_Linux_release/bin" ]] && \
       [[ -f "${COMPILER_BASE}/x86_64_Linux_release/bin/nvcc.profile" ]]; then
        info "GPGPU compiler export present ✓"
    else
        error "Compiler export failed — check dvsfetch.py output above."
    fi

    # Update shell config
    export GPGPU_COMPILER_EXPORT="${COMPILER_BASE}/x86_64_Linux_release"

    # Uncomment the line in shell RC if it was commented
    if grep -q "^# export GPGPU_COMPILER_EXPORT" "${SHELL_RC}" 2>/dev/null; then
        sed -i "s|^# export GPGPU_COMPILER_EXPORT=.*|export GPGPU_COMPILER_EXPORT=\"${COMPILER_BASE}/x86_64_Linux_release\"|" "${SHELL_RC}"
        info "Updated ${SHELL_RC} with GPGPU_COMPILER_EXPORT"
    elif ! grep -q "GPGPU_COMPILER_EXPORT" "${SHELL_RC}" 2>/dev/null; then
        echo "export GPGPU_COMPILER_EXPORT=\"${COMPILER_BASE}/x86_64_Linux_release\"" >> "${SHELL_RC}"
        info "Added GPGPU_COMPILER_EXPORT to ${SHELL_RC}"
    fi

    info "Compiler export ready: ${GPGPU_COMPILER_EXPORT}"
}

# ---------------------------------------------------------------------------
# 6. Pre-build checks
# ---------------------------------------------------------------------------
pre_build_checks() {
    section "6. Pre-build checks"

    # Source environment
    export SW="${SW}"
    export PATH="${SW}/tools/linux/unix-build:${PATH}"
    export GPGPU_COMPILER_EXPORT="${COMPILER_BASE}/x86_64_Linux_release"

    local all_ok=true

    test -d "${SW}" && \
        info "SW present ✓" || { warn "SW directory missing"; all_ok=false; }

    test -x "${SW}/tools/linux/unix-build/unix-build" && \
        info "unix-build present ✓" || { warn "unix-build missing"; all_ok=false; }

    test -d "${GPGPU_COMPILER_EXPORT}" && \
        info "compiler export present ✓" || { warn "compiler export missing"; all_ok=false; }

    test -d "${SW}/dev/gpu_drv/bugfix_main" && \
        info "driver source present ✓" || { warn "driver source missing"; all_ok=false; }

    test -d "${SW}/gpgpu/cuda" && \
        info "CUDA source present ✓" || { warn "CUDA source missing"; all_ok=false; }

    test -d "${SW}/gpgpu/cuda/apps/perf_bugs" && \
        info "perf_bugs source present ✓" || { warn "perf_bugs source missing"; all_ok=false; }

    echo ""
    info "unix-build version:"
    unix-build --version 2>/dev/null || warn "unix-build --version failed"

    echo ""
    info "Opened files:"
    p4 opened 2>&1 || true

    if [[ "${all_ok}" == "false" ]]; then
        error "Pre-build checks failed. Fix the issues above before building."
    fi

    info "All pre-build checks passed ✓"
}

# ---------------------------------------------------------------------------
# 7. Build debug CUDA user-mode driver
# ---------------------------------------------------------------------------
build_debug_driver() {
    section "7. Building DEBUG CUDA user-mode driver"

    cd "${SW}/dev/gpu_drv/bugfix_main"

    info "unix-build nvmake cuda debug amd64 (-j${BUILD_JOBS})..."
    unix-build --tools "${SW}/tools" nvmake \
        NV_COLOR_OUTPUT=1 \
        -j${BUILD_JOBS} \
        cuda debug amd64 compilecommands

    info "Verifying debug build output..."
    if find "${DEBUG_DRIVER}" -maxdepth 1 -name 'libcuda.so*' -print -quit 2>/dev/null | grep -q .; then
        info "libcuda.so found in ${DEBUG_DRIVER} ✓"
        find "${DEBUG_DRIVER}" -maxdepth 1 -name 'libcuda.so*' -print
    else
        error "libcuda.so NOT found in ${DEBUG_DRIVER}"
    fi
}

# ---------------------------------------------------------------------------
# 8. Build release driver
# ---------------------------------------------------------------------------
build_release_driver() {
    section "8. Building RELEASE CUDA driver"

    cd "${SW}/dev/gpu_drv/bugfix_main"

    info "unix-build nvmake cuda release amd64 (-j${BUILD_JOBS})..."
    unix-build --tools "${SW}/tools" nvmake cuda -j${BUILD_JOBS} amd64 release

    info "Verifying release build output..."
    if find "${RELEASE_DRIVER}" -maxdepth 1 -name 'libcuda.so*' -print -quit 2>/dev/null | grep -q .; then
        info "libcuda.so found in ${RELEASE_DRIVER} ✓"
    else
        warn "libcuda.so NOT found in ${RELEASE_DRIVER} — check build output."
    fi
}

# ---------------------------------------------------------------------------
# 9. Build CUDA runtime and tools
# ---------------------------------------------------------------------------
build_cuda_runtime() {
    section "9. Building CUDA runtime and tools"

    cd "${SW}/gpgpu/cuda"

    # Use make-4.4 with pipe jobserver (NOT make-4.00)
    local make44="${SW}/gpgpu/build/make-4.4"
    if [[ ! -x "${make44}" ]]; then
        error "make-4.4 not found at ${make44}. Sync the workspace first."
    fi

    info "Building with make-4.4 --jobserver-style=pipe -j${BUILD_JOBS}..."
    "${make44}" \
        --jobserver-style=pipe \
        -j${BUILD_JOBS} \
        UNSHARE_NAMESPACES=1 \
        DRIVER_ROOT="${SW}/dev/gpu_drv/bugfix_main"

    info "Verifying CUDA runtime output..."
    local cuda_bin="${SW}/gpgpu/bin/x86_64_Linux_debug"

    for lib in libcudart.so libcudart_static.a libcudadevrt.a; do
        if find "${cuda_bin}" -name "${lib}*" -print -quit 2>/dev/null | grep -q .; then
            info "  ${lib} ✓"
        else
            warn "  ${lib} not found"
        fi
    done

    if [[ -x "${cuda_bin}/nvcc" ]]; then
        info "  nvcc ✓"
    else
        warn "  nvcc not found in ${cuda_bin}"
    fi
}

# ---------------------------------------------------------------------------
# 10. Build smcTest + perf_bugs
# ---------------------------------------------------------------------------
build_tests() {
    section "10. Building smcTest and perf_bugs"

    local make44="${SW}/gpgpu/build/make-4.4"

    # --- smcTest ---
    info "Building smcTest..."
    cd "${SW}/gpgpu/cuda/apps"

    "${make44}" \
        --jobserver-style=pipe \
        -j${BUILD_JOBS} \
        smcTest \
        UNSHARE_NAMESPACES=1 \
        DRIVER_ROOT="${SW}/dev/gpu_drv/bugfix_main"

    test -x "${CUDA_BIN}/smcTest" && \
        info "smcTest built ✓" || warn "smcTest executable not found"

    # --- perf_bugs ---
    info "Building perf_bugs..."
    cd "${SW}/gpgpu/cuda/apps"

    "${make44}" \
        --jobserver-style=pipe \
        -j${BUILD_JOBS} \
        perf_bugs \
        UNSHARE_NAMESPACES=1 \
        DRIVER_ROOT="${SW}/dev/gpu_drv/bugfix_main"

    if find "${CUDA_BIN}" -name 'perf_bugs*' -type f -executable -print -quit 2>/dev/null | grep -q .; then
        info "perf_bugs built ✓"
        find "${CUDA_BIN}" -name 'perf_bugs*' -type f -executable -print
    else
        warn "perf_bugs executable not found — check build output"
    fi
}

# ---------------------------------------------------------------------------
# 11-12. Run smcTest sanity
# ---------------------------------------------------------------------------
run_smctest() {
    section "11-12. Running smcTest sanity"

    # Set LD_LIBRARY_PATH for this test session ONLY
    export LD_LIBRARY_PATH="${DEBUG_DRIVER}:${CUDA_BIN}${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"

    info "Using locally built user-mode driver:"
    ldd "${CUDA_BIN}/smcTest" 2>/dev/null | grep libcuda || warn "libcuda not resolved"

    # Start MPS
    export CUDA_MPS_PIPE_DIRECTORY=/tmp/smcTestPipe
    info "Starting MPS control daemon (pipe: ${CUDA_MPS_PIPE_DIRECTORY})..."
    nvidia-cuda-mps-control -d || warn "MPS daemon may already be running"

    # Run
    info "Running: smcTest --enable SingleCtxTest"
    cd "${CUDA_BIN}"
    local rc=0
    ./smcTest --enable SingleCtxTest || rc=$?

    # Stop MPS
    info "Stopping MPS..."
    echo quit | nvidia-cuda-mps-control 2>/dev/null || true
    unset CUDA_MPS_PIPE_DIRECTORY

    if (( rc == 0 )); then
        info "smcTest PASSED ✓"
    else
        warn "smcTest exited with code ${rc}"
        warn "If you see CUDA_ERROR_SYSTEM_DRIVER_MISMATCH (803):"
        warn "  → Ask the driver team which KMD version to install."
    fi
}

# ---------------------------------------------------------------------------
# 13. Record validated baseline
# ---------------------------------------------------------------------------
record_baseline() {
    section "13. Recording validated environment"

    local record_file="${DEV_BASE}/baseline_$(date +%Y%m%d_%H%M%S).txt"

    {
        echo "=== Validated Baseline — $(date) ==="
        echo ""
        echo "--- Perforce ---"
        p4 changes -m1 "${SW}/dev/gpu_drv/bugfix_main/..." 2>&1 || echo "(unavailable)"
        echo ""
        echo "--- GPU & Driver ---"
        nvidia-smi 2>&1 || echo "(unavailable)"
        echo ""
        echo "--- unix-build ---"
        unix-build --version 2>&1 || echo "(unavailable)"
        echo ""
        echo "--- nvcc (locally built) ---"
        "${CUDA_BIN}/nvcc" --version 2>&1 || echo "(unavailable)"
        echo ""
        echo "--- Build type: debug ---"
        echo "--- Debug driver: ${DEBUG_DRIVER} ---"
        echo ""
        echo "--- libcuda resolution ---"
        LD_LIBRARY_PATH="${DEBUG_DRIVER}:${CUDA_BIN}" \
            ldd "${CUDA_BIN}/smcTest" 2>/dev/null | grep libcuda || echo "(unavailable)"
        echo ""
        echo "--- Key env vars ---"
        echo "SW=${SW}"
        echo "GPGPU_COMPILER_EXPORT=${GPGPU_COMPILER_EXPORT:-not set}"
        echo "DRIVER_ROOT=${DRIVER_ROOT:-not set (auto-detected)}"
        echo ""
        echo "--- Hostname & OS ---"
        hostname
        uname -a
        echo ""
    } | tee "${record_file}"

    info "Baseline saved to: ${record_file}"
}

# ---------------------------------------------------------------------------
# ENV — Print and verify current environment
# ---------------------------------------------------------------------------
print_env() {
    section "Environment Summary"

    echo "  USERNAME:               ${USERNAME}"
    echo "  CLIENTNAME:             ${CLIENTNAME}"
    echo "  DEV_BASE:               ${DEV_BASE}"
    echo "  SW:                     ${SW}"
    echo "  COMPILER_BASE:          ${COMPILER_BASE}"
    echo "  GPGPU_COMPILER_EXPORT:  ${GPGPU_COMPILER_EXPORT:-<not set>}"
    echo "  DEBUG_DRIVER:           ${DEBUG_DRIVER}"
    echo "  RELEASE_DRIVER:         ${RELEASE_DRIVER}"
    echo "  CUDA_BIN:               ${CUDA_BIN}"
    echo "  P4PORT:                 ${P4PORT_VAL}"
    echo "  BUILD_JOBS:             ${BUILD_JOBS}"
    echo "  SHELL_RC:               ${SHELL_RC}"
    echo ""

    pre_build_checks 2>/dev/null || true
}

# ---------------------------------------------------------------------------
# MAIN
# ---------------------------------------------------------------------------
main() {
    local target="${1:-all}"

    info "bugfix_main setup — $(hostname) — $(date)"
    info "Target: ${target}"

    case "${target}" in
        p4)
            check_prerequisites
            configure_p4
            create_p4_client
            sync_workspace
            configure_shell_env
            ;;
        compiler)
            download_compiler
            ;;
        build)
            pre_build_checks
            build_debug_driver
            build_release_driver
            build_cuda_runtime
            build_tests
            ;;
        build-driver)
            pre_build_checks
            build_debug_driver
            build_release_driver
            ;;
        build-runtime)
            pre_build_checks
            build_cuda_runtime
            ;;
        build-tests)
            pre_build_checks
            build_tests
            ;;
        test)
            run_smctest
            ;;
        env)
            print_env
            ;;
        record)
            record_baseline
            ;;
        all)
            check_prerequisites
            configure_p4
            create_p4_client
            sync_workspace
            configure_shell_env
            download_compiler
            pre_build_checks
            build_debug_driver
            build_release_driver
            build_cuda_runtime
            build_tests
            echo ""
            section "Setup complete!"
            info "Next steps:"
            info "  1) source ${SHELL_RC}"
            info "  2) Run sanity test:  ./bugfix_main_setup.sh test"
            info "  3) Record baseline:  ./bugfix_main_setup.sh record"
            ;;
        *)
            echo "Usage: $0 [all|p4|compiler|build|build-driver|build-runtime|build-tests|test|env|record]"
            exit 1
            ;;
    esac
}

main "$@"
