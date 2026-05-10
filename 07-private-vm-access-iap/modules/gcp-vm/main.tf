resource "google_compute_instance" "app_vm" {
  name         = "${var.environment}-${var.vm_name}"
  machine_type = var.machine_type
  zone         = var.zone
  tags         = var.tags

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 10
      type  = "pd-balanced"
    }
  }

  network_interface {
    subnetwork = var.subnetwork_self_link
  }

  service_account {
    email  = var.service_account_email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"] # This needs to be parameterized lateron in real project
  }

  metadata = {
    enable-oslogin = tostring(var.enable_oslogin)

  }
  metadata_startup_script = file(var.startup_script_path)

}