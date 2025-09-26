#!/bin/bash
# Тестовый init скрипт #2 - имитация миграции БД

echo "=== Init Script #2: Database Migration Simulation ==="

echo "Checking database connection..."
sleep 1
echo "✓ Database connection OK"

echo "Running migrations..."
sleep 2
echo "✓ Migration 001: Create users table"
echo "✓ Migration 002: Add indexes"
echo "✓ Migration 003: Insert default data"

# Создаем лог миграции
mkdir -p /tmp/test-data
echo "Migration completed at $(date)" > /tmp/test-data/migration.log

echo "Database migration completed successfully"