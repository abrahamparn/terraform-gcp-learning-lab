resource "google_compute_instance" "app_vm" {
  name         = "${var.environment}-${var.vm_name}"
  machine_type = var.vm_machine_type
  zone         = var.vm_zone
  tags         = var.vm_tags

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 10
      type  = "pd-balanced"
    }
  }

  network_interface {
    subnetwork = var.subnet_self_link
  }

  metadata_startup_script = var.startup_script
}
