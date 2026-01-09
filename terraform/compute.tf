data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-2204-lts"
}

resource "yandex_compute_instance" "vm" {
  count       = var.vm_count
  name        = "${var.project_name}-vm-${count.index + 1}"
  platform_id = "standard-v2"
  zone        = var.zone

  resources {
    cores  = var.vm_cores
    memory = var.vm_memory
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = var.vm_disk_size
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.subnet-1.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.sg-1.id]
  }

  service_account_id = yandex_iam_service_account.vm-sa.id

  metadata = {
    user-data = <<-EOF
      #cloud-config
      users:
        - name: ${var.vm_user}
          groups: sudo
          shell: /bin/bash
          sudo: ['ALL=(ALL) NOPASSWD:ALL']
          ssh-authorized-keys:
            - ${var.vm_ssh_public_key}
      
      write_files:
        - path: /etc/docker/daemon.json
          content: |
            {
              "log-driver": "json-file",
              "log-opts": {
                "max-size": "10m",
                "max-file": "3"
              }
            }
        - path: /tmp/init_db.sql
          content: |
            CREATE TABLE IF NOT EXISTS users (
            id SERIAL PRIMARY KEY,
            name VARCHAR(255) NOT NULL,
            login VARCHAR(100) NOT NULL UNIQUE,
            email VARCHAR(255) NOT NULL UNIQUE,
            avatar VARCHAR(1024),
            created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT (now())
            );

            CREATE TABLE IF NOT EXISTS tasks (
            id SERIAL PRIMARY KEY,
            user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
            title VARCHAR(255) NOT NULL,
            description TEXT,
            is_completed BOOLEAN DEFAULT FALSE,
            created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT (now())
            );

            CREATE INDEX IF NOT EXISTS idx_tasks_user_id ON tasks(user_id);
      
      runcmd:
        - apt-get update
        - apt-get install -y docker.io docker-compose jq postgresql-client
        - systemctl enable docker
        - systemctl start docker
        - usermod -aG docker ${var.vm_user}
        - |
          # Настройка аутентификации Docker для Yandex Container Registry через IAM токен
          export HOME=/root
          TOKEN=$(curl -s -H "Metadata-Flavor: Google" "http://169.254.169.254/computeMetadata/v1/instance/service-accounts/default/token" | jq -r '.access_token')
          echo "$TOKEN" | docker login cr.yandex -u "iam" --password-stdin
        - |
          # Ожидание готовности PostgreSQL
          sleep 90
        - |
          # Инициализация схемы базы данных (только на первой VM, чтобы не создавать таблицы дважды)
          VM_INDEX="${count.index}"
          if [ "$VM_INDEX" = "0" ]; then
            echo "Initializing database schema on VM-1..."
            # Проверка готовности PostgreSQL
            for i in {1..30}; do
              if PGPASSWORD='${var.database_password}' psql -h ${yandex_mdb_postgresql_cluster.postgres-1.host[0].fqdn} -p 6432 -U ${var.database_user} -d ${var.database_name} -c "SELECT 1;" > /dev/null 2>&1; then
                echo "PostgreSQL is ready"
                break
              fi
              echo "Waiting for PostgreSQL... ($i/30)"
              sleep 5
            done
            # Выполнение SQL скрипта
            PGPASSWORD='${var.database_password}' psql \
              -h ${yandex_mdb_postgresql_cluster.postgres-1.host[0].fqdn} \
              -p 6432 \
              -U ${var.database_user} \
              -d ${var.database_name} \
              -f /tmp/init_db.sql \
              || echo "Database schema might already be initialized"
            echo "Database schema initialization completed"
          fi
        - |
          # Запуск Docker контейнера
          docker run -d \
            --name todo-app \
            --restart unless-stopped \
            -p 3000:3000 \
            -e DATABASE_URL="postgresql://${var.database_user}:${var.database_password}@${yandex_mdb_postgresql_cluster.postgres-1.host[0].fqdn}:6432/${var.database_name}" \
            -e YANDEX_ACCESS_KEY_ID="${yandex_iam_service_account_static_access_key.storage-sa-key.access_key}" \
            -e YANDEX_SECRET_ACCESS_KEY="${yandex_iam_service_account_static_access_key.storage-sa-key.secret_key}" \
            -e YANDEX_OBJECT_STORAGE_BUCKET="${yandex_storage_bucket.static-files.bucket}" \
            -e YANDEX_OBJECT_STORAGE_ENDPOINT="https://storage.yandexcloud.net" \
            -e NODE_ENV=production \
            -e PORT=3000 \
            ${var.app_image}
    EOF
  }
}