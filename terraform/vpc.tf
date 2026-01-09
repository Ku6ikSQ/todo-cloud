resource "yandex_vpc_network" "network-1" {
  name = "${var.project_name}-network"
}

resource "yandex_vpc_subnet" "subnet-1" {
  name           = "${var.project_name}-subnet-1"
  zone           = var.zone
  network_id     = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["10.2.0.0/16"]
}

resource "yandex_vpc_security_group" "sg-1" {
  name       = "${var.project_name}-sg"
  network_id = yandex_vpc_network.network-1.id

  ingress {
    description    = "HTTP"
    port           = 3000
    protocol       = "TCP"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description    = "SSH"
    port           = 22
    protocol       = "TCP"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description    = "PostgreSQL"
    port           = 6432
    protocol       = "TCP"
    v4_cidr_blocks = ["10.2.0.0/16"]
  }

  egress {
    description    = "Internet"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}