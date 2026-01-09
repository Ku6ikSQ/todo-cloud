resource "yandex_mdb_postgresql_cluster" "postgres-1" {
  name        = "${var.project_name}-postgres"
  environment = "PRODUCTION"
  network_id  = yandex_vpc_network.network-1.id

  config {
    version = 15

    resources {
      resource_preset_id = "s2.micro"
      disk_type_id       = "network-ssd"
      disk_size          = 20
    }

    postgresql_config = {
      max_connections = 100
    }
  }

  host {
    zone      = var.zone
    subnet_id = yandex_vpc_subnet.subnet-1.id
  }
}

resource "yandex_mdb_postgresql_user" "todo_user" {
  cluster_id = yandex_mdb_postgresql_cluster.postgres-1.id
  name       = var.database_user
  password   = var.database_password
}

resource "yandex_mdb_postgresql_database" "todo_db" {
  cluster_id = yandex_mdb_postgresql_cluster.postgres-1.id
  name       = var.database_name
  owner      = yandex_mdb_postgresql_user.todo_user.name
  depends_on = [yandex_mdb_postgresql_user.todo_user]
}