#!/bin/bash
# ============================================================================
# DRY_RUN Authorities Setup Implementation
# ============================================================================

set -euo pipefail

verify_authorities_variables() {
    tlog info "[DRY RUN] Would set up basic authorities variables:"

    if [[ -z "${CONTAINER_USER:-}" ]]; then
        tlog warning "[DRY RUN] CONTAINER_USER is required"
    fi

    if [[ -z "${CONTAINER_UID:-}" ]]; then
        tlog warning "[DRY RUN] CONTAINER_UID is required"

    fi

    if [[ -z "${CONTAINER_GROUP:-}" ]]; then
        tlog warning "[DRY RUN] CONTAINER_GROUP is required"
    fi

    if [[ -z "${CONTAINER_GID:-}" ]]; then
        tlog warning "[DRY RUN] CONTAINER_GID is required"
    fi
}

create_group_with_groupadd() {
    local group_name="$1"
    local group_id="$2"

    tlog info "[DRY RUN] Would use groupadd to create group"
    tlog info "[DRY RUN] Command: groupadd -g $group_id $group_name"
}

create_group_with_addgroup() {
    local group_name="$1"
    local group_id="$2"

    tlog info "[DRY RUN] Would use addgroup to create group"
    tlog info "[DRY RUN] Command: addgroup -g $group_id $group_name"
}

create_container_group() {
    local group_name="$1"
    local group_id="$2"

    tlog info "[DRY RUN] Would create group: $group_name ($group_id)"

    if command -v groupadd >/dev/null 2>&1; then
        create_group_with_groupadd "$group_name" "$group_id"
    elif command -v addgroup >/dev/null 2>&1; then
        create_group_with_addgroup "$group_name" "$group_id"
    else
        tlog info "[DRY RUN] Would fail: No group creation command found (groupadd/addgroup)"
    fi
}

setup_container_group() {
    tlog info "[DRY RUN] Would set up container group: $CONTAINER_GROUP ($CONTAINER_GID)"

    if ! group_exists "$CONTAINER_GROUP"; then
        create_container_group "$CONTAINER_GROUP" "$CONTAINER_GID"
        tlog info "[DRY RUN] Would create new group successfully"
    else
        tlog info "[DRY RUN] Group already exists, would skip creation: $CONTAINER_GROUP"
    fi
}

create_user_with_useradd() {
    local user_name="$1"
    local user_id="$2"
    local group_name="$3"

    tlog info "[DRY RUN] Would use useradd to create user"
    tlog info "[DRY RUN] First attempt: useradd -u $user_id -g $group_name -m -s /bin/bash $user_name"
    tlog info "[DRY RUN] Fallback: useradd -u $user_id -g $group_name $user_name"
}

create_user_with_adduser() {
    local user_name="$1"
    local user_id="$2"
    local group_name="$3"

    tlog info "[DRY RUN] Would use adduser (BusyBox) to create user"
    tlog info "[DRY RUN] Command: adduser -u $user_id -G $group_name -D -s /bin/bash $user_name"
}

create_container_user() {
    local user_name="$1"
    local user_id="$2"
    local group_name="$3"

    tlog info "[DRY RUN] Would create new user: $user_name ($user_id:$group_name)"

    if command -v useradd >/dev/null 2>&1; then
        create_user_with_useradd "$user_name" "$user_id" "$group_name"
    elif command -v adduser >/dev/null 2>&1; then
        create_user_with_adduser "$user_name" "$user_id" "$group_name"
    else
        tlog info "[DRY RUN] Would fail: No user creation command found (useradd/adduser)"
    fi
}

update_existing_user() {
    local user_name="$1"
    local user_id="$2"
    local group_name="$3"

    tlog info "[DRY RUN] User $user_name already exists, would attempt to update"

    local old_uid
    old_uid=$(users get-uid "$user_name" 2>/dev/null || echo "")
    tlog info "[DRY RUN] Current UID: ${old_uid:-unknown}"

    if ! command -v usermod >/dev/null 2>&1; then
        tlog info "[DRY RUN] usermod not available, would skip user modification"
        tlog info "[DRY RUN] Would warn about UID mismatch if needed: required $user_id"
        return 0
    fi

    tlog info "[DRY RUN] Would update user with usermod"
    tlog info "[DRY RUN] Command: usermod -u $user_id -g $group_name $user_name"

    if [[ -n "$old_uid" && "$old_uid" != "$user_id" ]]; then
        tlog info "[DRY RUN] Would fix file ownership: UID change from $old_uid to $user_id"
        tlog info "[DRY RUN] Would update ownership in: /home, /opt, /var"
    fi
}

setup_container_user() {
    tlog info "[DRY RUN] Would set up container user: $CONTAINER_USER ($CONTAINER_UID:$CONTAINER_GID)"

    if user_exists "$CONTAINER_USER"; then
        update_existing_user "$CONTAINER_USER" "$CONTAINER_UID" "$CONTAINER_GROUP"
    else
        create_container_user "$CONTAINER_USER" "$CONTAINER_UID" "$CONTAINER_GROUP"
    fi
}

update_file_ownership() {
    local old_uid="$1"

    tlog info "[DRY RUN] Would update file ownership from UID $old_uid to $CONTAINER_UID:$CONTAINER_GID"
    tlog info "[DRY RUN] Would scan directories: /home, /opt, /var"
    tlog info "[DRY RUN] Command: find /home /opt /var -user $old_uid -exec chown $CONTAINER_UID:$CONTAINER_GID {} +"
}

verify_authorities_setup() {
    tlog info "[DRY RUN] Would verify authorities setup:"

    if user_exists "$CONTAINER_USER"; then
        local user_info
        user_info=$(id "$CONTAINER_USER" 2>/dev/null || echo "User info unavailable")
        tlog info "[DRY RUN] ✓ User exists and would be verified: $user_info"
    else
        tlog info "[DRY RUN] ✗ User not found, would report error: $CONTAINER_USER"
    fi

    if group_exists "$CONTAINER_GROUP"; then
        tlog info "[DRY RUN] ✓ Group exists and would be verified: $CONTAINER_GROUP"
    else
        tlog info "[DRY RUN] ✗ Group not found, would report error: $CONTAINER_GROUP"
    fi

    if [[ -d "$CONTAINER_TOOLS" ]]; then
        tlog info "[DRY RUN] ✓ Container-tools directory exists: $CONTAINER_TOOLS"
    else
        tlog info "[DRY RUN] → Container-tools directory not found (optional): $CONTAINER_TOOLS"
    fi

    tlog info "[DRY RUN] Would complete authorities setup verification"
}