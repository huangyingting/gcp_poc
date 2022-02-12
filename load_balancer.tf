resource "google_compute_address" "web_nlb" {
  provider     = google-beta
  name         = "ip-web-nlb"
  region       = var.region1
  network_tier = "STANDARD"
}

resource "google_compute_address" "web_proxy" {
  provider     = google-beta
  name         = "ip-web-proxy"
  region       = var.region1
  network_tier = "STANDARD"
}

resource "google_compute_region_health_check" "web_http" {
  region             = var.region1
  name               = "rhc-web-http"
  check_interval_sec = 30
  timeout_sec        = 15
  http_health_check {
    port_specification = "USE_SERVING_PORT"
  }
}

# Regional network load balancer
resource "google_compute_region_backend_service" "web_nlb" {
  region                = var.region1
  name                  = "rbs-web-nlb"
  protocol              = "TCP"
  load_balancing_scheme = "EXTERNAL"
  backend {
    group          = google_compute_region_instance_group_manager.web.instance_group
    balancing_mode = "CONNECTION"
  }
  timeout_sec                     = 10
  session_affinity                = "CLIENT_IP"
  connection_draining_timeout_sec = 10
  health_checks                   = [google_compute_region_health_check.web_http.id]
}

resource "google_compute_forwarding_rule" "web_nlb" {
  provider        = google-beta
  name            = "fr-web-nlb"
  region          = var.region1
  port_range      = 80
  backend_service = google_compute_region_backend_service.web_nlb.id
  ip_address      = google_compute_address.web_nlb.id
  network_tier    = "STANDARD"
}

# Regional HTTPS load balancer
resource "google_compute_region_backend_service" "web_proxy" {
  provider              = google-beta
  region                = var.region1
  name                  = "rbs-web-proxy"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  backend {
    group                 = google_compute_region_instance_group_manager.web.instance_group
    balancing_mode        = "RATE"
    max_rate_per_instance = 100
    capacity_scaler       = 1.0
  }
  protocol      = "HTTP"
  timeout_sec   = 10
  health_checks = [google_compute_region_health_check.web_http.id]
}

resource "google_compute_region_ssl_certificate" "web_proxy" {
  provider    = google-beta
  region      = var.region1
  name_prefix = "rsc-web-proxy"
  private_key = acme_certificate.ssl.private_key_pem
  certificate = "${acme_certificate.ssl.certificate_pem}${acme_certificate.ssl.issuer_pem}"
  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_region_url_map" "web_proxy" {
  provider        = google-beta
  name            = "rum-web-proxy"
  region          = var.region1
  default_service = google_compute_region_backend_service.web_proxy.id
  host_rule {
    hosts        = ["proxy.${var.domain_name}"]
    path_matcher = "allpaths"
  }
  path_matcher {
    name            = "allpaths"
    default_service = google_compute_region_backend_service.web_proxy.id
  }
}

resource "google_compute_region_target_https_proxy" "web_proxy" {
  provider         = google-beta
  name             = "rthps-web-proxy"
  region           = var.region1
  url_map          = google_compute_region_url_map.web_proxy.id
  ssl_certificates = [google_compute_region_ssl_certificate.web_proxy.id]
}

# Regional forwarding rule
resource "google_compute_forwarding_rule" "web_proxy" {
  provider              = google-beta
  name                  = "fr-web-proxy"
  region                = var.region1
  ip_protocol           = "TCP"
  ip_address            = google_compute_address.web_proxy.id
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "443"
  target                = google_compute_region_target_https_proxy.web_proxy.id
  network               = google_compute_network.poc.id
  network_tier          = "STANDARD"
  depends_on            = [google_compute_subnetwork.proxy]
}

# Http to https redirect
resource "google_compute_region_url_map" "redirect" {
  provider        = google-beta
  name            = "rum-redirect"
  region          = var.region1
  default_service = google_compute_region_backend_service.web_proxy.id
  host_rule {
    hosts        = ["*"]
    path_matcher = "allpaths"
  }
  path_matcher {
    name            = "allpaths"
    default_service = google_compute_region_backend_service.web_proxy.id
    path_rule {
      paths = ["/*"]
      url_redirect {
        https_redirect         = true
        host_redirect          = "proxy.${var.domain_name}:443"        
        redirect_response_code = "PERMANENT_REDIRECT"
        strip_query            = true
      }
    }
  }
}

resource "google_compute_region_target_http_proxy" "redirect" {
  provider = google-beta
  name     = "rthp-redirect"
  region   = var.region1
  url_map  = google_compute_region_url_map.redirect.id
}

resource "google_compute_forwarding_rule" "redirect" {
  provider              = google-beta
  name                  = "fr-redirect"
  region                = var.region1
  ip_protocol           = "TCP"
  ip_address            = google_compute_address.web_proxy.id
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "80"
  target                = google_compute_region_target_http_proxy.redirect.id
  network               = google_compute_network.poc.id
  network_tier          = "STANDARD"
  depends_on            = [google_compute_subnetwork.proxy]
}