#!/bin/bash
# ============================================================================
# Permissions Setup Module
# Sets up file permissions for logging, temp directories, and container tools
# ============================================================================

set -euo pipefail

# Подключаем базовые функции
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${CONTAINER_TOOLS}/core/modules.sh"
# Загружаем нужную реализацию
load_module_implementation "$SCRIPT_DIR" "permissions"

# ============================================================================
# MODULE FUNCTION
# ============================================================================

module() {
    tlog header "PERMISSIONS VERIFY"

    if [[ $EUID -ne 0 ]]; then
        tlog warning "Not running as root (UID: $EUID) - some permission operations may fail"
    fi

    tlog info "Verify permissions for owner: $OWNER_STRING ($CONTAINER_USER:$CONTAINER_GROUP)"

    tlog step "1" "Verifying permissions"
    if ! verify_permissions; then
        tlog error "Permissions verification failed"
        return 1
    fi

    # ========================================================================
    # PERMISSIONS SUMMARY
    # ========================================================================

    tlog info "Permissions setup summary:"
    tlog info "  Container temp: $CONTAINER_TEMP (700/600, owner: $CONTAINER_USER)"
    tlog info "  tlog directory: /var/log/$CONTAINER_NAME (700/600, owner: $CONTAINER_USER)"
    tlog info "  Init scripts: $CONTAINER_ENTRYPOINT_SCRIPTS (700/700 + executable, owner: $CONTAINER_USER)"
    tlog info "  Configs: $CONTAINER_ENTRYPOINT_CONFIGS (700/600, owner: $CONTAINER_USER)"
    tlog info "  Dependencies: $CONTAINER_ENTRYPOINT_DEPENDENCIES (700/700 + executable, owner: $CONTAINER_USER)"
    tlog info "  Container tools: $CONTAINER_TOOLS (750/750 + executable, owner: $CONTAINER_USER)"

    # ========================================================================
    # COMPLETION
    # ========================================================================

    tlog success "Permissions verify module completed successfully"
    return 0
}

# ============================================================================
# ENTRY POINT
# ============================================================================

# Запускаем модуль и завершаем скрипт с его кодом
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  module "$@"
  exit $?
fi