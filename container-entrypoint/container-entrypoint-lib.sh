#!/bin/bash
# ============================================================================
# Container Runtime
# Orchestrates command modules and executes final command
# ============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export CONTAINER_TOOLS=$SCRIPT_DIR/bin

container_entrypoint_build() {
  local script_path="$SCRIPT_DIR/bin/container-entrypoint.sh"

  if [[ ! -x "$script_path" ]]; then
    echo "❌ ERROR: Script not found or not executable: $script_path"
    return 1
  fi

  "$script_path" build "$@"
  return $?
}

container_entrypoint_start() {
  local script_path="$SCRIPT_DIR/bin/container-entrypoint.sh"

  if [[ ! -x "$script_path" ]]; then
    echo "❌ ERROR: Script not found or not executable: $script_path"
    return 1
  fi

  "$script_path" entrypoint "$@"
  return $?
}