output "ubuntu_private_key" {
  value     = tls_private_key.ubuntu_private_key.private_key_pem
  sensitive = true
}

output "ubuntu_public_key" {
  value = tls_private_key.ubuntu_private_key.public_key_openssh
}
