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

variable "controlplane_count" {
  type = number
  default = 3
}

variable "controlplane_ips" {
  type = list(string)
  default = [ 
    "192.168.254.201",
    "192.168.254.202",
    "192.168.254.203" 
    ]
}