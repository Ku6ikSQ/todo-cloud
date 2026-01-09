output "external_ip_address_vm" {
  description = "External IP addresses of VM instances"
  value       = yandex_compute_instance.vm[*].network_interface[0].nat_ip_address
}

output "load_balancer_ip" {
  description = "External IP address of Load Balancer"
  value       = yandex_alb_load_balancer.lb-1.listener[0].endpoint[0].address[0].external_ipv4_address[0].address
}

output "postgres_host" {
  description = "PostgreSQL cluster FQDN"
  value       = yandex_mdb_postgresql_cluster.postgres-1.host[0].fqdn
}

output "postgres_port" {
  description = "PostgreSQL port"
  value       = 6432
}

output "object_storage_bucket" {
  description = "Object Storage bucket name"
  value       = yandex_storage_bucket.static-files.bucket
}

output "storage_access_key_id" {
  description = "Object Storage access key ID"
  value       = yandex_iam_service_account_static_access_key.storage-sa-key.access_key
  sensitive   = false
}

output "storage_secret_key" {
  description = "Object Storage secret key"
  value       = yandex_iam_service_account_static_access_key.storage-sa-key.secret_key
  sensitive   = true
}