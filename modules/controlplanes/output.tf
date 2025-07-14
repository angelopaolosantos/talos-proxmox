output "name" {
  value = proxmox_virtual_environment_vm.controlplane_vm.*.name
  description = ""
}

output "ip" {
value = var.controlplane_ips
  description = ""
}