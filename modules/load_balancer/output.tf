output "name" {
  value = proxmox_virtual_environment_vm.load_balancer_vm.*.name
  description = ""
}

output "ip" {
value = var.load_balancer_ips
  description = ""
}

output "load_balancer_count" {
  value = var.load_balancer_count
  description = ""
}

output "vm_user" {
  value = var.vm_user
  description = ""
}

output "load_balancer_allowed_access_ip" {
  value = var.load_balancer_allowed_access_ip
  description = ""
}