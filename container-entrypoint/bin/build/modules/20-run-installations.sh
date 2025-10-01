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
load_module_implementation "$SCRIPT_DIR" "run-installations"

# ============================================================================
# MODULE FUNCTION
# ============================================================================

module() {
    tlog header "RUN CONTAINER INSTALLATIONS"

    if [[ -z "${CONTAINER_ENTRYPOINT_RUN_SCRIPTS}" ]]; then
        tlog warning "Run container installations skipped. Cause is missing CONTAINER_ENTRYPOINT_RUN_SCRIPTS env variable"
        return 0
    fi

    local CORE_INSTALL_DIR="${CONTAINER_ENTRYPOINT_RUN_SCRIPTS}"
    local ROOT_INSTALL_DIR="${CORE_INSTALL_DIR}/root"
    local USER_INSTALL_DIR="${CORE_INSTALL_DIR}/user"

    tlog info "Show installation directories roots
    ROOT_INSTALL_DIR=$ROOT_INSTALL_DIR
    USER_INSTALL_DIR=$USER_INSTALL_DIR
    "

    tlog step "1" "Run root user installations"

    if [[ -d "${ROOT_INSTALL_DIR}" ]]; then
        if ! run_root_installations "${ROOT_INSTALL_DIR}"; then
            tlog error "Run root installations failed"
            return 1
        fi
    else
        tlog warning "Root install directory ($ROOT_INSTALL_DIR) is missed. Run installations step for root user scripts skipped!"
    fi

    if [[ -d "${USER_INSTALL_DIR}" ]]; then
        tlog step "2" "Run ${CONTAINER_USER} user installations"

        if ! chown -R "${CONTAINER_UID}:${CONTAINER_GID}" "$USER_INSTALL_DIR"; then
            tlog error "Change privileges for USER_INSTALL_DIR ($USER_INSTALL_DIR) directory for ${CONTAINER_USER} ($CONTAINER_UID:$CONTAINER_GID) failed"
            return 1
        fi

        # надо в новый контекст перезагрузить функции
        if ! su - "${CONTAINER_USER}" -c "
            source '${CONTAINER_TOOLS}/core/modules.sh'
            load_module_implementation '$SCRIPT_DIR' 'run-installations'
            run_user_installations '${USER_INSTALL_DIR}'
        "; then
            tlog error "Run ${CONTAINER_USER} installations failed"
            return 1
        fi
    else
        tlog warning "User install directory ($USER_INSTALL_DIR) is missed. Run installations step for ${CONTAINER_USER} user scripts skipped!"
    fi

    tlog success "Run installation scripts module completed successfully"
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