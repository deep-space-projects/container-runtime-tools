#!/bin/bash
# ============================================================================
# Standard Permissions Setup Implementation
# ============================================================================

set -euo pipefail

setup_container_tools_permissions() {
    tlog info "Setting up container-tools permissions: $CONTAINER_TOOLS"

    if [[ ! -d "$CONTAINER_TOOLS" ]]; then
        tlog warning "CONTAINER_TOOLS directory not found: $CONTAINER_TOOLS"
        tlog info "Skipping container-tools setup"
        return 0
    fi

    # Делаем все .sh файлы исполняемыми
    tlog info "Making shell scripts executable"
    if ! find "$CONTAINER_TOOLS" -name "*.sh" -type f -exec chmod +x {} \;; then
        tlog error "Failed to make scripts executable"
        return 1
    fi

    # Устанавливаем права владения (если запущено под root)
    if [[ $EUID -eq 0 ]]; then
        tlog info "Setting ownership to $CONTAINER_USER:$CONTAINER_GROUP"
        if ! chown -R "$CONTAINER_UID:$CONTAINER_GID" "$CONTAINER_TOOLS"; then
            tlog error "Failed to set ownership"
            return 1
        fi
        tlog success "Ownership set successfully"
    else
        tlog warning "Not running as root, skipping ownership setup"
    fi

    tlog success "Container-tools permissions configured successfully"
}


setup_container_temp_directory() {
    if ! permissions setup --privileged=true --path="$CONTAINER_TEMP" --owner="$OWNER_STRING" \
                           --dir-perms="700" --file-perms="600" --flags="create,strict,recursive"; then
        ops handle-quite "setup container temp directory" "Path: $CONTAINER_TEMP" 1
    else
        tlog success "Container temp directory configured: $CONTAINER_TEMP"
    fi
}

setup_user_init_scripts() {
    tlog info "Checking user init scripts: $CONTAINER_ENTRYPOINT_SCRIPTS"

    if [[ -d "$CONTAINER_ENTRYPOINT_SCRIPTS" ]]; then
        tlog info "User init scripts directory found, setting permissions"
        if ! permissions setup --privileged=true --path="$CONTAINER_ENTRYPOINT_SCRIPTS" --owner="$OWNER_STRING" \
                               --dir-perms="700" --file-perms="700" --flags="required,strict,recursive,executable"; then
            ops handle-quite "setup init scripts permissions" "Path: $CONTAINER_ENTRYPOINT_SCRIPTS" 1
        else
            tlog success "Init scripts permissions configured: $CONTAINER_ENTRYPOINT_SCRIPTS"
        fi
    else
        tlog info "No user init scripts directory found (this is normal)"
    fi
}

setup_user_configs() {
    tlog info "Checking user configs: $CONTAINER_ENTRYPOINT_CONFIGS"

    if [[ -d "$CONTAINER_ENTRYPOINT_CONFIGS" ]]; then
        tlog info "User configs directory found, setting permissions"
        if ! permissions setup --privileged=true --path="$CONTAINER_ENTRYPOINT_CONFIGS" --owner="$OWNER_STRING" \
                               --dir-perms="700" --file-perms="600" --flags="required,strict,recursive"; then
            ops handle-quite "setup configs permissions" "Path: $CONTAINER_ENTRYPOINT_CONFIGS" 1
        else
            tlog success "Configs permissions configured: $CONTAINER_ENTRYPOINT_CONFIGS"
        fi
    else
        tlog info "No user configs directory found (this is normal)"
    fi
}

setup_user_dependencies_scripts() {
    tlog info "Checking user dependencies scripts: $CONTAINER_ENTRYPOINT_DEPENDENCIES"

    if [[ -d "$CONTAINER_ENTRYPOINT_DEPENDENCIES" ]]; then
        tlog info "User dependencies scripts directory found, setting permissions"
        if ! permissions setup --privileged=true --path="$CONTAINER_ENTRYPOINT_DEPENDENCIES" --owner="$OWNER_STRING" \
                               --dir-perms="700" --file-perms="700" --flags="required,strict,recursive,executable"; then
            ops handle-quite "setup dependencies scripts permissions" "Path: $CONTAINER_ENTRYPOINT_DEPENDENCIES" 1
        else
            tlog success "Dependencies scripts permissions configured: $CONTAINER_ENTRYPOINT_DEPENDENCIES"
        fi
    else
        tlog info "No user dependencies scripts directory found (this is normal)"
    fi
}

setup_container_tools() {
    tlog info "Configuring container tools: $CONTAINER_TOOLS"

    # Container tools должны быть доступны владельцу и группе
    if ! permissions setup --privileged=true --path="$CONTAINER_TOOLS" --owner="$OWNER_STRING" \
                           --dir-perms="750" --file-perms="750" --flags="required,strict,recursive,executable"; then
        ops handle-quite "setup container tools permissions" "Path: $CONTAINER_TOOLS" 1
    else
        tlog success "Container tools permissions configured: $CONTAINER_TOOLS"
    fi
}