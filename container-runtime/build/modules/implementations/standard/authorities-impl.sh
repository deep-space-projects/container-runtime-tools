#!/bin/bash
# ============================================================================
# Authorities Setup Implementation
# ============================================================================

set -euo pipefail

verify_authorities_variables() {
    # Устанавливаем базовые переменные авторизации только если они не установлены
    if [[ -z "${CONTAINER_USER:-}" ]]; then
        tlog warning "CONTAINER_USER is required"
        return 1
    fi

    if [[ -z "${CONTAINER_UID:-}" ]]; then
        tlog warning "CONTAINER_UID is required"
        return 1
    fi

    if [[ -z "${CONTAINER_GROUP:-}" ]]; then
        tlog warning "CONTAINER_GROUP is required"
        return 1
    fi

    if [[ -z "${CONTAINER_GID:-}" ]]; then
        tlog warning "CONTAINER_GID is required"
        return 1
    fi

    tlog success "Basic authorities variables configured"
}

# Создание группы с помощью groupadd
create_group_with_groupadd() {
    local group_name="$1"
    local group_id="$2"

    tlog debug "Using groupadd to create group"
    if groupadd -g "$group_id" "$group_name"; then
        tlog success "Group created with groupadd: $group_name ($group_id)"
        return 0
    else
        tlog error "Failed to create group with groupadd"
        return 1
    fi
}

# Создание группы с помощью addgroup
create_group_with_addgroup() {
    local group_name="$1"
    local group_id="$2"

    tlog debug "Using addgroup to create group"
    if addgroup -g "$group_id" "$group_name"; then
        tlog success "Group created with addgroup: $group_name ($group_id)"
        return 0
    else
        tlog error "Failed to create group with addgroup"
        return 1
    fi
}

# Основной метод создания группы
create_container_group() {
    local group_name="$1"
    local group_id="$2"

    tlog info "Creating group: $group_name ($group_id)"

    if command -v groupadd >/dev/null 2>&1; then
        create_group_with_groupadd "$group_name" "$group_id"
    elif command -v addgroup >/dev/null 2>&1; then
        create_group_with_addgroup "$group_name" "$group_id"
    else
        tlog error "No group creation command found (groupadd/addgroup)"
        return 1
    fi
}

setup_container_group() {
    tlog info "Setting up container group: $CONTAINER_GROUP ($CONTAINER_GID)"

    if ! groups exists "$CONTAINER_GROUP"; then
        create_container_group "$CONTAINER_GROUP" "$CONTAINER_GID"
    else
        tlog info "Group already exists: $CONTAINER_GROUP"
        return 0
    fi
}

# Создание пользователя с помощью useradd
create_user_with_useradd() {
    local user_name="$1"
    local user_id="$2"
    local group_name="$3"

    tlog debug "Using useradd to create user"

    # Пытаемся создать с домашней директорией и bash
    if useradd -u "$user_id" -g "$group_name" -m -s /bin/bash "$user_name" 2>/dev/null; then
        tlog success "User created with home directory: $user_name"
        return 0
    # Если не получилось, создаем без домашней директории
    elif useradd -u "$user_id" -g "$group_name" "$user_name"; then
        tlog success "User created without home directory: $user_name"
        return 0
    else
        tlog error "Failed to create user with useradd"
        return 1
    fi
}

# Создание пользователя с помощью adduser (BusyBox)
create_user_with_adduser() {
    local user_name="$1"
    local user_id="$2"
    local group_name="$3"

    tlog debug "Using adduser (BusyBox) to create user"
    if adduser -u "$user_id" -G "$group_name" -D -s /bin/bash "$user_name"; then
        tlog success "User created with adduser: $user_name"
        return 0
    else
        tlog error "Failed to create user with adduser"
        return 1
    fi
}

# Основной метод создания пользователя
create_container_user() {
    local user_name="$1"
    local user_id="$2"
    local group_name="$3"

    tlog info "Creating new user: $user_name ($user_id:$group_name)"

    if command -v useradd >/dev/null 2>&1; then
        create_user_with_useradd "$user_name" "$user_id" "$group_name"
    elif command -v adduser >/dev/null 2>&1; then
        create_user_with_adduser "$user_name" "$user_id" "$group_name"
    else
        tlog error "No user creation command found (useradd/adduser)"
        return 1
    fi
}

# Обновление существующего пользователя
update_existing_user() {
    local user_name="$1"
    local user_id="$2"
    local group_name="$3"

    tlog info "User $user_name already exists, attempting to update"

    # Получаем старый UID
    local old_uid
    old_uid=$(users get-uid "$user_name" 2>/dev/null || echo "")

    if ! command -v usermod >/dev/null 2>&1; then
        tlog warning "usermod not available, skipping user modification"
        tlog info "Please ensure user UID matches required: $user_id"
        return 0
    fi

    tlog info "Updating user with usermod"
    if usermod -u "$user_id" -g "$group_name" "$user_name"; then
        tlog success "User updated successfully"

        # Исправляем права на файлы если UID изменился
        if [[ -n "$old_uid" && "$old_uid" != "$user_id" ]]; then
            tlog info "UID changed from $old_uid to $user_id - fixing file ownership"
            update_file_ownership "$old_uid"
        fi
    else
        tlog warning "Failed to update user with usermod, but continuing"
    fi
}

setup_container_user() {
    tlog info "Setting up container user: $CONTAINER_USER ($CONTAINER_UID:$CONTAINER_GID)"

    if users exists "$CONTAINER_USER"; then
        update_existing_user "$CONTAINER_USER" "$CONTAINER_UID" "$CONTAINER_GROUP"
    else
        create_container_user "$CONTAINER_USER" "$CONTAINER_UID" "$CONTAINER_GROUP"
    fi
}

update_file_ownership() {
    local old_uid="$1"

    tlog info "Updating file ownership from UID $old_uid to $CONTAINER_UID:$CONTAINER_GID"

    # Обновляем права в основных директориях
    for dir in /home /opt /var; do
        if [[ -d "$dir" ]]; then
            tlog debug "Checking directory: $dir"
            find "$dir" -user "$old_uid" -exec chown "$CONTAINER_UID:$CONTAINER_GID" {} + 2>/dev/null || true
        fi
    done

    tlog success "File ownership update completed"
}

verify_authorities_setup() {
    tlog info "Verifying authorities setup"

    # Проверяем пользователя
    if users exists "$CONTAINER_USER"; then
        tlog info "✓ User exists: $CONTAINER_USER"
    else
        tlog error "✗ User not found: $CONTAINER_USER"
        return 1
    fi

    # Проверяем группу
    if groups exists "$CONTAINER_GROUP"; then
        tlog info "✓ Group exists: $CONTAINER_GROUP"
    else
        tlog error "✗ Group not found: $CONTAINER_GROUP"
        return 1
    fi

    # Проверяем что пользователь в группе
    if users in-group "$CONTAINER_USER" "$CONTAINER_GROUP"; then
        tlog info "✓ User $CONTAINER_USER is a member of group $CONTAINER_GROUP"
    else
        tlog error "✗ User $CONTAINER_USER is not a member of group $CONTAINER_GROUP"
        return 1
    fi

    tlog success "Authorities setup verification completed"
}