#!/bin/bash
# Descriptor for entrypoint command modules

handle_args() {
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
    )

    local optional_vars=(
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

    return 0
}

get_module_operation_type() {
    echo "init"
}