resource "yandex_alb_target_group" "tg-1" {
  name = "${var.project_name}-tg"

  dynamic "target" {
    for_each = yandex_compute_instance.vm
    content {
      subnet_id  = yandex_vpc_subnet.subnet-1.id
      ip_address = target.value.network_interface[0].ip_address
    }
  }
}

resource "yandex_alb_backend_group" "bg-1" {
  name = "${var.project_name}-bg"

  http_backend {
    name             = "http-backend"
    weight           = 1
    port             = 3000
    target_group_ids = [yandex_alb_target_group.tg-1.id]

    healthcheck {
      timeout              = "10s"
      interval             = "2s"
      healthy_threshold    = 2
      unhealthy_threshold  = 3
      http_healthcheck {
        path = "/healthz"
      }
    }
  }
}

resource "yandex_alb_http_router" "router-1" {
  name = "${var.project_name}-router"
}

resource "yandex_alb_virtual_host" "vh-1" {
  name           = "${var.project_name}-vh"
  http_router_id = yandex_alb_http_router.router-1.id

  route {
    name = "default"
    http_route {
      http_route_action {
        backend_group_id = yandex_alb_backend_group.bg-1.id
      }
    }
  }
}

resource "yandex_alb_load_balancer" "lb-1" {
  name        = "${var.project_name}-lb"
  network_id  = yandex_vpc_network.network-1.id

  allocation_policy {
    location {
      zone_id   = var.zone
      subnet_id = yandex_vpc_subnet.subnet-1.id
    }
  }

  listener {
    name = "listener-1"
    endpoint {
      address {
        external_ipv4_address {
        }
      }
      ports = [80]
    }
    http {
      handler {
        http_router_id = yandex_alb_http_router.router-1.id
      }
    }
  }
}