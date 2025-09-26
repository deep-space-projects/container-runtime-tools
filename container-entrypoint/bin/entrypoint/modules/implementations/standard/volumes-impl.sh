#!/bin/bash
# ============================================================================
# Volumes Setup Implementation
# ============================================================================

set -euo pipefail

check_volume_configuration() {
    tlog info "Checking volume configuration"

    tlog info "VOLUME_DIRS: $VOLUME_DIRS"

    # Проверяем наличие переменных пользователя из authorities модуля
    if [[ -z "${CONTAINER_USER:-}" ]]; then
        tlog error "CONTAINER_USER not set - authorities module should run first"
        return 1
    fi

    if [[ -z "${CONTAINER_GROUP:-}" ]]; then
        tlog error "CONTAINER_GROUP not set - authorities module should run first"
        return 1
    fi

    if [[ -z "${CONTAINER_UID:-}" ]]; then
        tlog error "CONTAINER_UID not set - authorities module should run first"
        return 1
    fi

    if [[ -z "${CONTAINER_GID:-}" ]]; then
        tlog error "CONTAINER_GID not set - authorities module should run first"
        return 1
    fi

    tlog info "Target owner: $CONTAINER_USER:$CONTAINER_GROUP ($CONTAINER_UID:$CONTAINER_GID)"
    tlog success "Volume configuration check completed"
    return 0
}

parse_volume_directories() {
    tlog info "Parsing volume directories from VOLUME_DIRS"

    # Создаем массив директорий, разделяя по запятым
    IFS=',' read -ra VOLUME_DIRS_ARRAY <<< "$VOLUME_DIRS"

    # Убираем пробелы в начале и конце каждой директории
    local i=0
    for dir in "${VOLUME_DIRS_ARRAY[@]}"; do
        VOLUME_DIRS_ARRAY[i]=$(echo "$dir" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        ((i++))
    done

    # Экспортируем массив для использования в других функциях
    export VOLUME_DIRS_ARRAY

    tlog info "Parsed ${#VOLUME_DIRS_ARRAY[@]} volume directories:"
    for dir in "${VOLUME_DIRS_ARRAY[@]}"; do
        tlog info "  - $dir"
    done

    # Проверяем что есть хотя бы одна директория
    if [[ ${#VOLUME_DIRS_ARRAY[@]} -eq 0 ]]; then
        tlog error "No volume directories found after parsing"
        return 1
    fi

    tlog success "Volume directories parsing completed"
    return 0
}

validate_volume_directory() {
    local volume_dir="$1"

    # Проверяем что путь не пустой
    if [[ -z "$volume_dir" ]]; then
        tlog warning "Empty directory path found, skipping"
        return 1
    fi

    # Проверяем что директория существует
    if [[ ! -d "$volume_dir" ]]; then
        tlog warning "Directory does not exist: $volume_dir"
        return 1
    fi

    # Получаем текущего владельца
    local current_owner
    current_owner=$(stat -c '%U:%G' "$volume_dir" 2>/dev/null || echo "unknown:unknown")

    tlog debug "Directory $volume_dir - current owner: $current_owner"

    return 0
}

validate_volume_directories() {
    tlog info "Validating volume directories"

    local valid_dirs=()
    local invalid_count=0

    for dir in "${VOLUME_DIRS_ARRAY[@]}"; do
        if validate_volume_directory "$dir"; then
            valid_dirs+=("$dir")
            tlog debug "✓ Valid directory: $dir"
        else
            tlog warning "✗ Invalid directory: $dir"
            ((invalid_count++))
        fi
    done

    # Обновляем массив только валидными директориями
    VOLUME_DIRS_ARRAY=("${valid_dirs[@]}")

    tlog info "Validation results: ${#VOLUME_DIRS_ARRAY[@]} valid, $invalid_count invalid"

    # Если нет валидных директорий - это ошибка
    if [[ ${#VOLUME_DIRS_ARRAY[@]} -eq 0 ]]; then
        tlog error "No valid volume directories found"
        return 1
    fi

    tlog success "Volume directories validation completed"
    return 0
}

change_directory_ownership() {
    local volume_dir="$1"

    tlog debug "Changing ownership of: $volume_dir"

    # Получаем текущего владельца для логирования
    local current_owner
    current_owner=$(stat -c '%U:%G' "$volume_dir" 2>/dev/null || echo "unknown:unknown")

    # Меняем владельца БЕЗ рекурсии (-R не используем)
    if chown "$CONTAINER_UID:$CONTAINER_GID" "$volume_dir"; then
        tlog debug "✓ Ownership changed: $volume_dir ($current_owner → $CONTAINER_USER:$CONTAINER_GROUP)"
    else
        tlog error "✗ Failed to change ownership: $volume_dir"
        return 1
    fi

    if chmod 750 "$volume_dir"; then
        tlog debug "✓ Permissions changed to 750: $volume_dir"
    else
        tlog error "✗ Failed to change permissions: $volume_dir"
        return 1
    fi

    return 0
}

change_volumes_ownership() {
    tlog info "Changing ownership of volume directories to $CONTAINER_USER:$CONTAINER_GROUP"

    local success_count=0
    local error_count=0

    for dir in "${VOLUME_DIRS_ARRAY[@]}"; do
        if change_directory_ownership "$dir"; then
            ((success_count++))
        else
            ((error_count++))
        fi
    done

    tlog info "Ownership change results: $success_count successful, $error_count failed"

    # Если есть ошибки, но есть и успешные операции - предупреждение
    if [[ $error_count -gt 0 && $success_count -gt 0 ]]; then
        tlog warning "Some directories failed to change ownership"
    elif [[ $error_count -gt 0 ]]; then
        tlog error "All directories failed to change ownership"
        return 1
    fi

    tlog success "Volume directories ownership change completed"
    return 0
}

verify_volumes_ownership() {
    tlog info "Verifying volume directories ownership"

    local verified_count=0
    local mismatch_count=0

    for dir in "${VOLUME_DIRS_ARRAY[@]}"; do
        if [[ ! -d "$dir" ]]; then
            tlog warning "Directory no longer exists: $dir"
            ((mismatch_count++))
            continue
        fi

        # Получаем актуального владельца
        local actual_owner
        actual_owner=$(stat -c '%U:%G' "$dir" 2>/dev/null || echo "unknown:unknown")

        # Проверяем соответствие
        if [[ "$actual_owner" == "$CONTAINER_USER:$CONTAINER_GROUP" ]]; then
            tlog debug "✓ Correct ownership: $dir ($actual_owner)"
            ((verified_count++))
        else
            tlog warning "✗ Ownership mismatch: $dir (expected: $CONTAINER_USER:$CONTAINER_GROUP, actual: $actual_owner)"
            ((mismatch_count++))
        fi
    done

    tlog info "Verification results: $verified_count correct, $mismatch_count mismatched"

    if [[ $mismatch_count -gt 0 ]]; then
        tlog warning "Some directories have ownership mismatches"
    fi

    tlog success "Volume directories ownership verification completed"
    return 0
}