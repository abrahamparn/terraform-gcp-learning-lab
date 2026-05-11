resource "google_compute_instance_template" "template" {
  name_prefix  = "${var.environment}-${var.mig_name}-template-"
  machine_type = var.machine_type
  tags         = var.tags

  disk {
    source_image = "debian-cloud/debian-12"
    auto_delete  = true
    boot         = true
    disk_size_gb = 10
    disk_type    = "pd-balanced"
  }

  network_interface {
    subnetwork = var.subnetwork_self_link
  }

  metadata_startup_script = file(var.startup_script_path)

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_region_instance_group_manager" "mig" {
  name               = "${var.environment}-${var.mig_name}"
  region             = var.region
  base_instance_name = "${var.environment}-${var.mig_name}"
  target_size        = var.target_size
  version {
    instance_template = google_compute_instance_template.template.self_link

  }

  named_port {
    name = "http"

    port = var.app_port
  }

  distribution_policy_zones = [var.zone]

  auto_healing_policies {
    health_check      = var.health_check_self_link
    initial_delay_sec = 120
  }

}
