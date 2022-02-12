/*
resource "null_resource" "dns_a_proxy" {
  triggers = {
    address = google_compute_address.web_proxy.address
    dns_zone_resource_group_name = var.dns_zone_resource_group_name
    domain_name = var.domain_name
  }
  provisioner "local-exec" {
    command = "az network dns record-set a add-record -g ${self.triggers.dns_zone_resource_group_name} -z ${self.triggers.domain_name} --ttl 300 -n proxy -a ${self.triggers.address}"
  }
  provisioner "local-exec" {
    when    = destroy
    command = "az network dns record-set a delete -g ${self.triggers.dns_zone_resource_group_name} -z ${self.triggers.domain_name} -n proxy -y"
  }  
}

resource "null_resource" "dns_a_nlb" {
  triggers = {
    address = google_compute_address.web_nlb.address
    dns_zone_resource_group_name = var.dns_zone_resource_group_name
    domain_name = var.domain_name
  }
  provisioner "local-exec" {
    command = "az network dns record-set a add-record -g ${self.triggers.dns_zone_resource_group_name} -z ${self.triggers.domain_name} --ttl 300 -n nlb -a ${self.triggers.address}"
  }
  provisioner "local-exec" {
    when    = destroy
    command = "az network dns record-set a delete -g ${self.triggers.dns_zone_resource_group_name} -z ${self.triggers.domain_name} -n nlb -y"
  }  
}
*/

resource "azurerm_dns_a_record" "proxy" {
  provider = azurerm
  name                = "proxy"
  zone_name           = var.domain_name
  resource_group_name = var.dns_zone_resource_group_name
  ttl                 = 300
  records             = [google_compute_address.web_proxy.address]
}

resource "azurerm_dns_a_record" "nlb" {
  provider = azurerm
  name                = "nlb"
  zone_name           = var.domain_name
  resource_group_name = var.dns_zone_resource_group_name
  ttl                 = 300
  records             = [google_compute_address.web_nlb.address]
}

resource "azurerm_dns_a_record" "cdn" {
  provider = azurerm
  name                = "cdn"
  zone_name           = var.domain_name
  resource_group_name = var.dns_zone_resource_group_name
  ttl                 = 300
  records             = [google_compute_global_address.web_cdn.address]
}