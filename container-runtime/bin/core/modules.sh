#!/bin/bash

set -euo pipefail

# Загрузка нужной реализации модуля в зависимости от режима выполнения
load_module_implementation() {
    local module_path="$1"
    local module_name="$2"

    if [[ -z "$module_name" ]]; then
        tlog error "Module name is required for load_module_implementation"
        return 1
    fi

    local impl_file
    case "$(modes exec-mode current)" in
        "DRY_RUN")
            impl_file="${module_path}/implementations/dry_run/${module_name}-impl.sh"
            ;;
        *)
            impl_file="${module_path}/implementations/standard/${module_name}-impl.sh"
            ;;
    esac

    if [[ ! -f "$impl_file" ]]; then
        log_error "Implementation file not found: $impl_file"
        return 1
    fi

    tlog debug "Loading $(modes exec-mode current) implementation: $(basename "$impl_file")"
    source "$impl_file"
}

export -f load_module_implementation