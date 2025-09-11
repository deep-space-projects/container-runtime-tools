#!/bin/bash
# Descriptor for entrypoint command modules

handle_args() {
    # Сохраняем аргументы командной строки для финального exec (после парсинга)
    tlog debug "Final command (before proceed): $*"

    local final_command="$*"
    if [[ -z "$final_command" ]]; then
        tlog error "No command specified to execute"
        tlog error "Usage: $0 <command> [--range=RANGE] <command> [args...]"
        return 1
    fi

    # Экспортируем финальную команду для модуля 99-exec-command.sh
    export ENTRYPOINT_FINAL_COMMAND="$final_command"

    tlog info "Final command (after proceed): $final_command"
    tlog info ""
    
    return 0
}

# Валидация обязательных переменных окружения
validate_environment() {
    tlog info "Validating environment configuration..."

    local required_vars=(
        "CONTAINER_USER"
        "CONTAINER_UID"
        "CONTAINER_GID"
        "CONTAINER_NAME"
        "CONTAINER_TOOLS"
        "CONTAINER_TEMP"
        "CONTAINER_ENTRYPOINT_SCRIPTS"
        "CONTAINER_ENTRYPOINT_CONFIGS"
        "CONTAINER_ENTRYPOINT_DEPENDENCIES"
    )

    local optional_vars=(
        "CONTAINER_GROUP"
        "EXEC_MODE"
        "EXEC_ERROR_POLICY"
        "DEPENDENCY_TIMEOUT"
        "CONTAINER_WORKING_DIRS"
        "CONTAINER_WORKING_DIRS_RESTRICTIONS"
    )

    # Проверяем обязательные переменные
    if ! envs check-all "${required_vars[@]}"; then
        tlog error "Environment validation failed"
        return 1
    fi

    # Логируем опциональные переменные
    for var in "${optional_vars[@]}"; do
        local value="${!var:-<not set>}"
        tlog debug "Optional variable: $var=$value"
    done

    # Валидируем значения режимов
    local mode_name=$(modes exec-mode current)
    local policy_name=$(modes err-policy current)

    if [[ "$mode_name" == "UNKNOWN" ]]; then
        tlog warning "Unknown EXEC_MODE: $EXEC_MODE, defaulting to STANDARD"
        export EXEC_MODE=0
    fi

    if [[ "$policy_name" == "UNKNOWN" ]]; then
        tlog warning "Unknown EXEC_ERROR_POLICY: $EXEC_ERROR_POLICY, defaulting to STRICT"
        export EXEC_ERROR_POLICY=0
    fi

    tlog success "Environment validation completed"
    tlog info "Execution mode: $mode_name"
    tlog info "Error policy: $policy_name"

    return 0
}

get_module_operation_type() {
    local module_name="$1"

    case "$module_name" in
        00-*|01-*|02-*|03-*)
            echo "init"
            ;;
        40-dependencies.sh)
            echo "dependencies"
            ;;
        99-exec-command.sh)
            echo "exec"
            ;;
        *)
            echo "init"
            ;;
    esac
}