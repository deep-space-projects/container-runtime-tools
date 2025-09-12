#!/bin/bash
# ============================================================================
# Standard Permissions Setup Implementation
# ============================================================================

set -euo pipefail

verify_permissions() {
    # Проверяем что критически важные директории имеют правильного владельца
    critical_dirs=(
        "$LOG_DIR"
        "$CONTAINER_TOOLS"
        "$CONTAINER_TEMP"
    )

    verification_failed=false

    for dir in "${critical_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            # Проверяем владельца
            if commands exists stat; then
                dir_owner=$(stat -c '%U:%G' "$dir" 2>/dev/null || echo "unknown:unknown")
                expected_owner="$CONTAINER_USER:$CONTAINER_GROUP"

                if [[ "$dir_owner" == "$expected_owner" ]]; then
                    tlog debug "✓ Correct owner for $dir: $dir_owner"
                else
                    tlog warning "Owner mismatch for $dir: expected $expected_owner, got $dir_owner"
                    verification_failed=true
                fi
            fi

            # Проверяем базовые права доступа
            if [[ -r "$dir" ]] && [[ -x "$dir" ]]; then
                tlog debug "✓ Directory accessible: $dir"
            else
                tlog warning "Directory not accessible: $dir"
                verification_failed=true
            fi
        else
            tlog warning "Critical directory not found: $dir"
            verification_failed=true
        fi
    done

    # Проверяем все .sh файлы в core директории на исполняемость
    tlog info "Checking core scripts executability..."
    core_scripts=()
    while IFS= read -r -d '' script; do
        core_scripts+=("$script")
    done < <(find "$CONTAINER_TOOLS/core" -name "*.sh" -type f -print0 2>/dev/null)

    if [[ ${#core_scripts[@]} -eq 0 ]]; then
        tlog warning "No .sh files found in core directory: $CONTAINER_TOOLS/core"
        verification_failed=true
    else
        tlog info "Found ${#core_scripts[@]} core scripts to verify"
        for script in "${core_scripts[@]}"; do
            if [[ -x "$script" ]]; then
                tlog debug "✓ Executable: $(basename "$script")"
            else
                tlog warning "Not executable: $(basename "$script")"
                verification_failed=true
            fi
        done
    fi

    if [[ "$verification_failed" == "true" ]]; then
        ops handle-quite "permissions verification" "Some files/directories have incorrect permissions or ownership" 1
    else
        tlog success "Permissions verification completed successfully"
    fi
}