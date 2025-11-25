# VPC и подсети

resource "yandex_vpc_network" "main" {
  name = "diplom-net"
}

# NAT-шлюз и таблица маршрутов для приватных подсетей

resource "yandex_vpc_gateway" "nat" {
  name = "diplom-nat-gw"
  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "private_rt" {
  name       = "private-rt"
  network_id = yandex_vpc_network.main.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat.id
  }
}

# Публичная подсеть в ru-central1-a (bastion, zabbix, kibana, ALB)
resource "yandex_vpc_subnet" "public_a" {
  name           = "public-a"
  zone           = var.zone
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["10.0.0.0/24"]
}

# Приватная подсеть в ru-central1-a (web1, elastic)
resource "yandex_vpc_subnet" "private_a" {
  name           = "private-a"
  zone           = var.zone
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["10.0.1.0/24"]
  route_table_id = yandex_vpc_route_table.private_rt.id
}

# Приватная подсеть в ru-central1-b (web2)
resource "yandex_vpc_subnet" "private_b" {
  name           = "private-b"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["10.0.2.0/24"]
  route_table_id = yandex_vpc_route_table.private_rt.id
}

# Security groups

# Bastion — открыт только порт 22 наружу
resource "yandex_vpc_security_group" "bastion_sg" {
  name        = "bastion-sg"
  description = "SSH bastion"
  network_id  = yandex_vpc_network.main.id

  ingress {
    protocol       = "TCP"
    description    = "SSH from Internet"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    description    = "All outgoing"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# Web-серверы — HTTP из внутренней сети + SSH с VPC
resource "yandex_vpc_security_group" "web_sg" {
  name        = "web-sg"
  description = "Web servers"
  network_id  = yandex_vpc_network.main.id

  ingress {
    protocol       = "TCP"
    description    = "HTTP from VPC"
    port           = 80
    v4_cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    protocol       = "TCP"
    description    = "SSH from VPC"
    port           = 22
    v4_cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    protocol       = "ANY"
    description    = "All outgoing"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# Zabbix — web + Zabbix server/agent + SSH
resource "yandex_vpc_security_group" "zabbix_sg" {
  name        = "zabbix-sg"
  description = "Zabbix server/frontend"
  network_id  = yandex_vpc_network.main.id

  ingress {
    protocol       = "TCP"
    description    = "HTTP Zabbix UI"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "Zabbix server"
    port           = 10051
    v4_cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    protocol       = "TCP"
    description    = "Zabbix agent active checks"
    port           = 10050
    v4_cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    protocol       = "TCP"
    description    = "SSH from VPC"
    port           = 22
    v4_cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    protocol       = "ANY"
    description    = "All outgoing"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# Elasticsearch (приватный) + SSH
resource "yandex_vpc_security_group" "elastic_sg" {
  name        = "elastic-sg"
  description = "Elasticsearch node"
  network_id  = yandex_vpc_network.main.id

  ingress {
    protocol       = "TCP"
    description    = "HTTP from internal"
    port           = 9200
    v4_cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    protocol       = "TCP"
    description    = "SSH from VPC"
    port           = 22
    v4_cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    protocol       = "ANY"
    description    = "All outgoing"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# Kibana — UI + SSH
resource "yandex_vpc_security_group" "kibana_sg" {
  name        = "kibana-sg"
  description = "Kibana UI"
  network_id  = yandex_vpc_network.main.id

  ingress {
    protocol       = "TCP"
    description    = "Kibana HTTP"
    port           = 5601
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "SSH from VPC"
    port           = 22
    v4_cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    protocol       = "ANY"
    description    = "All outgoing"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# ALB — принимает HTTP снаружи и healthchecks
resource "yandex_vpc_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Application Load Balancer"
  network_id  = yandex_vpc_network.main.id

  ingress {
    protocol       = "TCP"
    description    = "HTTP from Internet"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol          = "TCP"
    description       = "healthchecks"
    predefined_target = "loadbalancer_healthchecks"
    port              = 30080
  }

  egress {
    protocol       = "ANY"
    description    = "All outgoing"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}
