variable "nfs_count" {
    type = number
    default = 1
}

variable "nfs_ips" {
    type = list(string)
    default = [
        "192.168.254.107",
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

variable "nfs_allowed_access_ip" {
    type = string
    default = "192.168.254.0/24"
}