output "name" {
  value = proxmox_virtual_environment_vm.nfs_vm.*.name
  description = ""
}

output "ip" {
value = var.nfs_ips
  description = ""
}