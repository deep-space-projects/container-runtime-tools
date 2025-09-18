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

setup_container_group() {
    tlog info "Setting up container group: $CONTAINER_GROUP ($CONTAINER_GID)"
    groups create "$CONTAINER_GROUP" "$CONTAINER_GID"
    return $?
}

setup_container_user() {
    tlog info "Setting up container user: $CONTAINER_USER ($CONTAINER_UID:$CONTAINER_GID)"

    if [[ -n ${IMAGE_USER:+x} ]]; then
        # если был задан предыдущий user контейнера, тогда мы делаем replace
        users replace --update-mode=full $IMAGE_USER $CONTAINER_USER $CONTAINER_UID $CONTAINER_GROUP
        return $?
    else
        # иначе мы создаем нового user контейнера и если он совпадает с существующим, то делаем replace
        users create --on-exist=update --update-mode=full $CONTAINER_USER $CONTAINER_UID $CONTAINER_GROUP
        return $?
    fi
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