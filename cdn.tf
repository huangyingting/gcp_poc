# Global IP
resource "google_compute_global_address" "web_cdn" {
  provider = google-beta
  name     = "ga-web-cdn"
}

# Health check
resource "google_compute_health_check" "web_http" {
  provider = google-beta
  name     = "hc-web-http"
  http_health_check {
    port_specification = "USE_SERVING_PORT"
  }
}

# CDN backend for managed instance group
resource "google_compute_backend_service" "web_cdn" {
  provider                = google-beta
  name                    = "bs-web-cdn"
  protocol                = "HTTP"
  port_name               = "http"
  load_balancing_scheme   = "EXTERNAL_MANAGED"
  timeout_sec             = 10
  enable_cdn              = true
  custom_request_headers  = ["X-Client-Geo-Location: {client_region_subdivision}, {client_city}"]
  custom_response_headers = ["X-Cache-Hit: {cdn_cache_status}"]
  health_checks           = [google_compute_health_check.web_http.id]
  backend {
    group                 = google_compute_region_instance_group_manager.web.instance_group
    balancing_mode        = "RATE"
    max_rate_per_instance = 100
    capacity_scaler       = 1.0
  }
}

# Backend bucket with CDN policy with default ttl settings
resource "google_compute_backend_bucket" "sa_cdn" {
  name        = "bb-sa-cdn"
  description = "Static web contents from bucket"
  bucket_name = google_storage_bucket.poc.name
  enable_cdn  = true
  cdn_policy {
    cache_mode        = "CACHE_ALL_STATIC"
    client_ttl        = 3600
    default_ttl       = 3600
    max_ttl           = 86400
    negative_caching  = true
    serve_while_stale = 86400
  }
}

# HTTPS URL map
resource "google_compute_url_map" "web_cdn" {
  provider        = google-beta
  name            = "um-web-cdn"
  default_service = google_compute_backend_service.web_cdn.id

  host_rule {
    hosts        = ["cdn.${var.domain_name}"]
    # hosts        = ["*"]
    path_matcher = "allpaths"
  }

  path_matcher {
    name            = "allpaths"
    default_service = google_compute_backend_service.web_cdn.id

    path_rule {
      paths   = ["/content/*", "/css/*"]
      service = google_compute_backend_bucket.sa_cdn.id
    }
  }
}

resource "google_compute_ssl_certificate" "web_cdn" {
  provider    = google-beta
  name_prefix = "sc-web-proxy"
  private_key = acme_certificate.ssl.private_key_pem
  certificate = "${acme_certificate.ssl.certificate_pem}${acme_certificate.ssl.issuer_pem}"
  lifecycle {
    create_before_destroy = true
  }
}

# HTTPS proxy
resource "google_compute_target_https_proxy" "web_cdn" {
  provider = google-beta
  name     = "thp-web-cdn"
  url_map  = google_compute_url_map.web_cdn.id
  ssl_certificates = [google_compute_ssl_certificate.web_cdn.id]
}

# HTTPS forwarding rule
resource "google_compute_global_forwarding_rule" "web_cdn" {
  provider              = google-beta
  name                  = "gfr-web-cdn"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "443"
  target                = google_compute_target_https_proxy.web_cdn.id
  ip_address            = google_compute_global_address.web_cdn.id
}

# HTTP redirect to HTTPS
resource "google_compute_url_map" "redirect" {
  provider        = google-beta
  name            = "um-redirect"
  default_service = google_compute_backend_service.web_cdn.id
  host_rule {
    hosts        = ["*"]
    path_matcher = "allpaths"
  }
  path_matcher {
    name            = "allpaths"
    default_service = google_compute_backend_service.web_cdn.id
    path_rule {
      paths = ["/*"]
      url_redirect {
        https_redirect         = true
        host_redirect          = "cdn.${var.domain_name}:443"        
        redirect_response_code = "PERMANENT_REDIRECT"
        strip_query            = true
      }
    }
  }
}

resource "google_compute_target_http_proxy" "redirect" {
  provider = google-beta
  name     = "thp-redirect"
  url_map  = google_compute_url_map.redirect.id
}

resource "google_compute_global_forwarding_rule" "redirect" {
  provider              = google-beta
  name                  = "gfr-redirect"
  ip_protocol           = "TCP"
  ip_address            = google_compute_global_address.web_cdn.id
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "80"
  target                = google_compute_target_http_proxy.redirect.id
}