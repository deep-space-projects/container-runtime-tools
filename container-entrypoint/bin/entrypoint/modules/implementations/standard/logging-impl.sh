#!/bin/bash
# ============================================================================
# Standard Logging Setup Implementation
# ============================================================================

set -euo pipefail

setup_basic_logging_variables() {
    # Устанавливаем базовые переменные логирования только если они не установлены
    if [[ -z "${LOG_DIR:-}" ]]; then
        export LOG_DIR="$LOG_HOME/$CONTAINER_NAME"
        tlog info "Set LOG_DIR: $LOG_DIR"
    else
        tlog info "LOG_DIR already set: $LOG_DIR"
    fi

    if [[ -z "${LOG_LEVEL:-}" ]]; then
        export LOG_LEVEL="INFO"
        tlog info "Set LOG_LEVEL: $LOG_LEVEL"
    else
        tlog info "LOG_LEVEL already set: $LOG_LEVEL"
    fi

    tlog success "Basic logging variables configured"
}

setup_log_directory() {
    tlog info "Configuring tlog directory: $LOG_DIR"

    if ! permissions setup --privileged=true --path="$LOG_DIR" --owner="$OWNER_STRING" \
                           --dir-perms="700" --file-perms="600" --flags="create,strict,recursive"; then
        ops handle-quite "setup tlog directory" "Path: $LOG_DIR" 1
    else
        tlog success "Log directory configured: $LOG_DIR"
    fi
}

verify_log_directory() {
    log_dir="$LOG_DIR"

    # Проверяем директорию логов
    if [[ -d "$log_dir" ]]; then
        tlog debug "✓ log directory exists: $log_dir"
    else
        tlog debug "→ log directory will be created: $log_dir"
        ops handle-quite "verify tlog directory" "Directory not found: $LOG_DIR" 1
    fi
}