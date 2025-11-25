# Application Load Balancer для веб-серверов

resource "yandex_alb_target_group" "web_tg" {
  name = "web-tg"

  target {
    ip_address = yandex_compute_instance.web1.network_interface[0].ip_address
    subnet_id  = yandex_vpc_subnet.private_a.id
  }

  target {
    ip_address = yandex_compute_instance.web2.network_interface[0].ip_address
    subnet_id  = yandex_vpc_subnet.private_b.id
  }
}

resource "yandex_alb_backend_group" "web_bg" {
  name = "web-bg"

  http_backend {
    name             = "web-http-backend"
    port             = 80
    weight           = 1
    target_group_ids = [yandex_alb_target_group.web_tg.id]

    healthcheck {
      timeout  = "1s"
      interval = "3s"
      healthy_threshold   = 4
      unhealthy_threshold = 3

      http_healthcheck {
        path = "/"
      }
    }
  }
}

resource "yandex_alb_http_router" "web_router" {
  name = "web-router"
}

resource "yandex_alb_virtual_host" "web_vhost" {
  name           = "web-vhost"
  http_router_id = yandex_alb_http_router.web_router.id

  route {
    name = "web-route"

    http_route {
      http_route_action {
        backend_group_id = yandex_alb_backend_group.web_bg.id
      }
    }
  }
}

resource "yandex_alb_load_balancer" "web_alb" {
  name       = "web-alb"
  network_id = yandex_vpc_network.main.id

  allocation_policy {
    location {
      zone_id   = var.zone
      subnet_id = yandex_vpc_subnet.public_a.id
    }
  }

  listener {
    name = "http-listener"

    endpoint {
      address {
        external_ipv4_address {}
      }

      ports = [80]
    }

    http {
      handler {
        http_router_id = yandex_alb_http_router.web_router.id
      }
    }
  }

  security_group_ids = [yandex_vpc_security_group.alb_sg.id]
}
