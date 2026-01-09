resource "yandex_iam_service_account" "storage-sa" {
  name        = "${var.project_name}-storage-sa"
  description = "Service account for Object Storage access"
}

resource "yandex_resourcemanager_folder_iam_member" "storage-sa-editor" {
  folder_id = var.folder_id
  role      = "storage.editor"
  member    = "serviceAccount:${yandex_iam_service_account.storage-sa.id}"
}

resource "yandex_iam_service_account_static_access_key" "storage-sa-key" {
  service_account_id = yandex_iam_service_account.storage-sa.id
  description        = "Static access key for Object Storage"
}

resource "yandex_storage_bucket" "static-files" {
  bucket     = var.object_storage_bucket_name
  access_key = yandex_iam_service_account_static_access_key.storage-sa-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.storage-sa-key.secret_key

  # Публичный доступ для чтения (опционально)
  # acl = "public-read"

  # CORS настройки
  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST", "DELETE"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3600
  }
}