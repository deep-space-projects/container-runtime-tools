#!/bin/bash
# ============================================================================
# Container Runtime
# Orchestrates command modules and executes final command
# ============================================================================

set -euo pipefail

container_runtime_build() {
  if [[ -z "${CONTAINER_TOOLS:-}" ]]; then
      echo "❌ ERROR: CONTAINER_TOOLS environment variable is not set"
      echo ""
      echo "This variable should be set in your Dockerfile:"
      echo "  ENV CONTAINER_TOOLS=/opt/container-tools"
      echo ""
      return 1
  fi

  local script_path="${CONTAINER_TOOLS}/container-runtime.sh"

  if [[ ! -x "$script_path" ]]; then
    echo "❌ ERROR: Script not found or not executable: $script_path"
    return 1
  fi

  "$script_path" build "$@"
  return $?
}

container_runtime_entrypoint() {
  if [[ -z "${CONTAINER_TOOLS:-}" ]]; then
      echo "❌ ERROR: CONTAINER_TOOLS environment variable is not set"
      echo ""
      echo "This variable should be set in your Dockerfile:"
      echo "  ENV CONTAINER_TOOLS=/opt/container-tools"
      echo ""
      return 1
  fi

  local script_path="${CONTAINER_TOOLS}/container-runtime.sh"

  if [[ ! -x "$script_path" ]]; then
    echo "❌ ERROR: Script not found or not executable: $script_path"
    return 1
  fi

  "$script_path" entrypoint "$@"
  return $?
}