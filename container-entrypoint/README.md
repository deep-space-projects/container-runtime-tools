# Universal Docker Entrypoint

Не совсем актуально, надо обновить

**Универсальный кроссплатформенный entrypoint для Docker контейнеров с модульной архитектурой и паттерном Strategy**

## 🎯 Что это такое?

Universal Docker Entrypoint — это готовое решение для инициализации Docker контейнеров, которое решает типичные проблемы:

- ✅ **Безопасное переключение пользователей** — от root к app user
- ✅ **Гибкая инициализация** — пользовательские скрипты и зависимости
- ✅ **Кроссплатформенность** — Alpine, Ubuntu, CentOS, и другие
- ✅ **Надежная обработка ошибок** — различные политики и режимы отладки
- ✅ **Простая интеграция** — добавляется в любой проект за 5 минут

## 🚀 Быстрый старт

### 1. Добавьте в Dockerfile

```dockerfile
# Минимальный тест Universal Docker Entrypoint
FROM alpine:3.19

# Устанавливаем bash (обязательно!)

# Используем текущего пользователя для тестов
ARG CURRENT_USER_ID=1000
ARG CURRENT_GROUP_ID=10000

USER root

# Настраиваем базовые переменные окружения
ENV CONTAINER_TOOLS=/opt/container-tools \
    CONTAINER_NAME=test-minimal \
    CONTAINER_USER=testuser \
    CONTAINER_UID=${CURRENT_USER_ID} \
    CONTAINER_GID=${CURRENT_GROUP_ID} \
    CONTAINER_GROUP=testgroup \
    CONTAINER_TEMP=/tmp/test-minimal \
    CONTAINER_ENTRYPOINT_SCRIPTS=/tmp/test-minimal/init \
    CONTAINER_ENTRYPOINT_CONFIGS=/tmp/test-minimal/config \
    CONTAINER_ENTRYPOINT_DEPENDENCIES=/tmp/test-minimal/dependencies

# Настраиваем пользователя и права
RUN apk add --no-cache bash yq \
    && REPO="deep-space-projects/shell-dev-tools" BRANCH="main" BUILD_DIR="build" && wget -qO $BRANCH.zip  https://github.com/$REPO/archive/refs/heads/$BRANCH.zip  && unzip -q $BRANCH.zip -d $BUILD_DIR && bash $BUILD_DIR/shell-dev-tools-$BRANCH/functions-manager/bin/build.sh --privileged --daemon && rm -rf $BUILD_DIR && rm -f $BRANCH.zip && fman install --system --daemon \
    && fman install --github --repo=deep-space-projects/container-dev-tools --branch=master \
    && cent build

# Устанавливаем entrypoint
ENTRYPOINT ["cent", "start"]
# Простая команда для тестирования
CMD ["echo", "Hello from Universal Entrypoint!"]
```


### 2. Запустите контейнер

```shell script
# Обычный запуск
docker run my-app

# Посмотрите план выполнения (DRY RUN)
docker run -e EXEC_MODE=4 my-app

# Только инициализация (для тестирования)
docker run -e EXEC_MODE=2 my-app
```


### 3. Добавьте пользовательские скрипты (опционально)

```dockerfile
# Скрипты инициализации
COPY init-scripts/ /tmp/my-app/init/

# Скрипты ожидания зависимостей  
COPY dependency-scripts/ /tmp/my-app/dependencies/
```


## 📋 Основные возможности

### Режимы выполнения

| Режим | Команда | Описание | Когда использовать |
|-------|---------|----------|-------------------|
| **STANDARD** | `EXEC_MODE=0` | Полная инициализация + запуск | Продакшен |
| **SKIP_ALL** | `EXEC_MODE=1` | Пропустить инициализацию | Экстренные случаи |
| **INIT_ONLY** | `EXEC_MODE=2` | Только инициализация | Тестирование setup |
| **DEBUG** | `EXEC_MODE=3` | Детальные логи | Отладка проблем |
| **DRY_RUN** | `EXEC_MODE=4` | План без выполнения | Проверка конфигурации |

### Политики обработки ошибок

```shell script
# Строгая - любая ошибка останавливает выполнение (по умолчанию)
docker run -e EXEC_ERROR_POLICY=0 my-app

# Мягкая - логируем ошибки и продолжаем
docker run -e EXEC_ERROR_POLICY=1 my-app
```


### Автоматическая настройка прав доступа

- **Безопасность по умолчанию**: права 700/600 для пользовательских данных
- **Исполняемые скрипты**: автоматически делает .sh файлы исполняемыми
- **Изоляция**: каждый контейнер использует свою подпапку в /tmp

## 📁 Структура проекта

```
container-tools/
├── build/                          # Скрипты сборки
│   └── setup-container-user.sh     # Настройка пользователя
├── core/                           # Базовые библиотеки
│   ├── logger.sh                   # Система логирования
│   ├── common.sh                   # Общие функции
│   ├── platform.sh                 # Кроссплатформенные команды
│   ├── permissions.sh              # Управление правами
│   └── process.sh                  # Управление процессами
├── entrypoint/                     # Главный entrypoint
│   ├── universal-entrypoint.sh     # Оркестратор
│   ├── modules/                    # Модули инициализации
│   │   ├── 00-environment.sh       # Проверка окружения
│   │   ├── 10-permissions.sh       # Настройка прав
│   │   ├── 20-logging.sh           # Настройка логирования
│   │   ├── 30-init-scripts.sh      # Пользовательские скрипты
│   │   ├── 40-dependencies.sh      # Ожидание зависимостей
│   │   └── 99-exec-command.sh      # Запуск приложения
│   └── implementations/            # Strategy Pattern
│       ├── standard/               # Реальное выполнение
│       └── dry_run/               # Симуляция
└── README.md
```


## 🛠 Пользовательские скрипты

### Скрипты инициализации

Поместите .sh файлы в `/tmp/{CONTAINER_NAME}/init/`:

```shell script
# 01-database-migration.sh
#!/bin/bash
echo "Выполняем миграции базы данных..."
python manage.py migrate
echo "Миграции завершены"

# 02-cache-warmup.sh  
#!/bin/bash
echo "Прогреваем кеш..."
curl -s http://localhost:8000/warmup
echo "Кеш прогрет"
```


### Скрипты ожидания зависимостей

Поместите .sh файлы в `/tmp/{CONTAINER_NAME}/dependencies/`:

```shell script
# 01-wait-for-postgres.sh
#!/bin/bash
echo "Ожидаем PostgreSQL..."
while ! nc -z postgres 5432; do
    echo "База данных не готова, ждем..."
    sleep 2
done
echo "PostgreSQL готов!"
```


**Важно**: Все dependency скрипты выполняются под общим таймаутом `DEPENDENCY_TIMEOUT` (по умолчанию 300 сек).

## ⚙️ Конфигурация

### Обязательные переменные

```dockerfile
ENV CONTAINER_TOOLS=/opt/container-tools \
    CONTAINER_NAME=my-app \
    CONTAINER_USER=appuser \
    CONTAINER_UID=1000 \
    CONTAINER_GID=1000
```


### Опциональные переменные

```dockerfile
ENV CONTAINER_GROUP=appgroup \
    EXEC_MODE=0 \
    EXEC_ERROR_POLICY=0 \
    DEPENDENCY_TIMEOUT=300 \
    LOG_LEVEL=INFO
```


### Автоматически создаваемые пути

```dockerfile
ENV CONTAINER_TEMP=/tmp/${CONTAINER_NAME} \
    CONTAINER_ENTRYPOINT_SCRIPTS=/tmp/${CONTAINER_NAME}/init \
    CONTAINER_ENTRYPOINT_CONFIGS=/tmp/${CONTAINER_NAME}/config \
    CONTAINER_ENTRYPOINT_DEPENDENCIES=/tmp/${CONTAINER_NAME}/dependencies
```


## 🔧 Примеры использования

### Веб-приложение с базой данных

```dockerfile
FROM python:3.11-alpine

RUN apk add --no-cache bash netcat-openbsd

ENV CONTAINER_TOOLS=/opt/container-tools \
    CONTAINER_USER=webapp \
    CONTAINER_UID=1000 \
    CONTAINER_GID=1000 \
    CONTAINER_NAME=my-webapp

COPY container-tools/ ${CONTAINER_TOOLS}/
COPY wait-for-db.sh /tmp/my-webapp/dependencies/
COPY migrate.sh /tmp/my-webapp/init/

RUN ${CONTAINER_TOOLS}/build/setup-container-user.sh \
    webapp 1000 webapp 1000

ENTRYPOINT ["bash", "/opt/container-tools/entrypoint/universal-entrypoint.sh"]
CMD ["python", "app.py"]
```


### Микросервис с несколькими зависимостями

```dockerfile
FROM alpine:3.19

RUN apk add --no-cache bash curl netcat-openbsd

ENV CONTAINER_TOOLS=/opt/container-tools \
    CONTAINER_USER=microservice \
    CONTAINER_UID=2000 \
    CONTAINER_GID=2000 \
    CONTAINER_NAME=auth-service \
    DEPENDENCY_TIMEOUT=120

COPY container-tools/ ${CONTAINER_TOOLS}/
COPY dependencies/ /tmp/auth-service/dependencies/
COPY init/ /tmp/auth-service/init/

RUN ${CONTAINER_TOOLS}/build/setup-container-user.sh \
    microservice 2000 microservice 2000

ENTRYPOINT ["bash", "/opt/container-tools/entrypoint/universal-entrypoint.sh"]
CMD ["./auth-service", "--config", "prod.conf"]
```


## 🚨 Решение проблем

### Bash не найден
```
❌ ERROR: bash is required but not found

Решение:
Alpine:        RUN apk add --no-cache bash
Debian/Ubuntu: RUN apt-get update && apt-get install -y bash
RHEL/CentOS:   RUN yum install -y bash
```


### Пользователь не существует
```
❌ ERROR: Target user does not exist: appuser

Решение:
Убедитесь что выполняется setup-container-user.sh:
RUN ${CONTAINER_TOOLS}/build/setup-container-user.sh \
    ${CONTAINER_USER} ${CONTAINER_UID} ${CONTAINER_GROUP} ${CONTAINER_GID}
```


### Проблемы с правами доступа
```
❌ ERROR: Failed to set owner 'appuser:appgroup' on '/var/log/myapp'

Проверьте:
1. Контейнер запускается под root для инициализации
2. Пользователь и группа созданы корректно
3. setup-container-user.sh был выполнен при сборке
```


### Таймаут зависимостей
```
❌ ERROR: Dependencies terminated due to timeout (300s)

Решения:
1. Увеличьте таймаут: ENV DEPENDENCY_TIMEOUT=600
2. Проверьте логику скриптов: docker run -e EXEC_MODE=4 my-app
3. Используйте мягкую политику: ENV EXEC_ERROR_POLICY=1
```


## 🧪 Тестирование и отладка

### Посмотреть план выполнения
```shell script
docker run -e EXEC_MODE=4 my-app
```


Выведет:
```
[DRY RUN] Would detect operating system using cmn os detect()
[DRY RUN] Would check required commands: id, whoami, chmod, chown
[DRY RUN] Would create directory: /var/log/my-app
[DRY RUN] Found 2 init scripts: 01-migrate.sh, 02-warmup.sh
[DRY RUN] Would execute final command: python app.py
```


### Детальная отладка
```shell script
docker run -e EXEC_MODE=3 -e LOG_LEVEL=DEBUG my-app
```


### Тестирование инициализации
```shell script
# Только инициализация, без запуска приложения
docker run -e EXEC_MODE=2 my-app

# Пропустить инициализацию (экстренный режим)
docker run -e EXEC_MODE=1 my-app
```


### Мягкая обработка ошибок для разработки
```shell script
docker run -e EXEC_ERROR_POLICY=1 my-app
```


## 📊 Типичные сценарии

### Продакшен
```shell script
# Строгий режим, полная инициализация
docker run \
    -e EXEC_MODE=0 \
    -e EXEC_ERROR_POLICY=0 \
    -e DEPENDENCY_TIMEOUT=300 \
    my-app
```


### Разработка
```shell script
# Отладка с мягкими ошибками
docker run \
    -e EXEC_MODE=3 \
    -e EXEC_ERROR_POLICY=1 \
    -e LOG_LEVEL=DEBUG \
    my-app
```


### CI/CD pipeline
```shell script
# Тестирование инициализации
docker run -e EXEC_MODE=2 my-app

# Проверка конфигурации  
docker run -e EXEC_MODE=4 my-app
```


### Экстренное восстановление
```shell script
# Обход всей инициализации
docker run -e EXEC_MODE=1 my-app
```


## 🔒 Безопасность

### Принципы
- **Минимальные права**: 700/600 для пользовательских данных
- **Изоляция**: каждый контейнер в своей подпапке
- **Переключение пользователей**: root → app user
- **Валидация**: проверка всех UID/GID

### Структура прав
```
/var/log/my-app/         700 appuser:appgroup  # Логи
/tmp/my-app/            700 appuser:appgroup  # Временные файлы
/tmp/my-app/init/       700 appuser:appgroup  # Init скрипты (executable)
/opt/container-tools/   750 appuser:appgroup  # Системные инструменты
```


## 🤝 Поддержка

### Совместимость
- **ОС**: Alpine Linux, Debian, Ubuntu, RHEL, CentOS, Rocky Linux, Alma Linux
- **Архитектуры**: x86_64, ARM64
- **Docker**: 20.10+, Docker Compose 2.0+
- **Kubernetes**: Поддерживается (стандартные контейнеры)

### Лицензия
MIT License - используйте свободно в коммерческих проектах.

---

**Universal Docker Entrypoint** — надежное решение для профессиональной контейнеризации! 🚀

*Начните использовать прямо сейчас — копируйте container-tools в ваш проект и настройте за 5 минут.*