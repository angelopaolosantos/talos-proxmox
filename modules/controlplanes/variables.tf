variable "controlplane_count" {
    type = number
    default = 3
}

variable "controlplane_ips" {
    type = list(string)
    default = [
        "192.168.254.101",
        "192.168.254.102",
        "192.168.254.103"
    ]
}

variable "proxmox_endpoint" {
  type = string
  default = "https://my-proxmox-endpoint.local/"
}

variable "proxmox_username" {
  type = string
  default = "root@pam"
}

variable "proxmox_password" {
  type = string
  default = "my-proxmox-password"
}

variable "file_id" {
  type = string  
}

variable "public_key_openssh" {
    type = string
}

variable "network_range" {
    type = string
    default = "24"
}

variable "gateway" {
    type = string
    default = "192.168.254.254"
    description = "network gateway"
}

variable "vm_user" {
    type = string
    default = "talos"
}

variable "cpu_cores" {
  type = number
  default = 4
}

variable "dedicated_memory" {
  type = number
  default = 6144
}