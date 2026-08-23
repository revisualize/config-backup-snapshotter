#!/usr/bin/env bash
# ------------------------------------------------------------------------------
#  config_backup_snapshotter.sh - dated, manifested config-file snapshots
#
#  Author:    Joseph Tracy  <https://revisualized.com>
#  Copyright: (c) 2026 Joseph Tracy. All rights reserved.
#  Origin:    Original work by the author, written on the author's own time
#             from public documentation and public references. Contains no
#             proprietary or employer material.
#  License:   View-only. See LICENSE. No copying, reuse, redistribution, or
#             derivative works without the author's written permission.
#  Home:      https://revisualized.com
# ------------------------------------------------------------------------------
#
# config_backup_snapshotter.sh
# Dated, manifested snapshots of watched configuration files.
#
# Usage:
#   config_backup_snapshotter.sh snapshot [label]
#   config_backup_snapshotter.sh diff
#   config_backup_snapshotter.sh list
#
# Exit codes: snapshot/list 0 success, 2 error.
#             diff 0 no changes, 1 changes found, 2 error.
#
# Configuration via environment (with sane defaults):
#   CONFIG_SNAPSHOT_ROOT       where snapshots are stored
#   CONFIG_SNAPSHOT_RETENTION  how many snapshots to keep
#   CONFIG_SNAPSHOT_WATCHED    colon-separated list of files to watch
#
set -u

snapshot_root="${CONFIG_SNAPSHOT_ROOT:-/var/lib/config_backup_snapshotter}"
retention_count="${CONFIG_SNAPSHOT_RETENTION:-10}"
if [ -n "${CONFIG_SNAPSHOT_WATCHED:-}" ]; then
    IFS=':' read -r -a watched_configuration_files <<< "${CONFIG_SNAPSHOT_WATCHED}"
else
    watched_configuration_files=(
        "/etc/fstab"
        "/etc/exports"
        "/etc/samba/smb.conf"
        "/etc/chrony.conf"
    )
fi

fail_run() {
    printf 'ERROR: %s\n' "$1" >&2
    exit 2
}

latest_snapshot_directory() {
    find "${snapshot_root}" -maxdepth 1 -type d -name '2*' 2>/dev/null | sort | tail -n 1
}

command_snapshot() {
    local snapshot_label="${1:-}"
    local snapshot_name
    snapshot_name="$(date +%Y%m%dT%H%M%S)"
    [ -n "$snapshot_label" ] && snapshot_name+="_${snapshot_label}"
    local snapshot_directory="${snapshot_root}/${snapshot_name}"
    mkdir -p "$snapshot_directory" || fail_run "cannot create ${snapshot_directory}"

    local manifest_file="${snapshot_directory}/manifest.sha256"
    : > "$manifest_file"
    local watched_file
    for watched_file in "${watched_configuration_files[@]}"; do
        if [ -f "$watched_file" ]; then
            mkdir -p "${snapshot_directory}$(dirname "$watched_file")"
            cp -p "$watched_file" "${snapshot_directory}${watched_file}" \
                || fail_run "copy failed: ${watched_file}"
            sha256sum "$watched_file" >> "$manifest_file"
        else
            printf 'MISSING  %s\n' "$watched_file" >> "$manifest_file"
        fi
    done
    printf 'snapshot created: %s\n' "$snapshot_directory"

    local pruned_directory
    while read -r pruned_directory; do
        [ -n "$pruned_directory" ] && rm -rf "$pruned_directory" \
            && printf 'pruned: %s\n' "$pruned_directory"
    done < <(find "${snapshot_root}" -maxdepth 1 -type d -name '2*' 2>/dev/null | sort | head -n -"$retention_count")
}

command_diff() {
    local baseline_directory
    baseline_directory=$(latest_snapshot_directory)
    [ -n "$baseline_directory" ] || fail_run "no snapshots exist yet; run snapshot first"

    local changes_found=0
    local watched_file
    for watched_file in "${watched_configuration_files[@]}"; do
        local snapshot_copy="${baseline_directory}${watched_file}"
        if [ -f "$snapshot_copy" ] && [ -f "$watched_file" ]; then
            if ! diff -u "$snapshot_copy" "$watched_file"; then
                changes_found=1
            fi
        elif [ -f "$snapshot_copy" ] && [ ! -f "$watched_file" ]; then
            printf 'DELETED since snapshot: %s\n' "$watched_file"
            changes_found=1
        elif [ ! -f "$snapshot_copy" ] && [ -f "$watched_file" ]; then
            printf 'CREATED since snapshot: %s\n' "$watched_file"
            changes_found=1
        fi
    done
    if [ "$changes_found" -eq 0 ]; then
        printf 'no changes since %s\n' "$baseline_directory"
    fi
    return "$changes_found"
}

command_list() {
    local snapshot_directory
    local file_count
    # Read line by line rather than word-splitting a command substitution, so
    # snapshot labels containing spaces stay intact. Mirrors the prune path.
    while IFS= read -r snapshot_directory; do
        [ -n "$snapshot_directory" ] || continue
        file_count=$(grep -c -v '^MISSING' "${snapshot_directory}/manifest.sha256" 2>/dev/null || echo 0)
        printf '%s  (%s files)\n' "$snapshot_directory" "$file_count"
    done < <(find "${snapshot_root}" -maxdepth 1 -type d -name '2*' 2>/dev/null | sort)
}

# Run the dispatcher only when executed directly, so tests can source the
# functions without triggering a run.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-}" in
        snapshot) command_snapshot "${2:-}" ;;
        diff)     command_diff ;;
        list)     command_list ;;
        *)        printf 'usage: %s snapshot [label] | diff | list\n' "$0" >&2; exit 2 ;;
    esac
fi
