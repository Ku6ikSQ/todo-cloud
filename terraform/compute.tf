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
      
      runcmd:
        - apt-get update
        - apt-get install -y docker.io docker-compose
        - systemctl enable docker
        - systemctl start docker
        - usermod -aG docker ${var.vm_user}
        - |
          # Установка yc CLI для аутентификации в Container Registry
          curl -sSL https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash
          /root/yandex-cloud/bin/yc container registry configure-docker || true
        - |
          # Ожидание готовности PostgreSQL
          sleep 60
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