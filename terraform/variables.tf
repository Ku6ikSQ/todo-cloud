variable "cloud_id" {
  description = "Yandex Cloud ID"
  type        = string
}

variable "folder_id" {
  description = "Yandex Cloud Folder ID"
  type        = string
}

variable "zone" {
  description = "Availability zone"
  type        = string
  default     = "ru-central1-a"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "todo-app"
}

variable "app_image" {
  description = "Docker image path in Container Registry"
  type        = string
}

variable "database_user" {
  description = "PostgreSQL database user"
  type        = string
  default     = "todo_user"
}

variable "database_password" {
  description = "PostgreSQL database password"
  type        = string
  sensitive   = true
}

variable "database_name" {
  description = "PostgreSQL database name"
  type        = string
  default     = "todo_db"
}

variable "vm_user" {
  description = "VM user for SSH access"
  type        = string
  default     = "ubuntu"
}

variable "vm_ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
}

variable "vm_cores" {
  description = "Number of CPU cores for VM"
  type        = number
  default     = 2
}

variable "vm_memory" {
  description = "VM memory in GB"
  type        = number
  default     = 4
}

variable "vm_disk_size" {
  description = "VM disk size in GB"
  type        = number
  default     = 20
}

variable "object_storage_bucket_name" {
  description = "Object Storage bucket name (must be globally unique)"
  type        = string
}

variable "vm_count" {
  description = "Number of VM instances"
  type        = number
  default     = 2
}