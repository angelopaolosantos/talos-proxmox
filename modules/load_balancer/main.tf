resource "proxmox_virtual_environment_vm" "load_balancer_vm" {
  count = var.load_balancer_count
  name        = "load-balancer-vm-${count.index+1}"
  description = "Managed by Terraform"
  tags        = ["terraform", "ubuntu", "k8s"]

  node_name = "pve01"

  agent {
    # read 'Qemu guest agent' section, change to true only when ready
    enabled = false
  }

  startup {
    order      = "1"
    up_delay   = "60"
    down_delay = "60"
  }

  disk {
    datastore_id = "local-zfs"
    file_id      = var.file_id
    interface    = "scsi0"
    size = 25
  }

  initialization {
    datastore_id = "local-zfs"

    ip_config {
      ipv4 {
        address = "${var.load_balancer_ips[count.index]}/${var.network_range}"
        gateway = var.gateway
      }
    }

    user_account {
      keys     = [trimspace(var.public_key_openssh)]
      # password = random_password.ubuntu_vm_password.result
      password = "mypassword"
      username = var.vm_user
    }

    interface = "ide2"
  }

  machine = "q35"

  bios = "ovmf"

  efi_disk {
    datastore_id = "local-zfs"
    file_format = "raw"
    type = "4m"
  }

  cpu {
    cores = var.cpu_cores
    type = "x86-64-v2-AES" // x86-64-v2-AES | host
  }

  memory {
    dedicated = var.dedicated_memory // 2048 | 4096 | 8192
  } 

  network_device {
    bridge = "vmbr0"
    model = "virtio"
    # vlan_id = 10
  }

  operating_system {
    type = "l26"
  }
}
