output "name" {
  value = proxmox_virtual_environment_vm.worker_vm.*.name
  description = ""
}

output "ip" {
value = var.worker_ips
  description = ""
}

output "worker_count" {
  value = var.worker_count
  description = ""
}

output "vm_user" {
  value = var.vm_user
  description = ""
}