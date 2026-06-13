#!/usr/bin/env bash
# Atomic Arch detection script - Sonatype-2026-003775.
# IOC sources:
#   ioctl.fail/preliminary-analysis-of-aur-malware (Whanos, 2026-06-11)
#   github.com/lenucksi/aur-malware-check iocs.txt (community, 2026-06-12)
#   Sonatype blog: atomic-arch-npm-campaign-adds-malicious-dependency
#   IFIN Discourse thread (js-digest wave update, 2026-06-12)
#
# Run as root for complete BPF, /var/lib, and all-user unit checks.
#
# WARNING: If the eBPF rootkit ran as root and is currently loaded,
#          getdents64-based tools (ps, ss, ls on /proc, find on /proc)
#          return filtered results. BPF map checks and static file
#          checks remain reliable because they use different kernel
#          paths (BPF_MAP_GET_NEXT_ID syscall, direct inode access).

set -uo pipefail

# ------------------------------------------------------------------ #
# IOC constants.
# ------------------------------------------------------------------ #

# Wave 1: ELF payload 'deps' delivered via atomic-lockfile@1.4.2
#         npm preinstall hook. Source: ioctl.fail analysis.
readonly HASH_DEPS_SHA256=\
"6144d433f8a0316869877b5f834c801251bbb936e5f1577c5680878c7443c98b"
readonly HASH_DEPS_MD5="42b59fdbe1b72895b2951412222ebf40"
readonly HASH_DEPS_SIZE=3040376

# Wave 2: ELF payload delivered via js-digest bun install hook.
#         Source: IFIN Discourse / socket.dev analysis (2026-06-12).
readonly HASH_JSDIGEST_SHA256=\
"7883bda1ff15425f2dbe622c45a3ae105ddfa6175009bbf0b0cad9bf5c79b316"

# Cryptominer staging binary fetched from C2 onion /bin/linux path.
#         Source: ioctl.fail staging section, VirusTotal link.
readonly HASH_MINER_SHA256=\
"47893d9badc38c54b71321263ce8178c1abb10396e0aadf9793e61ec8829e204"

# Malicious npm/bun package names injected into AUR PKGBUILDs.
readonly -a MALICIOUS_PKGS=("atomic-lockfile" "js-digest" "lockfile-js")

# PKGBUILD injection strings from both attack waves.
readonly -a INJECT_PATTERNS=(
    "npm install atomic-lockfile"
    "bun install js-digest"
    "npm install lockfile-js"
)

# eBPF rootkit pinned BPF map paths (require CAP_BPF to create).
#   hidden_pids   - PID numbers hidden from /proc listings.
#   hidden_names  - process names hidden from directory reads.
#   hidden_inodes - socket inodes hidden from ss/netstat/netlink.
readonly -a BPF_MAPS=(
    "/sys/fs/bpf/hidden_pids"
    "/sys/fs/bpf/hidden_names"
    "/sys/fs/bpf/hidden_inodes"
)

# C2 onion address XOR-decoded at runtime from within the ELF.
#   Communicates via POST /api/agent on TCP/80 and TCP/8080.
readonly C2_ONION=\
"olrh4mibs62l6kkuvvjyc5lrercqg5tz543r4lsw3o6mh5qb7g7sneid.onion"

# Cryptominer staging path referenced inside the malware binary.
readonly MINER_STAGE_PATH="/usr/bin/monero-wallet-gui"

# systemd service persistence signature written by the malware.
#   Both fields appear together in the generated unit file.
readonly SVC_RESTART="Restart=always"
readonly SVC_RESTART_SEC="RestartSec=30"

# AUR helper build and clone cache directories to inspect.
readonly -a AUR_CACHES=(
    "${HOME}/.cache/yay"
    "${HOME}/.cache/paru"
    "${HOME}/.cache/trizen"
    "${HOME}/.cache/pikaur"
    "${HOME}/.cache/aura"
)

# ------------------------------------------------------------------ #
# Output helpers.
# ------------------------------------------------------------------ #

RED='\033[0;31m'
YEL='\033[0;33m'
GRN='\033[0;32m'
DIM='\033[2m'
BOLD='\033[1m'
RST='\033[0m'

FINDINGS=0

_found() {
    printf "  ${RED}[found]${RST} %s\n" "$1"
    FINDINGS=$(( FINDINGS + 1 ))
}

_warn() {
    printf "  ${YEL}[warn]${RST} %s\n" "$1"
}

_ok() {
    printf "  ${GRN}[ok]${RST} %s\n" "$1"
}

_info() {
    printf "  ${DIM}        %s${RST}\n" "$1"
}

_section() {
    printf "\n${BOLD}==> %s${RST}\n" "$1"
}

# ------------------------------------------------------------------ #
# Decompression helper used by check_pacman_log.
# ------------------------------------------------------------------ #
_read_log() {
    case "$1" in
        *.gz)  zcat  "$1" ;;
        *.xz)  xzcat "$1" ;;
        *.zst) zstdcat "$1" ;;
        *.bz2) bzcat "$1" ;;
        *)     cat   "$1" ;;
    esac
}

# ------------------------------------------------------------------ #
# Check 1: eBPF rootkit pinned BPF maps.
#
# Pinned maps survive process restarts. The three map names below are
# hardcoded in the malware source (scales.bpf.c reference in Sonatype
# analysis). Checking their presence is reliable because:
#   - File existence does not use getdents64.
#   - The rootkit hides processes and sockets, not its own map paths.
# ------------------------------------------------------------------ #
check_bpf_maps() {
    _section "bpf rootkit: pinned map artifacts"
    local any=0
    for mappath in "${BPF_MAPS[@]}"; do
        if [[ -e "$mappath" ]]; then
            _found "rootkit bpf map present: $mappath"
            any=1
        fi
    done
    [[ "$any" -eq 0 ]] && \
        _ok "no rootkit bpf maps found under /sys/fs/bpf/"
}

# ------------------------------------------------------------------ #
# Check 2: loaded BPF programs via bpftool.
#
# bpftool uses BPF_PROG_GET_NEXT_ID / BPF_MAP_GET_NEXT_ID syscalls,
# which enumerate kernel objects directly without reading /proc or any
# filesystem directory. This bypasses any getdents64 hook the rootkit
# may have installed.
#
# Flag programs attached to getdents syscalls - the primary mechanism
# the rootkit uses to hide PIDs, names, and socket inodes.
# Requires root.
# ------------------------------------------------------------------ #
check_bpf_progs() {
    _section "bpf rootkit: loaded programs via bpftool"

    if [[ "${EUID}" -ne 0 ]]; then
        _warn "requires root; skipping bpftool enumeration"
        return
    fi
    if ! command -v bpftool &>/dev/null; then
        _warn "bpftool not installed (install linux-tools or bpf-tools)"
        return
    fi

    local progs
    if ! progs=$(bpftool prog list 2>/dev/null); then
        _warn "bpftool prog list failed"
        return
    fi

    if [[ -z "$progs" ]]; then
        _ok "no bpf programs currently loaded"
        return
    fi

    # Flag programs whose name contains getdents - the hiding vector.
    if echo "$progs" | grep -qi "getdents"; then
        _found "bpf program attached to getdents syscall detected"
        echo "$progs" | grep -i "getdents" | while IFS= read -r line; do
            _info "$line"
        done
    fi

    # List all programs; analyst reviews for unexpected kprobes.
    local count
    count=$(echo "$progs" | grep -c "^[0-9]" || true)
    _info "$count bpf program(s) loaded - review for unexpected kprobes:"
    echo "$progs" | grep "^[0-9]" | while IFS= read -r line; do
        _info "  $line"
    done
}

# ------------------------------------------------------------------ #
# Check 3: systemd persistence units.
#
# The malware installs a service unit with Restart=always +
# RestartSec=30, with ExecStart pointing to a generated binary path
# under /var/lib/ (root) or the user's home directory (non-root).
# Both system-level and per-user unit directories are scanned.
# ------------------------------------------------------------------ #
check_systemd_units() {
    _section "systemd persistence units"

    local -a scan_dirs=("/etc/systemd/system")
    [[ -d "${HOME}/.config/systemd/user" ]] && \
        scan_dirs+=("${HOME}/.config/systemd/user")

    # When root, extend scan to all local user home directories.
    if [[ "${EUID}" -eq 0 ]]; then
        while IFS= read -r -d '' udir; do
            local uunit="${udir}/.config/systemd/user"
            [[ -d "$uunit" ]] && scan_dirs+=("$uunit")
        done < <(find /home -maxdepth 1 -mindepth 1 \
                 -type d -print0 2>/dev/null)
    fi

    local any=0
    for svcdir in "${scan_dirs[@]}"; do
        [[ -d "$svcdir" ]] || continue
        while IFS= read -r -d '' svcfile; do
            # Both fields must be present together for a match.
            if grep -q "^${SVC_RESTART}$" "$svcfile" 2>/dev/null && \
               grep -q "^${SVC_RESTART_SEC}$" "$svcfile" 2>/dev/null; then
                local execstart
                execstart=$(grep "^ExecStart=" "$svcfile" 2>/dev/null \
                            | head -1)
                # Flag only units whose binary lives in the malware's
                # known install paths (/var/lib/ for root, home for user).
                if echo "$execstart" | \
                   grep -qE "^ExecStart=(/var/lib/|${HOME}/|/home/)"; then
                    _found "persistence unit with malware signature: $svcfile"
                    _info "$execstart"
                    any=1
                fi
            fi
        done < <(find "$svcdir" -maxdepth 1 -name "*.service" \
                 -print0 2>/dev/null)
    done
    [[ "$any" -eq 0 ]] && \
        _ok "no suspicious systemd persistence units found"
}

# ------------------------------------------------------------------ #
# Check 4: AUR build cache injection traces.
#
# Scans AUR helper clone/build cache directories for:
#   - PKGBUILD injection strings from both attack waves.
#   - The npm preinstall hook payload path src/hooks/deps.
#   - Extracted malicious package directories inside node_modules.
# ------------------------------------------------------------------ #
check_build_artifacts() {
    _section "aur build cache injection traces"
    local any=0

    for cachedir in "${AUR_CACHES[@]}"; do
        [[ -d "$cachedir" ]] || continue

        for pattern in "${INJECT_PATTERNS[@]}"; do
            local hits
            hits=$(grep -rl "${pattern}" "${cachedir}" 2>/dev/null || true)
            if [[ -n "$hits" ]]; then
                _found "pkgbuild injection: '${pattern}'"
                echo "$hits" | while IFS= read -r f; do _info "$f"; done
                any=1
            fi
        done

        # The npm preinstall lifecycle hook executes this exact path.
        while IFS= read -r -d '' payloadfile; do
            _found "preinstall payload path found: $payloadfile"
            any=1
        done < <(find "${cachedir}" -path "*/src/hooks/deps" \
                 -print0 2>/dev/null)

        for pkg in "${MALICIOUS_PKGS[@]}"; do
            while IFS= read -r -d '' moddir; do
                _found "malicious pkg '${pkg}' in node_modules: $moddir"
                any=1
            done < <(find "${cachedir}" -type d -name "${pkg}" \
                     -path "*/node_modules/*" -print0 2>/dev/null)
        done
    done

    [[ "$any" -eq 0 ]] && _ok "no build cache injection traces found"
}

# ------------------------------------------------------------------ #
# Check 5: npm and bun package manager caches.
#
# The npm cache at ~/.npm is content-addressed but package.json files
# inside it carry the original package name. The bun cache at
# ~/.bun/install/cache has the same structure.
# ------------------------------------------------------------------ #
check_package_caches() {
    _section "npm / bun package manager caches"
    local any=0

    local npm_cache="${HOME}/.npm"
    if [[ -d "$npm_cache" ]]; then
        for pkg in "${MALICIOUS_PKGS[@]}"; do
            local hits
            hits=$(grep -rl "\"name\": \"${pkg}\"" \
                   "${npm_cache}" 2>/dev/null || true)
            if [[ -n "$hits" ]]; then
                _found "malicious package '${pkg}' in npm cache"
                echo "$hits" | head -3 | while IFS= read -r f; do
                    _info "$f"
                done
                any=1
            fi
        done
    fi

    local bun_cache="${HOME}/.bun/install/cache"
    if [[ -d "$bun_cache" ]]; then
        for pkg in "${MALICIOUS_PKGS[@]}"; do
            while IFS= read -r -d '' pkgjson; do
                if grep -q "\"name\": \"${pkg}\"" \
                   "$pkgjson" 2>/dev/null; then
                    _found "malicious package '${pkg}' in bun cache"
                    _info "$pkgjson"
                    any=1
                fi
            done < <(find "${bun_cache}" -name "package.json" \
                     -print0 2>/dev/null)
        done
    fi

    [[ "$any" -eq 0 ]] && \
        _ok "no malicious packages found in npm / bun caches"
}

# ------------------------------------------------------------------ #
# Check 6: payload SHA256 hash match.
#
# Searches targeted directories for files whose SHA256 matches any
# known payload. File size filter (2-6 MB) reduces candidates before
# hashing. The deps binary is exactly 3,040,376 bytes.
# ------------------------------------------------------------------ #
check_payload_hashes() {
    _section "payload sha256 hash match"

    if ! command -v sha256sum &>/dev/null; then
        _warn "sha256sum not found; skipping hash check"
        return
    fi

    local -a search_dirs=("/tmp" "/var/lib" "${HOME}" "${HOME}/.local")
    for cachedir in "${AUR_CACHES[@]}"; do
        [[ -d "$cachedir" ]] && search_dirs+=("$cachedir")
    done

    local any=0
    while IFS= read -r -d '' candidate; do
        local h
        h=$(sha256sum "$candidate" 2>/dev/null | awk '{print $1}')
        case "$h" in
            "${HASH_DEPS_SHA256}")
                _found "wave1 payload (deps/atomic-lockfile): $candidate"
                any=1 ;;
            "${HASH_JSDIGEST_SHA256}")
                _found "wave2 payload (js-digest elf): $candidate"
                any=1 ;;
            "${HASH_MINER_SHA256}")
                _found "cryptominer staging payload: $candidate"
                any=1 ;;
        esac
    done < <(find "${search_dirs[@]}" -type f \
             -size +2M -size -6M -print0 2>/dev/null)

    [[ "$any" -eq 0 ]] && _ok "no files matched known payload sha256 hashes"
}

# ------------------------------------------------------------------ #
# Check 7: /var/lib unowned ELF executables created post-attack-window.
#
# When run as root, the malware copies itself under a generated name
# inside /var/lib/. Candidate files must satisfy all three conditions:
#   1. Executable permission bit set.
#   2. ELF magic bytes (7f 45 4c 46) at offset 0 - eliminates SQLite
#      databases, VM disk images, lock files, and other data files that
#      happen to have the execute bit set.
#   3. Modified on or after 2026-06-09 (attack window start) - reduces
#      the set to recently created files only.
# Requires root for reliable access to all subdirectories.
# ------------------------------------------------------------------ #
check_varlib_executables() {
    _section "/var/lib unowned elf executables (root install path)"

    if [[ "${EUID}" -ne 0 ]]; then
        _warn "requires root; skipping /var/lib unowned executable scan"
        return
    fi
    if ! command -v pacman &>/dev/null; then
        _warn "pacman not available; skipping"
        return
    fi

    # _is_elf returns 0 if the file starts with the ELF magic bytes.
    _is_elf() {
        local magic
        magic=$(od -A n -t x1 -N 4 "$1" 2>/dev/null | tr -d ' \n')
        [[ "$magic" == "7f454c46" ]]
    }

    # Create a reference file stamped at 2026-06-08 23:59:59 so that
    # find -newer selects only files modified on or after 2026-06-09.
    local reffile
    reffile=$(mktemp)
    touch -t 202606082359 "$reffile" 2>/dev/null || {
        _warn "could not create reference timestamp file; skipping"
        rm -f "$reffile"
        return
    }

    local any=0
    while IFS= read -r -d '' f; do
        # Skip non-ELF files (db files, images, lock files, etc.).
        _is_elf "$f" || continue
        if ! pacman -Qo "$f" &>/dev/null 2>&1; then
            _found "unowned elf executable in /var/lib (post-window): $f"
            any=1
        fi
    done < <(find /var/lib -maxdepth 4 -type f -executable \
             -newer "$reffile" -print0 2>/dev/null)

    rm -f "$reffile"
    [[ "$any" -eq 0 ]] && \
        _ok "no unowned elf executables found in /var/lib post-attack-window"
}

# ------------------------------------------------------------------ #
# Check 8: cryptominer staging artifact.
#
# The malware can download a second binary from the C2 onion at
# /bin/linux and stage it at the monero-wallet-gui path. If the file
# exists but is not owned by any package, it was likely placed there
# by the malware staging routine.
# ------------------------------------------------------------------ #
check_miner_staging() {
    _section "cryptominer staging artifact"

    if [[ -f "${MINER_STAGE_PATH}" ]]; then
        _info "file present: ${MINER_STAGE_PATH}"
        if command -v pacman &>/dev/null; then
            if ! pacman -Qo "${MINER_STAGE_PATH}" &>/dev/null 2>&1; then
                _found "monero-wallet-gui exists but is unowned by pacman"
                _info "likely placed by the malware cryptominer staging path"
            else
                _ok "monero-wallet-gui is owned by a known package"
            fi
        else
            _warn "cannot verify ownership without pacman"
        fi
    else
        _ok "monero-wallet-gui staging path does not exist"
    fi
}

# ------------------------------------------------------------------ #
# Check 9: pacman installation log - attack window scan.
#
# Scans /var/log/pacman.log and compressed rotations for AUR (foreign)
# packages installed or upgraded during the confirmed attack window:
# June 9-12, 2026. Official repo packages are listed as informational
# only; AUR packages are flagged as findings.
# ------------------------------------------------------------------ #
check_pacman_log() {
    _section "pacman log - attack window (2026-06-09 to 2026-06-12)"

    local logfile="/var/log/pacman.log"
    if [[ ! -f "$logfile" ]]; then
        _warn "/var/log/pacman.log not found"
        return
    fi

    local aur_list=""
    if command -v pacman &>/dev/null; then
        aur_list=$(pacman -Qqm 2>/dev/null || true)
    fi

    local -a logs=("$logfile")
    for comp in /var/log/pacman.log.*.gz \
                /var/log/pacman.log.*.xz \
                /var/log/pacman.log.*.zst \
                /var/log/pacman.log.*.bz2; do
        [[ -f "$comp" ]] && logs+=("$comp")
    done

    local any=0
    for lf in "${logs[@]}"; do
        while IFS= read -r line; do
            # Match lines from the attack window only.
            case "$line" in
                \[2026-06-09*|\[2026-06-10*|\[2026-06-11*|\[2026-06-12*)
                    ;;
                *) continue ;;
            esac
            # Match install and upgrade transactions only.
            case "$line" in
                *"installed "*|*"upgraded "*) ;;
                *) continue ;;
            esac
            # Extract package name from field 5 of the log format:
            # [YYYY-MM-DD HH:MM:SS] [ALPM] installed pkg (version)
            local pkg
            pkg=$(echo "$line" | awk '{print $5}')
            [[ -z "$pkg" ]] && continue
            if [[ -n "$aur_list" ]] && \
               echo "$aur_list" | grep -qx "${pkg}"; then
                _found "aur package installed in attack window: ${pkg}"
                _info "$line"
                any=1
            fi
        done < <(_read_log "$lf" 2>/dev/null)
    done

    [[ "$any" -eq 0 ]] && \
        _ok "no aur packages found installed in the attack window"
}

# ------------------------------------------------------------------ #
# Check 10: process integrity (proc vs ps delta).
#
# Compares /proc PID directory count against ps output. A large delta
# suggests processes are being hidden. Note that if the rootkit hooks
# getdents64 on /proc itself, both counts will be filtered, making
# this check unreliable on an active root-level infection. The BPF
# map and bpftool checks above are more authoritative in that case.
# ------------------------------------------------------------------ #
check_proc_integrity() {
    _section "process integrity (proc vs ps delta)"

    local proc_count ps_count delta

    proc_count=$(find /proc -maxdepth 1 -name '[0-9]*' \
                 -type d 2>/dev/null | wc -l)
    ps_count=$(ps -e --no-headers 2>/dev/null | wc -l)

    delta=$(( proc_count - ps_count ))
    [[ "$delta" -lt 0 ]] && delta=$(( -delta ))

    _info "/proc pid dirs : $proc_count"
    _info "ps -e count    : $ps_count"
    _info "delta          : $delta"

    if [[ "$delta" -gt 10 ]]; then
        _found "high proc/ps discrepancy ($delta) - possible process hiding"
        _info "note: if the rootkit hooks getdents64 on /proc, both counts"
        _info "      are filtered and this delta may understate the impact"
    else
        _ok "proc/ps delta within expected range ($delta)"
    fi
}

# ------------------------------------------------------------------ #
# Check 11: loopback SOCKS transport.
#
# The malware binds a local SOCKS proxy on 127.0.0.1 to route C2
# traffic to the onion service. When the rootkit is active, socket
# inodes used by this proxy are inserted into hidden_inodes and
# filtered from ss/netstat/netlink output. This check is informational
# when the rootkit is active.
#
# To enumerate hidden socket inodes directly:
#   bpftool map dump name hidden_inodes
# ------------------------------------------------------------------ #
check_loopback_socks() {
    _section "loopback socks transport"

    _warn "if the rootkit is active, hidden_inodes filters ss output"
    _info "authoritative check: bpftool map dump name hidden_inodes"

    if ! command -v ss &>/dev/null; then
        _warn "ss not available"
        return
    fi

    local listeners
    listeners=$(ss -tlnp 2>/dev/null | grep "127\.0\.0\.1" || true)
    if [[ -n "$listeners" ]]; then
        _info "loopback tcp listeners (review for unexpected entries):"
        echo "$listeners" | while IFS= read -r line; do
            _info "  $line"
        done
    else
        _ok "no loopback tcp listeners visible via ss"
    fi
}

# ------------------------------------------------------------------ #
# Summary and remediation guidance.
# ------------------------------------------------------------------ #
print_summary() {
    echo ""
    echo -e "${BOLD}--- summary ---${RST}"
    echo ""

    if [[ "${FINDINGS}" -eq 0 ]]; then
        echo -e "  ${GRN}no indicators found${RST}"
        echo ""
        echo "  a clean result does not guarantee the system is uninfected."
        echo "  if the rootkit loaded as root, it may hide its own artifacts"
        echo "  from the file and process tools this script uses."
        echo "  the bpf map and bpftool checks are the most reliable indicators"
        echo "  when an active root-level infection is suspected."
    else
        echo -e "  ${RED}${FINDINGS} indicator(s) found${RST}"
        echo ""
        echo "  credential rotation required (assume all of the following"
        echo "  were exfiltrated): browser sessions, ssh keys, github/npm"
        echo "  tokens, slack/discord/teams sessions, vault tokens,"
        echo "  docker/podman registry credentials, cloud provider keys."
        echo ""
        echo "  if the payload ran as root:"
        echo "    reinstall from trusted media - in-place cleanup is not"
        echo "    trustworthy once a rootkit has had root execution."
        echo ""
        echo "  if the payload ran as a non-root user (no rootkit):"
        echo "    remove the ~/.config/systemd/user/<generated>.service unit,"
        echo "    remove the persisted binary, then rotate all credentials."
    fi

    echo ""
    echo "  c2 onion   : ${C2_ONION}"
    echo "  references :"
    echo "    https://ioctl.fail/preliminary-analysis-of-aur-malware/"
    echo "    https://github.com/lenucksi/aur-malware-check"
    # shellcheck disable=SC2016
    echo "    https://www.sonatype.com/blog/atomic-arch-npm-campaign"
    echo "    https://lists.archlinux.org/archives/list/aur-general@lists.archlinux.org/"
    echo ""
}

# ------------------------------------------------------------------ #
# Entry point.
# ------------------------------------------------------------------ #
main() {
    echo ""
    echo -e "${BOLD}atomic arch detection - sonatype-2026-003775${RST}"
    echo "  attack window  : 2026-06-09 to 2026-06-12"
    echo "  malicious pkgs : atomic-lockfile (npm) / js-digest (bun)"
    echo "  payload hashes : wave1=${HASH_DEPS_SHA256:0:16}..."
    echo "                   wave2=${HASH_JSDIGEST_SHA256:0:16}..."
    echo "  running as     : $(id -un) (uid=${EUID})"
    echo ""

    check_bpf_maps
    check_bpf_progs
    check_systemd_units
    check_build_artifacts
    check_package_caches
    check_payload_hashes
    check_varlib_executables
    check_miner_staging
    check_pacman_log
    check_proc_integrity
    check_loopback_socks
    print_summary
}

main
