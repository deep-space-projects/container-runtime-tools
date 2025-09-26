#!/bin/bash
# ============================================================================
# Volumes Setup Module
# Sets up ownership for container volume directories
# ============================================================================

set -euo pipefail

# Подключаем базовые функции
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${CONTAINER_TOOLS}/core/modules.sh"
# Загружаем нужную реализацию
load_module_implementation "$SCRIPT_DIR" "volumes"

# ============================================================================
# MODULE FUNCTION
# ============================================================================

module() {
    tlog header "VOLUMES SETUP"

    tlog info "Configuring volume directories ownership for container: $CONTAINER_NAME"

    # Проверяем наличие переменной $VOLUME_DIRS
    if [[ -z "${VOLUME_DIRS:-}" ]]; then
        tlog info "VOLUME_DIRS not specified"
        tlog success "Volumes setup module completed successfully (no action needed)"
        return 0  # Сигнал для успешного выхода из основного модуля
    fi

    # ========================================================================
    # 1. CHECK VOLUME CONFIGURATION
    # ========================================================================

    tlog step "1" "Checking volume configuration"
    check_volume_configuration

    if ! check_volume_configuration; then
        return 1
    fi

    # ========================================================================
    # 2. PARSE VOLUME DIRECTORIES
    # ========================================================================

    tlog step "2" "Parsing volume directories"
    if ! parse_volume_directories; then
        tlog error "Volume directories parsing failed"
        return 1
    fi

    # ========================================================================
    # 3. VALIDATE VOLUME DIRECTORIES
    # ========================================================================

    tlog step "3" "Validating volume directories"
    if ! validate_volume_directories; then
        tlog error "Volume directories validation failed"
        return 1
    fi

    # ========================================================================
    # 4. CHANGE OWNERSHIP
    # ========================================================================

    tlog step "4" "Changing volume directories ownership"
    if ! change_volumes_ownership; then
        tlog error "Volume directories ownership change failed"
        return 1
    fi

    # ========================================================================
    # 5. VERIFY OWNERSHIP
    # ========================================================================

    tlog step "5" "Verifying volume directories ownership"
    if ! verify_volumes_ownership; then
        tlog error "Volume directories ownership verification failed"
        return 1
    fi

    # ========================================================================
    # VOLUMES SUMMARY
    # ========================================================================

    tlog info "Volumes setup summary:"
    tlog info "  Volume directories: ${VOLUME_DIRS_ARRAY[*]}"
    tlog info "  Owner: $CONTAINER_USER:$CONTAINER_GROUP ($CONTAINER_UID:$CONTAINER_GID)"
    tlog info "  Processed: ${#VOLUME_DIRS_ARRAY[@]} directories"

    # ========================================================================
    # COMPLETION
    # ========================================================================

    tlog success "Volumes setup module completed successfully"
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

