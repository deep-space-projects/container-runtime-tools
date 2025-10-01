#!/bin/bash
# ============================================================================
# Standard Environment Validation Implementation
# ============================================================================

set -euo pipefail

detect_operating_system() {
    OS_TYPE=$(os detect)
    OS_FAMILY=$(os family)
    IS_MINIMAL=$(os is-mini && tlog info "true" || tlog info "false")

    tlog info "Operating System: $OS_TYPE"
    tlog info "OS Family: $OS_FAMILY"
    tlog info "Minimal system: $IS_MINIMAL"

    # Экспортируем информацию об ОС для других модулей
    export DETECTED_OS="$OS_TYPE"
    export DETECTED_OS_FAMILY="$OS_FAMILY"
    export IS_MINIMAL_SYSTEM="$IS_MINIMAL"
}

validate_system_commands() {
    required_commands=("id" "whoami" "chmod" "chown")
    optional_commands=("find" "grep" "cut" "sort")

    missing_required=()
    for cmd in "${required_commands[@]}"; do
        if ! commands exists "$cmd"; then
            missing_required+=("$cmd")
        else
            tlog debug "✓ $cmd available"
        fi
    done

    if [[ ${#missing_required[@]} -gt 0 ]]; then
        tlog error "Missing required system commands:"
        for cmd in "${missing_required[@]}"; do
            tlog error "  - $cmd"
        done
        ops handle-quite "validate system commands" "Missing required commands: ${missing_required[*]}" 1
    fi

    missing_optional=()
    for cmd in "${optional_commands[@]}"; do
        if ! commands exists "$cmd"; then
            missing_optional+=("$cmd")
        else
            tlog debug "✓ $cmd available"
        fi
    done

    if [[ ${#missing_optional[@]} -gt 0 ]]; then
        tlog warning "Missing optional commands (some features may be limited):"
        for cmd in "${missing_optional[@]}"; do
            tlog warning "  - $cmd"
        done
    fi

    tlog success "System commands check completed"
}

validate_directory_structure() {
    # Проверяем стандартные директории
    standard_dirs=(
        "$CONTAINER_ENTRYPOINT_SCRIPTS"
        "$CONTAINER_ENTRYPOINT_CONFIGS"
        "$CONTAINER_ENTRYPOINT_DEPENDENCIES"
    )

    for dir in "${standard_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            tlog debug "✓ Directory exists: $dir"
        else
            tlog debug "→ Directory will be created if needed: $dir"
        fi
    done

    tlog success "Directory structure validation completed"
}

export_runtime_information() {
    # Экспортируем информацию для других модулей
    export RUNTIME_START_TIME="$(date +%s)"
    export RUNTIME_START_ISO="$(date -Iseconds)"
    export CURRENT_WORKING_DIR="$(pwd)"
    export OWNER_STRING="$CONTAINER_UID:$CONTAINER_GID"

    # Получаем информацию о текущем пользователе
    users get-info $(whoami)

    tlog info "Runtime information:"
    tlog info "  Start time: $RUNTIME_START_ISO"
    tlog info "  Working directory: $CURRENT_WORKING_DIR"
    tlog info "  Current user: $(whoami) (UID: $(users get-uid $(whoami))"
    tlog info "  Target user: $CONTAINER_USER (UID: $CONTAINER_UID)"
}

import_runtime_environment_files() {
    local env_dir="${CONTAINER_ENTRYPOINT_ENVIRONMENT_VARS}"

    if [[ -z ${env_dir} ]]; then
        tlog info "Container environment var directory not specified, skip import"
        return 0
    fi

    # Создаем или очищаем system profile файл
    tlog info "Создание system profile файла..."
    tee /etc/profile.d/custom_vars.sh > /dev/null << EOF
# Автоматически сгенерировано из .env файлов
# Дата создания: $(date)
# Источник: $env_dir

EOF
    chmod 644 /etc/profile.d/custom_vars.sh

    for bashrc_file in "${HOME}/.bashrc" "/home/${CONTAINER_USER}/.bashrc"; do
        cat >> "$bashrc_file" << 'EOF'

# IMPORT CUSTOM USER PROPERTIES
[[ -s "/etc/profile.d/custom_vars.sh" ]] && source "/etc/profile.d/custom_vars.sh"
EOF
    done


    # Ищем все .env файлы в директории
    local env_files=()
    while IFS= read -r -d '' file; do
        env_files+=("$file")
    done < <(find "$env_dir" -maxdepth 1 -name "*.env*" -type f -print0)

    # Сортируем файлы для предсказуемого порядка
    IFS=$'\n' env_files=($(sort <<<"${env_files[*]}"))
    unset IFS

    if [[ ${#env_files[@]} -eq 0 ]]; then
        tlog info "Не найдено .env файлов в директории $env_dir"
        return 0
    fi

    tlog info "Найдено .env файлов: ${#env_files[@]}"

    # Обрабатываем каждый файл
    for env_file in "${env_files[@]}"; do
        tlog info ""
        tlog info "Обработка файла: $(basename "$env_file")"
        tlog info "=========================================="

        # Проверяем, что файл читаем
        if [[ ! -r "$env_file" ]]; then
            tlog warning "Пропускаем: Нет прав на чтение файла"
            continue
        fi

        # Добавляем в system profile && в текущую сессию
        __export_env_variables "$env_file"

        tlog info "Файл обработан: $(basename "$env_file")"
    done

    tlog info ""
    tlog info "=========================================="
    tlog info "Все .env файлы обработаны!"
    tlog info "System profile: /etc/profile.d/custom_vars.sh"
    tlog info "Переменные экспортированы в текущую сессию"

}

__export_env_variables() {
    local env_file="$1"
    local profile_file="/etc/profile.d/custom_vars.sh"

    tlog info "Экспорт переменных из $env_file в текущую сессию..."

    # Добавляем заголовок с именем файла
    echo "# --- Переменные из $(basename "$env_file") ---" | tee -a "$profile_file" > /dev/null

    while read -r line; do
        # Пропускаем комментарии и пустые строки
        [[ $line =~ ^# ]] || [[ -z $line ]] && continue

        # Экспортируем переменную
        if [[ $line =~ ^[a-zA-Z_][a-zA-Z0-9_]*!?= ]]; then
            override=false

            var_name="${line%%=*}"
            var_value=$(echo "${line#*=}" | envsubst)

            # Проверяем, заканчивается ли переменная на !
            if [[ $var_name == *! ]]; then
                override=true
                # Убираем ! из названия переменной
                var_name="${var_name%!}"
            fi

            if envs check $var_name && [[ $override == "false" ]]; then
              tlog warning "⚠ Переменная уже объявлена: $var_name=${!var_name}, переменная проигнорирована"
              continue
            fi

            export "$var_name=$var_value"
            echo "export $var_name=$var_value" | tee -a "$profile_file" > /dev/null

            tlog info "✓ $line"

        else
            tlog info "✗ Неверный формат: $line"
        fi
    done < "$env_file"


    # Добавляем пустую строку для читаемости
    echo | tee -a "$profile_file" > /dev/null
}