# curl -k https://cdn.gcp.cnpro.org -H 'X-Api-Version: ${jndi:ldap://127.0.0.1/log4j}'

resource "google_compute_security_policy" "web_cdn" {
  provider = google-beta
  name     = "sp-web-cdn"
  rule {
    action   = "deny(403)"
    priority = 1
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('cve-canary')"
      }
    }
  }
  rule {
    action   = "allow"
    priority = "2147483647"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "default rule"
  }
}
