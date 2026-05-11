resource "google_compute_global_address" "lb_ip" {
  name = "${var.environment}-${var.lb_name}-ip"
}

resource "google_compute_backend_service" "backend" {
  name                  = "${var.environment}-${var.lb_name}-backend"
  protocol              = "HTTP"
  port_name             = "http"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  timeout_sec           = 30

  health_checks = [
    var.health_check_self_link
  ]

  backend {
    group           = var.backend_instance_group
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }
}

resource "google_compute_url_map" "url_map" {
  name            = "${var.environment}-${var.lb_name}-url-map"
  default_service = google_compute_backend_service.backend.self_link
}

resource "google_compute_target_http_proxy" "http_proxy" {
  name    = "${var.environment}-${var.lb_name}-http-proxy"
  url_map = google_compute_url_map.url_map.self_link
}

resource "google_compute_global_forwarding_rule" "http_forwarding_rule" {
  name                  = "${var.environment}-${var.lb_name}-http-forwarding-rule"
  ip_address            = google_compute_global_address.lb_ip.address
  ip_protocol           = "TCP"
  port_range            = tostring(var.app_port)
  load_balancing_scheme = "EXTERNAL_MANAGED"
  target                = google_compute_target_http_proxy.http_proxy.self_link
}
