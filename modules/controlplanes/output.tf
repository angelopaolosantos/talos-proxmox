output "name" {
  value = proxmox_virtual_environment_vm.controlplane_vm.*.name
  description = ""
}

output "ip" {
  value = var.controlplane_ips
  description = ""
}

output "controlplane_count" {
  value = var.controlplane_count
  description = ""
}

output "vm_user" {
  value = var.vm_user
  description = ""
}