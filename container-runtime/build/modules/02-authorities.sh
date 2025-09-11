#!/bin/bash
# ============================================================================
# Authorities Setup Module
# Sets up container user, group and permissions management
# ============================================================================

set -euo pipefail

# Подключаем базовые функции
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${CONTAINER_TOOLS}/core/modules.sh"
# Загружаем нужную реализацию
load_module_implementation "$SCRIPT_DIR" "authorities"

# ============================================================================
# MODULE FUNCTION
# ============================================================================

module() {
    tlog header "AUTHORITIES SETUP"

    tlog info "Configuring user authorities and permissions for container: $CONTAINER_NAME"

    # ========================================================================
    # 1. SETUP BASIC VARIABLES
    # ========================================================================

    tlog step "1" "Verify authorities variables"
    if ! verify_authorities_variables; then
        tlog error "Authorities variables verify failed"
        return 1
    fi

    # ========================================================================
    # 2. SETUP GROUP
    # ========================================================================

    tlog step "2" "Setting up container group"
    if ! setup_container_group; then
        tlog error "Container group setup failed"
        return 1
    fi

    # ========================================================================
    # 3. SETUP USER
    # ========================================================================

    tlog step "3" "Setting up container user"
    if ! setup_container_user; then
        tlog error "Container user setup failed"
        return 1
    fi

    # ========================================================================
    # 4. VERIFY SETUP
    # ========================================================================

    tlog step "4" "Verifying authorities setup"
    if ! verify_authorities_setup; then
        tlog error "Authorities setup verification failed"
        return 1
    fi

    # ========================================================================
    # AUTHORITIES SUMMARY
    # ========================================================================

    tlog info "Authorities setup summary:"
    tlog info "  Container user: $CONTAINER_USER ($CONTAINER_UID)"
    tlog info "  Container group: $CONTAINER_GROUP ($CONTAINER_GID)"
    tlog info "  System type: ${SYSTEM_TYPE:-unknown}"
    tlog info "  Container-tools: $CONTAINER_TOOLS"

    # ========================================================================
    # COMPLETION
    # ========================================================================

    tlog success "Authorities setup module completed successfully"
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