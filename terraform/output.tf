output "web_ip1" {
  value = "${azurerm_public_ip.test.ip_address}"
}
