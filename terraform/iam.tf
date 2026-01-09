resource "yandex_iam_service_account" "vm-sa" {
  name        = "${var.project_name}-vm-sa"
  description = "Service account for VM instances"
}

resource "yandex_resourcemanager_folder_iam_member" "vm-sa-editor" {
  folder_id = var.folder_id
  role      = "editor"
  member    = "serviceAccount:${yandex_iam_service_account.vm-sa.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "vm-sa-container-registry-puller" {
  folder_id = var.folder_id
  role      = "container-registry.images.puller"
  member    = "serviceAccount:${yandex_iam_service_account.vm-sa.id}"
}