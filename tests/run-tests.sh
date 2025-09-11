#!/bin/bash
# Скрипт запуска всех тестов Universal Docker Entrypoint

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_DIR="$SCRIPT_DIR/docker"

cd "$DOCKER_DIR"

# Получаем ID текущего пользователя и группы
CURRENT_USER_ID=$(id -u)
CURRENT_GROUP_ID=10000 #$(id -g)

# Получаем метаданные для сборки
BUILD_DATE=$(date -Iseconds)
GIT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
BUILD_NUMBER=${BUILD_NUMBER:-local}

echo "🧪 Universal Docker Entrypoint Test Suite"
echo "=========================================="
echo "Using current user: UID=$CURRENT_USER_ID, GID=$CURRENT_GROUP_ID"
echo "Build metadata:"
echo "  Build Date: $BUILD_DATE"
echo "  Git Commit: $GIT_COMMIT"
echo "  Git Branch: $GIT_BRANCH"
echo "  Build Number: $BUILD_NUMBER"
echo ""

# Экспортируем для docker compose
export CURRENT_USER_ID
export CURRENT_GROUP_ID
export BUILD_DATE
export GIT_COMMIT
export GIT_BRANCH
export BUILD_NUMBER

# Функция запуска теста
# Функция запуска теста
run_test() {
    local profile="$1"
    local description="$2"
    local test_result=0

    echo "🔍 Running test: $description"
    echo "Profile: $profile"
    echo ""

    if docker compose --profile "$profile" up --build --remove-orphans; then
        echo "✅ Test PASSED: $description"
        test_result=0
    else
        echo "❌ Test FAILED: $description"
        test_result=1
    fi

    echo ""
    echo "🧹 Cleaning up..."
    docker compose --profile "$profile" down --remove-orphans --volumes
    echo ""
    echo "----------------------------------------"
    echo ""

    return $test_result
}

# Функция показа метаданных образа
show_image_metadata() {
    local profile="$1"
    local image_name="docker-$profile"

    echo "📋 Image metadata for $profile:"
    docker inspect "$image_name" --format '{{json .Config.Labels}}' | jq -r '
        to_entries[] |
        select(.key | startswith("org.opencontainers.image") or startswith("org.label-schema") or . == "test.type") |
        "\(.key): \(.value)"
    ' 2>/dev/null || echo "  No metadata available"
    echo ""
}

# Массив тестов: профиль, описание
declare -a TESTS=(
    "dry-run|DRY RUN Mode - Show execution plan"
    "standard|Standard Mode - Minimal setup"
    "skip-all|SKIP ALL Mode - Direct command execution"
    "init-only|INIT ONLY Mode - Initialization without command"
    "full|Full Mode - With init scripts and dependencies"
    "soft-errors|Soft Error Policy - Continue on errors"
    "timeout-test|Dependencies timeout - Stop on timeout"
)

# Счетчики
TOTAL_TESTS=${#TESTS[@]}
PASSED_TESTS=0
FAILED_TESTS=0

echo "🚀 Starting $TOTAL_TESTS tests..."
echo ""

# Запускаем все тесты
for test_spec in "${TESTS[@]}"; do
    IFS='|' read -r profile description <<< "$test_spec"

    if run_test "$profile" "$description"; then
        ((PASSED_TESTS++))

        # Показываем метаданные для успешных тестов
        show_image_metadata "$profile"
    else
        ((FAILED_TESTS++))
        echo "⚠️  Continuing with remaining tests..."
        echo ""
    fi
done

# Итоговый отчет
echo "📊 TEST SUMMARY"
echo "==============="
echo "Total tests:  $TOTAL_TESTS"
echo "Passed:       $PASSED_TESTS"
echo "Failed:       $FAILED_TESTS"
echo ""

if [[ $FAILED_TESTS -eq 0 ]]; then
    echo "🎉 All tests PASSED!"
    exit 0
else
    echo "💥 Some tests FAILED!"
    exit 1
fi