# Todo App - Инструкция по развертыванию

## Предварительные требования

- Node.js (>= 16.x)
- Docker и Docker Compose
- Yandex Cloud CLI (yc)
- Terraform (>= 1.0)

## Быстрое развертывание в Yandex Cloud

### 1. Настройка Yandex Cloud CLI

```bash
# Инициализация
yc init

# Получение токена для Terraform
export YC_TOKEN=$(yc iam create-token)

# Получение Cloud ID и Folder ID
export YC_CLOUD_ID=$(yc config get cloud-id)
export YC_FOLDER_ID=$(yc config get folder-id)
```

### 2. Создание Container Registry

```bash
# Создание registry
yc container registry create --name todo-app-registry

# Получение Registry ID
REGISTRY_ID=$(yc container registry list --format json | jq -r '.[0].id')

# Настройка Docker
yc container registry configure-docker
```

### 3. Подготовка Docker образа

```bash
# Сборка образа
docker build -t todo-app:latest .

# Тегирование
docker tag todo-app:latest cr.yandex/$REGISTRY_ID/todo-app:latest

# Загрузка в Container Registry
docker push cr.yandex/$REGISTRY_ID/todo-app:latest
```

### 4. Настройка Terraform переменных

```bash
cd terraform

# Копирование примера
cp terraform.tfvars.example terraform.tfvars

# Редактирование terraform.tfvars
# Заполните все необходимые переменные:
# - cloud_id
# - folder_id
# - app_image (cr.yandex/$REGISTRY_ID/todo-app:latest)
# - database_password
# - vm_ssh_public_key
# - object_storage_bucket_name (уникальное имя)
```

### 5. Развертывание инфраструктуры

```bash
# Инициализация Terraform
terraform init

# Валидация конфигурации
terraform validate

# Планирование развертывания
terraform plan

# Развертывание (займет 10-15 минут)
terraform apply
```

### 6. Проверка работы

```bash
# Получение IP адреса Load Balancer
LB_IP=$(terraform output -raw load_balancer_ip)

# Проверка healthcheck
curl http://$LB_IP/healthz

# Ожидаемый ответ: {"status":"ok","db":"ok"}
```

## Получение выходных значений

```bash
# Просмотр всех outputs
terraform output

# Основные значения:
# - load_balancer_ip - IP адрес балансировщика нагрузки
# - postgres_host - FQDN PostgreSQL кластера
# - object_storage_bucket - Имя bucket в Object Storage
```

## Очистка ресурсов

```bash
cd terraform
terraform destroy
```

**Внимание:** Это удалит все созданные ресурсы в Yandex Cloud!
