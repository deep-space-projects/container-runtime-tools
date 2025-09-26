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
    tlog header "PERMISSIONS SETUP"

    if [[ $EUID -ne 0 ]]; then
        tlog warning "Not running as root (UID: $EUID) - some permission operations may fail"
    fi

    tlog info "Setting up permissions for owner: $OWNER_STRING ($CONTAINER_USER:$CONTAINER_GROUP)"
    tlog info "Container temp directory: $CONTAINER_TEMP"

    # ========================================================================
    # 1. SETUP CONTAINER-TOOLS PERMISSIONS
    # ========================================================================

    tlog step "1" "Setting up container-tools permissions"
    if ! setup_container_tools_permissions; then
        tlog error "Container-tools permissions setup failed"
        return 1
    fi


    # ========================================================================
    # 1. CONTAINER TEMP DIRECTORY
    # ========================================================================

    tlog step "1" "Setting up container temp directory: $CONTAINER_TEMP"
    if ! setup_container_temp_directory; then
        tlog error "Container temp directory setup failed"
        return 1
    fi

    # ========================================================================
    # 2. USER INIT SCRIPTS (if exist)
    # ========================================================================

    tlog step "2" "Setting up user init scripts permissions"
    if ! setup_user_init_scripts; then
        tlog error "User init scripts permissions setup failed"
        return 1
    fi

    # ========================================================================
    # 3. USER CONFIGS (if exist)
    # ========================================================================

    tlog step "3" "Setting up user configs permissions"
    if ! setup_user_configs; then
        tlog error "User configs permissions setup failed"
        return 1
    fi

    # ========================================================================
    # 4. USER DEPENDENCIES SCRIPTS (if exist)
    # ========================================================================

    tlog step "4" "Setting up user dependencies scripts permissions"
    if ! setup_user_dependencies_scripts; then
        tlog error "User dependencies scripts permissions setup failed"
        return 1
    fi

    # ========================================================================
    # 5. CONTAINER TOOLS
    # ========================================================================

    tlog step "5" "Setting up container tools permissions"
    if ! setup_container_tools; then
        tlog error "Container tools permissions setup failed"
        return 1
    fi

    # ========================================================================
    # COMPLETION
    # ========================================================================

    tlog success "Permissions setup module completed successfully"
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