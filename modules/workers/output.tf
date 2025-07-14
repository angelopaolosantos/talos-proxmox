output "name" {
  value = proxmox_virtual_environment_vm.worker_vm.*.name
  description = ""
}

output "ip" {
value = var.worker_ips
  description = ""
}