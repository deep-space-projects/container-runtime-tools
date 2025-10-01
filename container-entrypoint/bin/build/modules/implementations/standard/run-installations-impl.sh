#!/bin/bash
# ============================================================================
# Working Directories Permissions Implementation - Standard Mode
# Real execution of working directories permissions setup
# ============================================================================

set -euo pipefail

run_root_installations() {
  run_scripts_in_directory "$1"
}


run_user_installations() {
  run_scripts_in_directory "$1"
}

run_scripts_in_directory() {
    local directory="$1"

    if [[ -z "$directory" ]]; then
        tlog error "Error: Directory parameter is required"
        return 1
    fi

    if [[ ! -d "$directory" ]]; then
        tlog error "Error: Directory '$directory' does not exist"
        return 1
    fi

    tlog info "Searching for .sh files in: $directory"

    # Поиск всех .sh файлов
    local script_files
    mapfile -t script_files < <(find "$directory" -type f -name "*.sh" | sort)

    if [[ ${#script_files[@]} -eq 0 ]]; then
        tlog warning "No .sh files found in '$directory'"
        return 0
    fi

    tlog info "Found ${#script_files[@]} script file(s)"

    # Итерация по найденным файлам
    for script in "${script_files[@]}"; do
        tlog debug "Processing: $script"

        # Делаем файл исполняемым
        if ! chmod +x "$script"; then
            tlog error "Error: Failed to make '$script' executable"
            return 1
        fi

        tlog debug "Executing: $script"

        # Выполняем скрипт
        if ! "$script"; then
            tlog error "Error: Script '$script' failed with exit code $?"
            return 1
        fi

        tlog success "Successfully executed: $script"
    done

    tlog success "All scripts executed successfully"
    return 0
}
