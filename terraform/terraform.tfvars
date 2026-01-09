cloud_id  = "b1g4gsvjs6bvgfsitu74"
folder_id = "b1gk1c6nocmhh7mbsu6v"
zone      = "ru-central1-a"

project_name = "todo-app"

# Docker image from Container Registry (пока placeholder, будет создан позже)
app_image = "cr.yandex/crp2l2c6dnd3m4ufdt95/todo-app:latest"

# PostgreSQL settings
database_user     = "todo_user"
database_password = "12345678"
database_name     = "todo_db"

# VM settings
vm_user = "ubuntu"
vm_ssh_public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO6hY3XkPa3smnWOQRRyKBc7AUjKlGslfJWk7U/ZIJ5k todo-app-vm"

# VM resources
vm_cores     = 2
vm_memory    = 4
vm_disk_size = 20

# Object Storage (имя должно быть уникальным глобально)
object_storage_bucket_name = "todo-app-static-files"  # Или задайте уникальное имя вручную

# Number of VM instances
vm_count = 2