terraform {
  required_version = ">= 1.5.0"

  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.127"
    }
  }

  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "yandex" {
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = var.zone
}

# Сеть, NAT и security groups описаны в network.tf
# Виртуальные машины — в compute.tf
# Балансировщик — в alb.tf
# Снапшоты — в snapshots.tf
