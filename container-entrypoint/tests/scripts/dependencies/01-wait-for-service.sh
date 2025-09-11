#!/bin/bash
# Тестовый dependency скрипт - ожидание сервиса

echo "=== Dependency Script: Waiting for External Service ==="

# Имитируем ожидание внешнего сервиса
SERVICE_HOST="${TEST_SERVICE_HOST:-httpbin.org}"
SERVICE_PORT="${TEST_SERVICE_PORT:-80}"

echo "Waiting for service: $SERVICE_HOST:$SERVICE_PORT"

# В реальной ситуации здесь был бы цикл ожидания
# Для теста просто имитируем проверку
for i in {1..3}; do
    echo "Attempt $i: Checking $SERVICE_HOST:$SERVICE_PORT..."
    sleep 1

    # Имитируем успешное подключение на 3-й попытке
    if [[ $i -eq 3 ]]; then
        echo "✓ Service is available!"
        break
    else
        echo "Service not ready, retrying..."
    fi
done

echo "Dependency check completed successfully"