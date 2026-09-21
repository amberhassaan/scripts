#!/usr/bin/env python3
import argparse
import getpass
import os
import platform
import subprocess
import sys

DEFAULT_P4PORT = "p4proxy-sc:2006"

paths = [
    "//sw/dev/gpu_drv/bugfix_main/sdk/...",
    "//sw/dev/gpu_drv/bugfix_main/docs/agent/...",
    "//sw/dev/gpu_drv/bugfix_main/tools/agent/...",
    "//sw/dev/gpu_drv/bugfix_main/apps/nvml/...",
    "//sw/dev/gpu_drv/bugfix_main/drivers/gpgpu/...",
    "-//sw/dev/gpu_drv/bugfix_main/drivers/gpgpu/compiler/gpgpu/export/...",
    "//sw/dev/gpu_drv/bugfix_main/drivers/gpgpu/compiler/gpgpu/export/bin/x86_64_Linux_develop/...",
    "-//sw/dev/gpu_drv/bugfix_main/drivers/gpgpu/compiler/gpgpu/export/bin/x86_64_Linux_develop/libnvptxcompiler_static.a",
    "-//sw/dev/gpu_drv/bugfix_main/drivers/gpgpu/compiler/gpgpu/export/bin/x86_64_Linux_develop/libgpgpucomp.a",
    "//sw/dev/gpu_drv/bugfix_main/drivers/common/...",
    "-//sw/dev/gpu_drv/bugfix_main/drivers/common/HW/...",
    "-//sw/dev/gpu_drv/bugfix_main/drivers/common/video/...",
    "-//sw/dev/gpu_drv/bugfix_main/drivers/common/inc/hwref/...",
    "//sw/dev/gpu_drv/bugfix_main/drivers/common/inc/hwref/ada/ad102/dev_graphics_nobundle.h",
    "//sw/dev/gpu_drv/bugfix_main/drivers/common/inc/hwref/ada/ad102/dev_ltc.h",
    "//sw/dev/gpu_drv/bugfix_main/drivers/common/inc/hwref/ada/ad102/dev_mmu.h",
    "//sw/dev/gpu_drv/bugfix_main/drivers/common/inc/hwref/ada/ad102/hwproject.h",
    "//sw/dev/gpu_drv/bugfix_main/drivers/common/inc/hwref/ampere/ga100/dev_graphics_nobundle.h",
    "//sw/dev/gpu_drv/bugfix_main/drivers/common/inc/hwref/ampere/ga100/dev_ltc.h",
    "//sw/dev/gpu_drv/bugfix_main/drivers/common/inc/hwref/ampere/ga100/dev_mmu.h",
    "//sw/dev/gpu_drv/bugfix_main/drivers/common/inc/hwref/ampere/ga100/hwproject.h",
    "//sw/dev/gpu_drv/bugfix_main/drivers/common/inc/hwref/blackwell/gb100/dev_graphics_nobundle.h",
    "//sw/dev/gpu_drv/bugfix_main/drivers/common/inc/hwref/blackwell/gb100/dev_ltc.h",
    "//sw/dev/gpu_drv/bugfix_main/drivers/common/inc/hwref/blackwell/gb100/dev_mmu.h",
    "//sw/dev/gpu_drv/bugfix_main/drivers/common/inc/hwref/blackwell/gb100/hwproject.h",
    "//sw/dev/gpu_drv/bugfix_main/drivers/common/inc/hwref/blackwell/gb202/dev_graphics_nobundle.h",
    "//sw/dev/gpu_drv/bugfix_main/drivers/common/inc/hwref/blackwell/gb202/dev_ltc.h",
    "//sw/dev/gpu_drv/bugfix_main/drivers/common/inc/hwref/blackwell/gb20c/dev_ltc.h",
    "//sw/dev/gpu_drv/bugfix_main/drivers/common/inc/hwref/blackwell/gb207/dev_mmu.h",
    "//sw/dev/gpu_drv/bugfix_main/drivers/common/inc/hwref/fermi/gf100/dev_top.h",
    "//sw/dev/gpu_drv/bugfix_main/drivers/common/inc/hwref/feynman/fn100/dev_graphics_nobundle.h",
    "//sw/dev/gpu_drv/bugfix_main/drivers/common/inc/hwref/feynman/fn100/dev_ltc.h",
    "//sw/dev/gpu_drv/bugfix_main/drivers/common/inc/hwref/feynman/fn100/dev_mmu.h",
    "//sw/dev/gpu_drv/bugfix_main/drivers/common/inc/hwref/feynman/fn100/hwproject.h",
    "//sw/dev/gpu_drv/bugfix_main/drivers/common/inc/hwref/hopper/gh100/dev_graphics_nobundle.h",
    "//sw/dev/gpu_drv/bugfix_main/drivers/common/inc/hwref/hopper/gh100/dev_ltc.h",
    "//sw/dev/gpu_drv/bugfix_main/drivers/common/inc/hwref/hopper/gh100/dev_mmu.h",
    "//sw/dev/gpu_drv/bugfix_main/drivers/common/inc/hwref/hopper/gh100/hwproject.h",
    "//sw/dev/gpu_drv/bugfix_main/drivers/common/inc/hwref/kepler/gk20a/dev_timer.h",
    "//sw/dev/gpu_drv/bugfix_main/drivers/common/inc/hwref/maxwell/gm204/dev_fuse.h",
    "//sw/dev/gpu_drv/bugfix_main/drivers/common/inc/hwref/rubin/gr100/dev_graphics_nobundle.h",
    "//sw/dev/gpu_drv/bugfix_main/drivers/common/inc/hwref/rubin/gr202/dev_graphics_nobundle.h",
    "//sw/dev/gpu_drv/bugfix_main/drivers/common/inc/hwref/rubin/gr202/dev_ltc.h",
    "//sw/dev/gpu_drv/bugfix_main/drivers/common/inc/hwref/turing/tu102/dev_fuse.h",
    "//sw/dev/gpu_drv/bugfix_main/drivers/common/inc/hwref/turing/tu102/dev_graphics_nobundle.h",
    "//sw/dev/gpu_drv/bugfix_main/drivers/common/inc/hwref/turing/tu102/dev_mmu.h",
    "//sw/dev/gpu_drv/bugfix_main/drivers/common/inc/hwref/turing/tu102/dev_top.h",
    "//sw/dev/gpu_drv/bugfix_main/drivers/common/inc/hwref/turing/tu102/dev_usermode.h",
    "//sw/dev/gpu_drv/bugfix_main/drivers/common/inc/hwref/turing/tu102/hwproject.h",
    "//sw/dev/gpu_drv/bugfix_main/drivers/common/inc/hwref/volta/gv100/dev_graphics_nobundle.h",
    "//sw/dev/gpu_drv/bugfix_main/drivers/compiler/gpgpucomp/...",
    "//sw/dev/gpu_drv/bugfix_main/drivers/compiler/utilities/...",
    "//sw/dev/gpu_drv/bugfix_main/drivers/compiler/build/...",
    "//sw/dev/gpu_drv/bugfix_main/drivers/compiler/cuda/...",
    "//sw/dev/gpu_drv/bugfix_main/drivers/compiler/cuda-host-tile-loader/...",
    "//sw/dev/gpu_drv/bugfix_main/drivers/compiler/cuda_tile/tileir/tile_ir/compiler/include/...",
    "//sw/dev/gpu_drv/bugfix_main/drivers/compiler/nvgpucomp/...",
    "//sw/dev/gpu_drv/bugfix_main/drivers/nvsci/inc/...",
    "//sw/dev/gpu_drv/bugfix_main/drivers/vdpau/...",
    "//sw/dev/gpu_drv/bugfix_main/drivers/khronos/...",
    "-//sw/dev/gpu_drv/bugfix_main/drivers/khronos/wfd/...",
    "-//sw/dev/gpu_drv/bugfix_main/drivers/tegra/...",
    "-//sw/dev/gpu_drv/bugfix_main/drivers/dxcask/...",
    "-//sw/dev/gpu_drv/bugfix_main/drivers/nvcamera/...",
    "-//sw/dev/gpu_drv/bugfix_main/drivers/gpgpu/cuda/legacy32/...",
    "//sw/dev/gpu_drv/bugfix_main/drivers/OpenGL/...",
    "//sw/dev/gpu_drv/bugfix_main/drivers/modeset/...",
    "//sw/dev/gpu_drv/bugfix_main/drivers/mm/...",
    "//sw/dev/gpu_drv/bugfix_main/drivers/unix/...",
    "//sw/dev/gpu_drv/bugfix_main/drivers/resman/interface/...",
    "//sw/dev/gpu_drv/bugfix_main/drivers/resman/arch/nvalloc/...",
    "//sw/dev/gpu_drv/bugfix_main/tests/cuda/...",
    "//sw/devrel/SDK/inc/GL/...",
    "//sw/gpgpu/cuda/...",
    "-//sw/gpgpu/cuda/apps/perf_mercury_testsuite/...",
    "-//sw/gpgpu/cuda/apps/perf_bugs/...",
    "-//sw/gpgpu/cuda/apps/cutil/...",
    "-//sw/gpgpu/cuda/apps/common/VulkanSDK/...",
    "-//sw/gpgpu/cuda/apps/checkrestore_nccl/...",
    "-//sw/gpgpu/cuda/import/phat/...",
    "-//sw/gpgpu/cuda/legacy32/...",
    "//sw/gpgpu/libcudacxx/...",
    "//sw/gpgpu/build/...",
    "//sw/gpgpu/build/scripts/...",
    "-//sw/gpgpu/build/scripts/testing/...",
    "//sw/gpgpu/common/...",
    "//sw/gpgpu/dvs/scripts/...",
    "//sw/gpgpu/cccl/...",
    "//sw/automation/dvs/dvsbuild/...",
    "//sw/pvt/sgurfinkel/linux/...",
    "//sw/pvt/ebendler/...",
    "//sw/pvt/aliciah/scripts/container/...",
    "//sw/pvt/mtijanic/tools/...",
]

# Tools view paths, composed from buckets by build_tools_paths() below.
# TOOLS_COMMON: host/target-independent tools.
TOOLS_COMMON = [
    "//sw/tools/unix/targets/common/xorg-server/include/...",
    "//sw/tools/unix/targets/common/bison/...",
    "//sw/tools/unix/targets/common/libdrm/...",
    "//sw/tools/linux/python/330/...",
    "//sw/tools/boost/boost-1.55.0/boost/...",
    "//sw/tools/boost/boost-1.58.0/boost/...",
    "//sw/tools/boost/boost-1.66.0/boost/...",
    "//sw/tools/sdk/CUDA/gpgpu/36077116/...",
    "-//sw/tools/sdk/CUDA/gpgpu/36077116/compiler/Windows_amd64/...",
    "//sw/tools/sdk/CUDA/gpgpu/34382332/...",
    "-//sw/tools/sdk/CUDA/gpgpu/34382332/compiler/Windows_amd64/...",
    "//sw/tools/sdk/gtest/1.8.1/...",
    "//sw/tools/scripts/SignCert/Common/dvs-dev-cert/...",
    "//sw/tools/linux/unix-build/...",
    "//sw/tools/bin2obj/...",
]

# TOOLS_WSL: WSL (wddmv2) paths, excluded with --no-wsl.
TOOLS_WSL = [
    "//sw/tools/ddk/wddmv2/dev/wsl/...",
    "//sw/tools/ddk/wddmv2/official/28000/...",
]

# TOOLS_HOST: host-only tools. Note: due to a build-system quirk,
# hosts/Linux-x86 and hosts/Linux-x86_64 are both the amd64 host.
TOOLS_HOST = {
    "amd64": [
        "//sw/tools/unix/hosts/Linux-x86/...",
        "-//sw/tools/unix/hosts/Linux-x86/targets/...",
        "//sw/tools/unix/hosts/Linux-x86_64/pahole-1.25/bin/...",
        "//sw/tools/unix/hosts/Linux-x86_64/libabigail-2.4/bin/...",
    ],
    # Reserved for future use; no aarch64 host toolchain support yet.
    "aarch64": [],
}

# TOOLS_TARGET: host-independent target libraries (glibc, headers, openssl).
TOOLS_TARGET = {
    "amd64": [
        "//sw/tools/unix/targets/Linux-x86_64/glibc-2.11.3/...",
        "//sw/tools/unix/targets/Linux-x86_64/linux-libc-headers-2.6.32/...",
        "//sw/tools/unix/targets/Linux-x86_64/openssl-1.0/...",
        "//sw/tools/unix/targets/Linux-x86_64/openssl-3.0.7_glibc-2.11/...",
        "//sw/tools/unix/targets/Linux-x86_64/glibc-2.27/...",
        "//sw/tools/unix/targets/Linux-x86_64/linux-libc-headers-4.15/...",
        "//sw/tools/unix/targets/Linux-x86_64/openssl-1.0/...",
        "//sw/tools/unix/targets/Linux-x86_64/openssl-3.5.4_glibc-2.11/...",
        "//sw/tools/unix/targets/Linux-x86_64/openssl-3.0.7_glibc-2.11/...",
        "//sw/tools/unix/targets/Linux-x86/glibc-2.27/...",
        "//sw/tools/unix/targets/Linux-x86/linux-libc-headers-4.15/...",
    ],
    "aarch64": [
        "//sw/tools/unix/targets/Linux-aarch64/glibc-2.17/...",
        "//sw/tools/unix/targets/Linux-aarch64/glibc-2.27/...",
        "//sw/tools/unix/targets/Linux-aarch64/linux-libc-headers-3.7.10/...",
        "//sw/tools/unix/targets/Linux-aarch64/linux-libc-headers-4.15/...",
        "//sw/tools/unix/targets/Linux-aarch64/openssl-1.0/...",
        "//sw/tools/unix/targets/Linux-aarch64/openssl-3.0.7/...",
        "//sw/tools/unix/targets/Linux-aarch64/openssl-3.5.4/...",
    ],
    "riscv64": [
        "//sw/tools/unix/targets/Linux-riscv64/glibc-2.36/...",
        "//sw/tools/unix/targets/Linux-riscv64/linux-headers-5.17/...",
    ],
}

# TOOLS_HOST_TARGET: cross toolchains living in <host>/targets/<target>.
# targets/Linux-x86 (32-bit) and targets/Linux-x86_64 are both amd64 targets.
TOOLS_HOST_TARGET = {
    ("amd64", "amd64"): [
        "//sw/tools/unix/hosts/Linux-x86/targets/Linux-x86/configs/...",
        "//sw/tools/unix/hosts/Linux-x86/targets/Linux-x86/gcc-10.3.0/...",
        "//sw/tools/unix/hosts/Linux-x86/targets/Linux-x86/binutils-2.36.1/...",
        "//sw/tools/unix/hosts/Linux-x86/targets/Linux-x86_64/configs/...",
        "//sw/tools/unix/hosts/Linux-x86/targets/Linux-x86_64/gcc-10.3.0/...",
        "//sw/tools/unix/hosts/Linux-x86/targets/Linux-x86_64/binutils-2.36.1/...",
        "//sw/tools/unix/hosts/Linux-x86/targets/Linux-x86/configs/...",
        "//sw/tools/unix/hosts/Linux-x86/targets/Linux-x86/gcc-15.2.0as2/...",
        "//sw/tools/unix/hosts/Linux-x86/targets/Linux-x86/binutils-2.45.1/...",
        "//sw/tools/unix/hosts/Linux-x86/targets/Linux-x86_64/configs/...",
        "//sw/tools/unix/hosts/Linux-x86/targets/Linux-x86_64/gcc-15.2.0as2/...",
        "//sw/tools/unix/hosts/Linux-x86/targets/Linux-x86_64/binutils-2.45.1/...",
        "//sw/tools/linux/cuda-agnostic-toolchain/gcc8.5-glibc2.28/...",
    ],
    ("amd64", "aarch64"): [
        "//sw/tools/unix/hosts/Linux-x86/targets/Linux-aarch64/configs/...",
        "//sw/tools/unix/hosts/Linux-x86/targets/Linux-aarch64/gcc-10.3.0/...",
        "//sw/tools/unix/hosts/Linux-x86/targets/Linux-aarch64/binutils-2.36.1/...",
        "//sw/tools/unix/hosts/Linux-x86/targets/Linux-aarch64/gcc-15.2.0/...",
        "//sw/tools/unix/hosts/Linux-x86/targets/Linux-aarch64/binutils-2.45.1/...",
    ],
    ("amd64", "riscv64"): [
        "//sw/tools/unix/hosts/Linux-x86/targets/Linux-riscv64/configs/...",
        "//sw/tools/unix/hosts/Linux-x86/targets/Linux-riscv64/gcc-11.1.0/...",
        "//sw/tools/unix/hosts/Linux-x86/targets/Linux-riscv64/binutils-2.38/...",
        "//sw/tools/unix/hosts/Linux-x86/targets/Linux-riscv64/gcc-15.2.0/...",
        "//sw/tools/unix/hosts/Linux-x86/targets/Linux-riscv64/binutils-2.45.1/...",
    ],
    # aarch64 host: reserved for future use, no toolchain support yet.
}

# Client spec template
CLIENT_SPEC_TEMPLATE = """# A Perforce Client Specification.
#
#  Client:      The client name.
#  Update:      The date this specification was last modified.
#  Access:      The date this client was last used in any way.
#  Owner:       The Perforce user name of the user who owns the client
#               workspace. The default is the user who created the
#               client workspace.
#  Host:        If set, restricts access to the named host.
#  Description: A short description of the client (optional).
#  Root:        The base directory of the client workspace.
#  AltRoots:    Up to two alternate client workspace roots.
#  Options:     Client options:
#                      [no]allwrite [no]clobber [no]compress
#                      [un]locked [no]modtime [no]rmdir [no]altsync
#  SubmitOptions:
#                      submitunchanged/submitunchanged+reopen
#                      revertunchanged/revertunchanged+reopen
#                      leaveunchanged/leaveunchanged+reopen
#  LineEnd:     Text file line endings on client: local/unix/mac/win/share.
#  Type:        Type of client: writeable/readonly/graph/partitioned/
#                                   partitioned-jnl.
#  ServerID:    If set, restricts access to the named server.
#  View:        Lines to map depot files into the client workspace.
#  ChangeView:  Lines to restrict depot files to specific changelists.
#  Stream:      The stream to which this client's view will be dedicated.
#               (Files in stream paths can be submitted only by dedicated
#               stream clients.) When this optional field is set, the
#               View field will be automatically replaced by a stream
#               view as the client spec is saved.
#  StreamAtChange:  A changelist number that sets a back-in-time view of a
#                   stream ( Stream field is required ).
#                   Changes cannot be submitted when this field is set.
#
# Use 'p4 help client' to see more about client views and options.

Client:	{client_name}

Update:	{update_date}

Access:	{access_date}

Owner:	{owner}

Description:
        Created by {owner}.

Root:	{local_root}

Options:	noallwrite noclobber nocompress unlocked nomodtime normdir noaltsync

SubmitOptions:	submitunchanged

LineEnd:	local

View:
{view_lines}"""


def parse_args() -> argparse.Namespace:
    """Parse command line arguments using argparse."""
    parser = argparse.ArgumentParser(
        prog="cuda-p4client.py",
        description="Generate Perforce client view mappings for CUDA development",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s --client myclient                    # Generate view lines for myclient
  %(prog)s --client myclient --edit             # Update existing client spec
  %(prog)s --client myclient --edit --dry-run   # Preview spec without writing
  %(prog)s --client myclient --create --local-root /path/to/workspace  # Create new client

Exit codes:
  0  success
  1  p4 operation failed (or not logged in when using --batch)
  2  command-line usage error

AI_CONTEXT:
  - Use --dry-run with --edit/--create to preview the resulting spec on
    stdout without writing anything to the server.
  - Use --batch to fail fast instead of prompting for 'p4 login'.
  - Default mode prints one view mapping per line on stdout.
  - --target may be repeated; --host defaults to the current machine.
        """,
    )

    # Client specification group
    client_group = parser.add_argument_group("Client Options")
    client_group.add_argument(
        "--client",
        metavar="NAME",
        help="name of the p4 client (required for --edit/--create)",
    )

    # Operation mode group
    mode_group = parser.add_mutually_exclusive_group()
    mode_group.add_argument(
        "--edit", action="store_true", help="edit existing client spec in-place"
    )
    mode_group.add_argument(
        "--create", action="store_true", help="create new client spec on server"
    )

    # Create-specific options
    create_group = parser.add_argument_group("Create Options")
    create_group.add_argument(
        "--local-root",
        metavar="PATH",
    )

    # Automation options
    agent_group = parser.add_argument_group("Automation Options")
    agent_group.add_argument(
        "--dry-run",
        action="store_true",
        help="print the resulting client spec without writing to the server",
    )
    agent_group.add_argument(
        "--batch",
        action="store_true",
        help="non-interactive: fail instead of prompting for p4 login",
    )

    # View configuration group
    view_group = parser.add_argument_group("View Configuration")

    # SW directory options
    sw_group = view_group.add_mutually_exclusive_group()
    sw_group.add_argument(
        "--include-sw",
        action="store_true",
        default=False,
        help="include 'sw' directory after client name (default)",
    )

    # Tools options
    tools_group = view_group.add_mutually_exclusive_group()
    tools_group.add_argument(
        "--get-tools",
        action="store_true",
        default=True,
        help="include tools directories (default)",
    )
    tools_group.add_argument(
        "--no-get-tools",
        action="store_false",
        dest="get_tools",
        help="exclude tools directories",
    )

    # Toolchain host/target options
    view_group.add_argument(
        "--host",
        choices=["amd64", "aarch64"],
        default=None,
        help="host architecture for toolchain paths (default: detect current host)",
    )
    view_group.add_argument(
        "--target",
        choices=["amd64", "aarch64", "riscv64"],
        action="append",
        default=None,
        help="target architecture for toolchain paths; may be given multiple "
        "times (default: same as host)",
    )
    view_group.add_argument(
        "--no-wsl",
        action="store_true",
        help="exclude //sw/tools/ddk/wddmv2 (WSL) paths",
    )

    args = parser.parse_args()

    # Validate argument combinations
    if (args.edit or args.create) and not args.client:
        parser.error("--client is required when using --edit or --create")

    if args.create and not args.local_root:
        parser.error("--local-root is required when using --create")

    if args.client and args.client.startswith("-"):
        parser.error(f"'{args.client}' does not seem like a valid client name")

    # Resolve toolchain host/targets
    if args.host is None:
        args.host = detect_host()
    if args.host == "aarch64":
        print(
            "Note: no aarch64 host toolchain support in the build system yet; "
            "--host aarch64 is reserved for future use.",
            file=sys.stderr,
        )
    if not args.target:
        args.target = [args.host]

    return args


def second_half(p: str, client: str, include_sw: bool) -> str:
    """Generate the second half of the mapping for a given path."""
    start = "//sw"  # ignore starting '-'
    include = "/sw" if include_sw else ""
    return f"//{client}{include}{p[p.index(start) + len(start) :]}"


def detect_host() -> str:
    """Detect the current host architecture."""
    return {"x86_64": "amd64", "aarch64": "aarch64"}.get(platform.machine(), "amd64")


def build_tools_paths(host: str, targets: list[str], no_wsl: bool) -> list[str]:
    """Compose the tools view paths for the requested host/target pairs."""
    tools = list(TOOLS_COMMON)
    tools += TOOLS_HOST.get(host, [])
    for t in dict.fromkeys(targets):
        tools += TOOLS_TARGET.get(t, [])
        tools += TOOLS_HOST_TARGET.get((host, t), [])
    if not no_wsl:
        tools += TOOLS_WSL
    return tools


def generate_view_lines(client: str, include_sw: bool, tools: list[str]) -> list[str]:
    """Generate the view lines for the client spec."""
    view_lines = []
    for p in paths:
        view_lines.append(f"\t{p} {second_half(p, client, include_sw)}")
    for p in tools:
        view_lines.append(f"\t{p} {second_half(p, client, include_sw)}")
    return view_lines


def perforce_env(client_name: str | None = None) -> dict[str, str]:
    """Return a P4 environment with local defaults applied."""
    env = os.environ.copy()
    if not env.get("P4PORT"):
        env["P4PORT"] = DEFAULT_P4PORT
    env["P4USER"] = env.get("USER") or getpass.getuser()
    if client_name:
        env["P4CLIENT"] = client_name
    return env


def p4_login(batch: bool = False) -> None:
    """Ensure a valid p4 ticket before mutating client specs."""
    if batch:
        # Non-interactive: check ticket status, never prompt.
        result = subprocess.run(
            ["p4", "login", "-s"],
            capture_output=True,
            text=True,
            env=perforce_env(),
        )
        if result.returncode != 0:
            print(
                "Error: not logged in to p4 and --batch was given (not "
                "prompting). Run 'p4 login' first.",
                file=sys.stderr,
            )
            sys.exit(1)
        return
    try:
        subprocess.run(["p4", "login"], env=perforce_env(), check=True)
    except subprocess.CalledProcessError as e:
        print(f"Error running p4 login: {e}", file=sys.stderr)
        sys.exit(1)


def read_client_spec(client_name: str) -> str:
    """Read the existing client spec from the server."""
    try:
        result = subprocess.run(
            ["p4", "client", "-o", client_name],
            capture_output=True,
            text=True,
            env=perforce_env(),
            check=True,
        )
        return result.stdout
    except subprocess.CalledProcessError as e:
        print(f"Error reading client spec: {e}", file=sys.stderr)
        sys.exit(1)


def update_client_spec(spec_content: str, new_view_lines: list[str]) -> str:
    """Update the View section of the client spec."""
    lines = spec_content.split("\n")
    in_view_section = False
    updated_lines = []

    for line in lines:
        if line.strip() == "View:":
            # Start of View section
            in_view_section = True
            updated_lines.append(line)
            # Add the new view lines
            updated_lines.extend(new_view_lines)
        elif in_view_section and line.strip() == "":
            # End of View section (empty line)
            in_view_section = False
            updated_lines.append(line)
        elif not in_view_section:
            # Not in View section, keep the line
            updated_lines.append(line)
        # Skip lines that are in the View section (they'll be replaced)

    return "\n".join(updated_lines)


def write_client_spec(spec_content: str, client_name: str):
    """Write the updated client spec back to the server."""
    try:
        subprocess.run(
            ["p4", "client", "-i"],
            input=spec_content,
            text=True,
            env=perforce_env(client_name),
            check=True,
        )
        print(f"Successfully updated client '{client_name}'", file=sys.stderr)
    except subprocess.CalledProcessError as e:
        print(f"Error writing client spec: {e}", file=sys.stderr)
        sys.exit(1)


def create_client_spec(
    client_name: str, local_root: str, include_sw: bool, tools: list[str]
) -> str:
    """Create a new client spec from template."""
    import datetime

    # Generate view lines
    view_lines = generate_view_lines(client_name, include_sw, tools)

    # Format view lines for template
    formatted_view_lines = "\n".join(view_lines)

    # Get current user and date
    current_user = getpass.getuser()
    current_date = datetime.datetime.now().strftime("%Y/%m/%d %H:%M:%S")

    # Fill in the template
    spec_content = CLIENT_SPEC_TEMPLATE.format(
        client_name=client_name,
        local_root=local_root,
        owner=current_user,
        update_date=current_date,
        access_date=current_date,
        view_lines=formatted_view_lines,
    )

    return spec_content


def main():
    args = parse_args()

    tools = (
        build_tools_paths(args.host, args.target, args.no_wsl) if args.get_tools else []
    )
    if args.edit:
        # Edit mode: read existing spec, update View section, write back
        if not args.dry_run:
            p4_login(args.batch)
        print(f"Reading existing client spec for '{args.client}'...", file=sys.stderr)
        spec_content = read_client_spec(args.client)

        print("Generating new view lines...", file=sys.stderr)
        view_lines = generate_view_lines(args.client, args.include_sw, tools)

        print("Updating client spec...", file=sys.stderr)
        updated_spec = update_client_spec(spec_content, view_lines)

        if args.dry_run:
            print(updated_spec)
            return
        print("Writing updated spec back to server...", file=sys.stderr)
        write_client_spec(updated_spec, args.client)
    elif args.create:
        # Create mode: create new client spec from template
        print(f"Creating new client spec for '{args.client}'...", file=sys.stderr)
        spec_content = create_client_spec(
            args.client, args.local_root, args.include_sw, tools
        )

        if args.dry_run:
            print(spec_content)
            return
        p4_login(args.batch)
        print("Writing new client spec to server...", file=sys.stderr)
        write_client_spec(spec_content, args.client)
    else:
        # Normal mode: just output the view lines
        # Use a default client name if none provided
        client_name = args.client or "default_client"
        view_lines = generate_view_lines(client_name, args.include_sw, tools)
        for line in view_lines:
            print(line)


if __name__ == "__main__":
    main()
