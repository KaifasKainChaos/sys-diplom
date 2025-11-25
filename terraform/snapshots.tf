# Снапшоты всех дисков ВМ, ежедневные, TTL 7 дней

resource "yandex_compute_snapshot_schedule" "daily" {
  name = "daily-snapshots"

  schedule_policy {
    expression = "0 3 * * *"
  }

  snapshot_count = 7

  snapshot_spec {
    description = "Daily snapshots for diploma VMs"
    labels = {
      project = "netology-diplom"
    }
  }

  disk_ids = [
    yandex_compute_instance.bastion.boot_disk[0].disk_id,
    yandex_compute_instance.web1.boot_disk[0].disk_id,
    yandex_compute_instance.web2.boot_disk[0].disk_id,
    yandex_compute_instance.zabbix.boot_disk[0].disk_id,
    yandex_compute_instance.elastic.boot_disk[0].disk_id,
    yandex_compute_instance.kibana.boot_disk[0].disk_id,
  ]
}
