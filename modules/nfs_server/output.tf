output "name" {
  value = proxmox_virtual_environment_vm.nfs_vm.*.name
  description = ""
}

output "ip" {
value = var.nfs_ips
  description = ""
}

output "nfs_count" {
  value = var.nfs_count
  description = ""
}

output "vm_user" {
  value = var.vm_user
  description = ""
}

output "nfs_allowed_access_ip" {
  value = var.nfs_allowed_access_ip
  description = ""
}