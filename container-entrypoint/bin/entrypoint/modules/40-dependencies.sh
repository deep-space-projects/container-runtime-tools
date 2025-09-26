#!/bin/bash
# ============================================================================
# Dependencies Waiting Module
# Executes dependency waiting scripts with total timeout control
# ============================================================================

set -euo pipefail

# Подключаем базовые функции
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${CONTAINER_TOOLS}/core/modules.sh"
# Загружаем нужную реализацию
load_module_implementation "$SCRIPT_DIR" "dependencies"

# ============================================================================
# MODULE FUNCTION
# ============================================================================

module() {
    tlog header "DEPENDENCIES WAITING"

    tlog info "Checking for dependency waiting scripts in: $CONTAINER_ENTRYPOINT_DEPENDENCIES"
    tlog info "Total timeout for all dependencies: ${DEPENDENCY_TIMEOUT}s"

    # ========================================================================
    # 1. CHECK DEPENDENCIES SCRIPTS DIRECTORY
    # ========================================================================

    tlog step "1" "Checking dependencies scripts directory"
    if ! check_dependencies_scripts_directory; then
        tlog error "Dependencies scripts directory check failed"
        return 1
    fi

    # ========================================================================
    # 2. EXECUTE DEPENDENCIES SCRIPTS WITH TOTAL TIMEOUT
    # ========================================================================

    tlog step "2" "Executing dependencies scripts with total timeout"
    if ! execute_dependencies_scripts; then
        tlog error "Dependencies scripts execution failed"
        return 1
    fi

    # ========================================================================
    # COMPLETION
    # ========================================================================

    tlog success "Dependencies waiting module completed successfully"
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