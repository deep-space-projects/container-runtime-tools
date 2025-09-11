#!/bin/bash
# ============================================================================
# Container Runtime
# Orchestrates command modules and executes final command
# ============================================================================

set -euo pipefail

local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

container_runtime_build() {
  local script_path="$script_dir/bin/container-runtime.sh"

  if [[ ! -x "$script_path" ]]; then
    echo "❌ ERROR: Script not found or not executable: $script_path"
    return 1
  fi

  "$script_path" build "$@"
  return $?
}

container_runtime_entrypoint() {
  local script_path="$script_dir/bin/container-runtime.sh"

  if [[ ! -x "$script_path" ]]; then
    echo "❌ ERROR: Script not found or not executable: $script_path"
    return 1
  fi

  "$script_path" entrypoint "$@"
  return $?
}