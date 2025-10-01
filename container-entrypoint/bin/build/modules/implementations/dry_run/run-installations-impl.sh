#!/bin/bash
# ============================================================================
# Working Directories Permissions Implementation - Standard Mode
# Real execution of working directories permissions setup
# ============================================================================

set -euo pipefail

run_root_installations() {
  local install_dir="$1"
  tlog info "[DRY RUN] Starting root installations from directory: $install_dir"
  tlog info "[DRY RUN] Running as user: $(whoami) (UID: $(id -u))"
  tlog success "[DRY RUN] Root installations completed successfully"
}


run_user_installations() {
  local install_dir="$1"
  tlog info "[DRY RUN] Starting user installations from directory: $install_dir"
  tlog info "[DRY RUN] Running as user: $(whoami) (UID: $(id -u))"
  tlog success "[DRY RUN] User installations completed successfully"
}
