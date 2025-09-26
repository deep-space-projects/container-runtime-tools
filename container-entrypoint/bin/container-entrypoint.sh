#!/bin/bash
# ============================================================================
# Container Runtime
# Orchestrates command modules and executes final command
# ============================================================================

set -euo pipefail

# ============================================================================
# BASH REQUIREMENT CHECK
# ============================================================================

echo "

    ███████╗ ██████╗ ██████╗  ██████╗ ███████╗
    ██╔════╝██╔═══██╗██╔══██╗██╔════╝ ██╔════╝
    █████╗  ██║   ██║██████╔╝██║  ███╗█████╗
    ██╔══╝  ██║   ██║██╔══██╗██║   ██║██╔══╝
    ██║     ╚██████╔╝██║  ██║╚██████╔╝███████╗
    ╚═╝      ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝

    ██████╗  █████╗ ███╗   ██╗██████╗  █████╗
    ██╔══██╗██╔══██╗████╗  ██║██╔══██╗██╔══██╗
    ██████╔╝███████║██╔██╗ ██║██║  ██║███████║
    ██╔═══╝ ██╔══██║██║╚██╗██║██║  ██║██╔══██║
    ██║     ██║  ██║██║ ╚████║██████╔╝██║  ██║
    ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═══╝╚═════╝ ╚═╝  ╚═╝

"

# Проверяем наличие bash - обязательное требование
if ! command -v bash >/dev/null 2>&1; then
    echo "❌ ERROR: bash is required but not found"
    echo ""
    echo "Please install bash in your container:"
    echo "  Alpine:        RUN apk add --no-cache bash"
    echo "  Debian/Ubuntu: RUN apt-get update && apt-get install -y bash"
    echo "  RHEL/CentOS:   RUN yum install -y bash"
    echo "  Rocky/Alma:    RUN dnf install -y bash"
    echo ""
    exit 1
fi

# Проверяем обязательную переменную CONTAINER_TOOLS
if [[ -z "${CONTAINER_TOOLS:-}" ]]; then
    echo "❌ ERROR: CONTAINER_TOOLS environment variable is not set"
    echo ""
    echo "This variable should be set in your Dockerfile:"
    echo "  ENV CONTAINER_TOOLS=/opt/container-tools"
    echo ""
    exit 1
fi

# ============================================================================
# BOOTSTRAP AND DEPENDENCIES
# ============================================================================

# Используем абсолютные пути через CONTAINER_TOOLS
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMANDS_DIR="${SCRIPT_DIR}"

# ============================================================================
# COMMAND AND RANGE CONFIGURATION
# ============================================================================

# Глобальные переменные для новой функциональности
RUNTIME_COMMAND=""
RUNTIME_RANGE="00:100"
RUNTIME_FILTERED_MODULES=()

source_runtime_command() {
    local modules_dir="${COMMANDS_DIR}/${RUNTIME_COMMAND}"
    local descriptor_path="$modules_dir/${RUNTIME_COMMAND}.sh"
    source "$descriptor_path"
}

# Парсинг range строки в массив номеров модулей
parse_range_string() {
    local range_str="$1"
    local -a parsed_numbers=()

    # Если range пустой - возвращаем пустой массив
    if [[ -z "$range_str" ]]; then
        printf '%s\n' "${parsed_numbers[@]}"
        return 0
    fi

    # Разбиваем по запятым
    IFS=',' read -ra range_parts <<< "$range_str"

    for part in "${range_parts[@]}"; do
        part=$(echo "$part" | tr -d ' ')  # Убираем пробелы

        if [[ "$part" =~ ^[0-9]+:[0-9]+$ ]]; then
            # Это диапазон вида "00:50"
            local start="${part%:*}"
            local end="${part#*:}"

            # Валидация диапазона
            if [[ $((10#$start)) -ge $((10#$end)) ]]; then
                echo "❌ ERROR: Invalid range '$part' - start must be less than end"
                return 1
            fi

            # Генерируем числа в диапазоне
            for ((i=10#$start; i<10#$end; i++)); do
                parsed_numbers+=($(printf "%02d" $i))
            done

        elif [[ "$part" =~ ^[0-9]+$ ]]; then
            # Это отдельное число
            parsed_numbers+=($(printf "%02d" $((10#$part))))

        else
            echo "❌ ERROR: Invalid range format '$part'"
            return 1
        fi
    done

    # Убираем дубликаты и сортируем
    printf '%s\n' "${parsed_numbers[@]}" | sort -u
}

# Сбор и фильтрация модулей по диапазону
collect_and_filter_modules() {
    local -a all_modules=()
    local -a allowed_numbers=()
    local modules_dir="${COMMANDS_DIR}/${RUNTIME_COMMAND}"
    RUNTIME_FILTERED_MODULES=()

    tlog info "Dir for modules filtering: $modules_dir"

    # Проверяем существование директории команды
    if [[ ! -d "$modules_dir" ]]; then
        echo "❌ ERROR: Command directory not found: $modules_dir"
        return 1
    fi

    # Собираем все доступные модули
    while IFS= read -r -d '' module_file; do
        all_modules+=("$(basename "$module_file")")
    done < <(find "$modules_dir" -name "*.sh" -type f -print0)

    # Парсим диапазон
    mapfile -t allowed_numbers < <(parse_range_string "$RUNTIME_RANGE")
    if [[ $? -ne 0 ]]; then
        return 1
    fi

    # Фильтруем модули по номерам
    for module in "${all_modules[@]}"; do
        # Извлекаем номер из имени модуля (первые цифры до дефиса)
        if [[ "$module" =~ ^([0-9]+)- ]]; then
            local module_number=$(printf "%02d" $((10#${BASH_REMATCH[1]})))

            # Проверяем, входит ли номер в разрешенные
            for allowed in "${allowed_numbers[@]}"; do
                if [[ "$module_number" == "$allowed" ]]; then
                    RUNTIME_FILTERED_MODULES+=("$module")
                    break
                fi
            done
        fi
    done

    # Сортируем лексикографически
    IFS=$'\n' RUNTIME_FILTERED_MODULES=($(sort <<<"${RUNTIME_FILTERED_MODULES[*]}"))
    unset IFS

    return 0
}

# ============================================================================
# RUNTIME CONFIGURATION
# ============================================================================

# Стандартные переменные окружения с значениями по умолчанию
export EXEC_MODE="${EXEC_MODE:-0}"
export EXEC_ERROR_POLICY="${EXEC_ERROR_POLICY:-0}"
export DEPENDENCY_TIMEOUT="${DEPENDENCY_TIMEOUT:-300}"

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

# Выполнение модуля с проверкой режима
execute_module() {
    local module_name="$1"
    local operation_type="$2"  # init, dependencies, exec
    local modules_dir="${COMMANDS_DIR}/${RUNTIME_COMMAND}/modules"
    local module_path="$modules_dir/$module_name"

    # Проверяем нужно ли выполнять в текущем режиме
    if ! should_execute_in_mode "$operation_type" "$(modes exec-mode current)"; then
        tlog info "Skipping module $module_name due to exec mode: $(modes exec-mode current)"
        return 0
    fi

    # Проверяем существование модуля
    if [[ ! -f "$module_path" ]]; then
        local error_msg="Module not found: $module_path"
        case "$(modes err-policy current)" in
            "STRICT")
                tlog error "$error_msg"
                return 1
                ;;
            "SOFT"|"CUSTOM")
                tlog warning "$error_msg (continuing due to error policy)"
                return 0
                ;;
        esac
    fi

    tlog info ""
    tlog step "$(basename "$module_name" .sh | cut -d'-' -f1)" "Executing module: $module_name"

    # Выполняем модуль через bash
    source "$module_path"
    module
    local exit_code=$?

    if [[ $exit_code == 0 ]]; then
        tlog success "Module completed: $module_name"
        return 0
    else
        local error_msg="Source execution of separate module finished with fail condition, exit code: $exit_code"
        ops handle-quite "execute $module_name =_=" "$error_msg" "$exit_code"
        return $?
    fi
}

# Проверка нужно ли выполнять операцию в текущем режиме
should_execute_in_mode() {
    local operation_type="$1"  # init, exec, dependencies
    local mode_name="$2"

    case "$mode_name" in
        "STANDARD"|"DEBUG")
            return 0  # Выполняем все
            ;;
        "SKIP_ALL")
            if [[ "$operation_type" == "exec" ]]; then
                return 0  # Только exec команду
            else
                return 1  # Пропускаем инициализацию
            fi
            ;;
        "INIT_ONLY")
            if [[ "$operation_type" == "exec" ]]; then
                return 1  # НЕ выполняем exec
            else
                return 0  # Выполняем инициализацию
            fi
            ;;
        "DRY_RUN")
            return 0  # Выполняем все в режиме симуляции
            ;;
        *)
            tlog warning "Unknown exec mode: $mode_name, defaulting to STANDARD"
            return 0
            ;;
    esac
}


# Показать справку по использованию
show_help() {
    cat << 'EOF'
Container Runtime with Command Support

USAGE:
    container-runtime.sh <command> [--range=RANGE] [command_args...]

REQUIRED PARAMETERS:
    <command>               Command to execute (directory name with modules)

OPTIONAL PARAMETERS:
    --range=RANGE           Module range to execute (default: "00:100")
    --help, -h              Show this help message

RANGE FORMATS:
    "00:50"                 Range from 00 to 49 (inclusive:exclusive)
    "10,20,30"             Individual modules
    "00:20,40,80:100"      Mixed ranges and individual modules

COMMANDS:
    entrypoint             Run entrypoint modules from entrypoint/ directory
    build                  Run build modules from build/ directory
    <custom>               Run modules from <custom>/ directory

EXAMPLES:
    # Run entrypoint command with full initialization
    container-runtime.sh entrypoint my-application --config=/etc/app.conf

    # Run build command with specific modules only
    container-runtime.sh build --range="00:20" /bin/bash

    # Run custom command with mixed module selection
    container-runtime.sh deploy --range="10:30,40" deploy-app.sh
EOF
}

# ============================================================================
# MAIN RUNTIME LOGIC
# ============================================================================

main() {
    local start_time=$(date +%s)

    # Парсим аргументы прямо здесь
    if [[ $# -eq 0 || "$1" =~ ^-- ]]; then
        echo "❌ ERROR: command parameter is required"
        echo ""
        show_help
        exit 1
    fi

    # Извлекаем команду
    RUNTIME_COMMAND="$1"
    shift

    # Загрузка скрипта с вспомогательными функциями
    source_runtime_command

    # Передаем в handle_args точно то, что вернул парсер
    if ! handle_args "$@"; then
        tlog error "Arguments handling failed, cannot continue"
        return 1
    fi


    # Валидация параметров среды исполнения
    if ! validate_environment; then
        tlog error "Environment validation failed, cannot continue"
        return 1
    fi

    # Собираем и фильтруем модули
    if ! collect_and_filter_modules; then
        tlog error "Failed to collect and filter modules"
        return 1
    fi

    # Информация о дальнейшем запуске
    tlog header "CONTAINER RUNTIME"
    tlog info "Container: $CONTAINER_NAME"
    tlog info "Target user: $CONTAINER_USER (UID: $CONTAINER_UID, GID: $CONTAINER_GID)"
    tlog info "Command: $RUNTIME_COMMAND"
    tlog info "Module range: $RUNTIME_RANGE"
    tlog info "Filtered modules: ${#RUNTIME_FILTERED_MODULES[@]} found"
    tlog info "Execution mode: $(modes exec-mode current) (EXEC_MODE=$EXEC_MODE)"
    tlog info "Error policy: $(modes err-policy current) (EXEC_ERROR_POLICY=$EXEC_ERROR_POLICY)"

    # Если нет модулей для выполнения
    if [[ ${#RUNTIME_FILTERED_MODULES[@]} -eq 0 ]]; then
        tlog warning "No modules to execute in command '$RUNTIME_COMMAND' with range '$RUNTIME_RANGE'"
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        tlog info "Total runtime duration: ${duration}s"
        return 0
    fi

    # ========================================================================
    # ВЫПОЛНЕНИЕ ОТФИЛЬТРОВАННЫХ МОДУЛЕЙ
    # ========================================================================

    tlog header "COMMAND EXECUTION: $RUNTIME_COMMAND"

    for module in "${RUNTIME_FILTERED_MODULES[@]}"; do
        local operation_type=$(get_module_operation_type "$module")

        # В режиме SKIP_ALL выполняем только exec модули
        if [[ "$(modes exec-mode current)" == "SKIP_ALL" && "$operation_type" != "exec" ]]; then
            tlog info "Skipping module $module due to SKIP_ALL mode"
            continue
        fi

        if ! execute_module "$module" "$operation_type"; then
            tlog error "Module execution failed: $module"
            return 1
        fi
    done

    # ========================================================================
    # ЗАВЕРШЕНИЕ
    # ========================================================================

    # Проверяем режим INIT_ONLY
    if [[ "$(modes exec-mode current)" == "INIT_ONLY" ]]; then
        tlog success "INIT_ONLY mode: initialization completed, skipping command execution"
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        tlog info "Total runtime duration: ${duration}s"
        return 0
    fi

    # Если мы дошли до сюда в DRY_RUN - это нормально
    if [[ "$(modes exec-mode current)" == "DRY_RUN" ]]; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        tlog success "DRY RUN completed successfully"
        tlog info "Total runtime duration: ${duration}s"
        return 0
    fi

    # Если мы дошли до сюда не в DRY_RUN - команда выполнилась и завершилась (нормально)
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    tlog success "Command completed successfully"
    tlog info "Total runtime duration: ${duration}s"
    return 0
}

# ============================================================================
# ENTRY POINT
# ============================================================================

# Обработка сигналов для graceful shutdown
trap 'tlog warning "Received termination signal, shutting down..."; exit 143' SIGTERM
trap 'tlog warning "Received interrupt signal, shutting down..."; exit 130' SIGINT

# Запуск основной логики
main "$@"
main_exit_code=$?

if [[ $main_exit_code -ne 0 ]]; then
    tlog error "Container runtime failed with exit code: $main_exit_code"
    exit $main_exit_code
fi

# Если main() вернула 0 - все прошло успешно
tlog success "Container runtime completed successfully"
exit 0

