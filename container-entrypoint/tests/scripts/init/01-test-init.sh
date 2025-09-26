#!/bin/bash
# Тестовый init скрипт #1

echo "=== Init Script #1: Basic Setup ==="
echo "Container: $CONTAINER_NAME"
echo "User: $CONTAINER_USER (UID: $CONTAINER_UID)"
echo "Working directory: $(pwd)"
echo "Current user: $(whoami)"

# Создаем тестовые файлы
mkdir -p /tmp/test-data
echo "Init script #1 was here at $(date)" > /tmp/test-data/init1.log

echo "Init script #1 completed successfully"