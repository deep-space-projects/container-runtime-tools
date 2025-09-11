#!/bin/bash
# Медленный dependency скрипт для тестирования таймаута

echo "=== Slow Dependency Script: Testing Timeout ==="

SERVICE_NAME="${TEST_SLOW_SERVICE:-slow-external-service}"
WAIT_TIME="${WAIT_TIME:-15}"  # По умолчанию 15 секунд

echo "Simulating slow dependency check for: $SERVICE_NAME"
echo "This will take $WAIT_TIME seconds..."

for i in $(seq 1 $WAIT_TIME); do
    echo "Attempt $i/$WAIT_TIME: Still checking $SERVICE_NAME..."
    sleep 1

    # Показываем прогресс каждые 5 секунд
    if (( i % 5 == 0 )); then
        echo "Progress: $i/$WAIT_TIME seconds elapsed"
    fi
done

echo "✓ Slow dependency check completed after $WAIT_TIME seconds"
echo "This message should NOT appear if timeout works correctly"