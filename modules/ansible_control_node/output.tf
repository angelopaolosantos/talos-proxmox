output "name" {
  value = proxmox_virtual_environment_vm.ansible_vm.name
  description = ""
}

output "ip" {
value = var.ansible_ips
  description = ""
}

output "vm_user" {
  value = var.vm_user
  description = ""
}