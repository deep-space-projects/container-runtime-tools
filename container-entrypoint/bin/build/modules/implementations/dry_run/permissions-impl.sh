#!/bin/bash
# ============================================================================
# DRY_RUN Permissions Setup Implementation
# ============================================================================

set -euo pipefail

setup_container_tools_permissions() {
    tlog info "[DRY RUN] Would set up container-tools permissions: $CONTAINER_TOOLS"

    if [[ ! -d "$CONTAINER_TOOLS" ]]; then
        tlog info "[DRY RUN] CONTAINER_TOOLS directory not found: $CONTAINER_TOOLS"
        tlog info "[DRY RUN] Would skip container-tools setup"
        return 0
    fi

    tlog info "[DRY RUN] Would make shell scripts executable"
    tlog info "[DRY RUN] Command: find $CONTAINER_TOOLS -name '*.sh' -type f -exec chmod +x {} ;"

    if [[ $EUID -eq 0 ]]; then
        tlog info "[DRY RUN] Would set ownership to $CONTAINER_USER:$CONTAINER_GROUP"
        tlog info "[DRY RUN] Command: chown -R $CONTAINER_UID:$CONTAINER_GID $CONTAINER_TOOLS"
    else
        tlog info "[DRY RUN] Not running as root, would skip ownership setup"
    fi
}

setup_container_temp_directory() {
    tlog info "[DRY RUN] Would create and configure: $CONTAINER_TEMP"
    tlog info "[DRY RUN] Would set owner: $CONTAINER_USER:$CONTAINER_GROUP"
    tlog info "[DRY RUN] Would set permissions: 700/600"
}

setup_user_init_scripts() {
    tlog info "[DRY RUN] Checking user init scripts: $CONTAINER_ENTRYPOINT_SCRIPTS"
    tlog info "[DRY RUN] Would check if $CONTAINER_ENTRYPOINT_SCRIPTS exists"
    tlog info "[DRY RUN] Would make .sh files executable for owner only"
}

setup_user_configs() {
    tlog info "[DRY RUN] Checking user configs: $CONTAINER_ENTRYPOINT_CONFIGS"
    tlog info "[DRY RUN] Would check if $CONTAINER_ENTRYPOINT_CONFIGS exists"
    tlog info "[DRY RUN] Would set owner and permissions 700/600"
}

setup_user_dependencies_scripts() {
    tlog info "[DRY RUN] Checking user dependencies scripts: $CONTAINER_ENTRYPOINT_DEPENDENCIES"
    tlog info "[DRY RUN] Would check if $CONTAINER_ENTRYPOINT_DEPENDENCIES exists"
    tlog info "[DRY RUN] Would make .sh files executable for owner only"
}

setup_container_tools() {
    tlog info "[DRY RUN] Configuring container tools: $CONTAINER_TOOLS"
    tlog info "[DRY RUN] Would set permissions on: $CONTAINER_TOOLS"
    tlog info "[DRY RUN] Would set owner: $CONTAINER_USER:$CONTAINER_GROUP"
    tlog info "[DRY RUN] Would make .sh files executable: 750/750"
}