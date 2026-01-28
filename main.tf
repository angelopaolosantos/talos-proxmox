resource "tls_private_key" "ubuntu_private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096

  provisioner "local-exec" {
    command = "mkdir -p .ssh"
  }

  provisioner "local-exec" { # Copy a "my-private-key.pem" to local computer.
    command = "echo '${tls_private_key.ubuntu_private_key.private_key_pem}' | tee ${path.cwd}/.ssh/my-private-key.pem"
  }

  provisioner "local-exec" {
    command = "chmod 600 ${path.cwd}/.ssh/my-private-key.pem"
  }

  provisioner "local-exec" { # Copy a "my-private-key.pem" to local computer.
    command = "echo '${tls_private_key.ubuntu_private_key.public_key_openssh}' | tee ${path.cwd}/.ssh/my-public-key.pub"
  }

  provisioner "local-exec" {
    command = "chmod 600 ${path.cwd}/.ssh/my-public-key.pub"
  }
}

# resource "proxmox_virtual_environment_download_file" "latest_ubuntu_22_jammy_qcow2_img" {
#   content_type = "iso"
#   datastore_id = "local"
#   node_name    = "pve01"
#   url            = "https://cloud-images.ubuntu.com/noble/20250704/noble-server-cloudimg-amd64.img"
#   upload_timeout = 4444 // seconds, make it longer to accomodate big files
# }

# resource "proxmox_virtual_environment_download_file" "latest_talos_linux_nocloud_img" {
#   content_type = "iso"
#   datastore_id = "local"
#   node_name    = "pve01"
#   url          = "https://factory.talos.dev/image/ce4c980550dd2ab1b17bbf2b08801c7eb59418eafe8f279833297925d67c7515/v1.10.5/nocloud-amd64-secureboot.iso"
#   upload_timeout = 4444 // seconds, make it longer to accomodate big files
# }


resource "random_password" "vm_password" {
  length           = 16
  override_special = "_%@"
  special          = true
}

module "controlplanes" {
  source             = "./modules/controlplanes"
  # file_id            = proxmox_virtual_environment_download_file.latest_talos_linux_nocloud_img.id
  # For Proxmox environments download images once to the Proxmox host and manage them outside Terraform.
  # Use Terraform for infrastructure, not artifact transport. It leads to fewer brittle failures.
  # File exists in local:iso/ubuntu-24.04-noble.img
  file_id            = "local:iso/nocloud-amd64-secureboot.iso"
  public_key_openssh = tls_private_key.ubuntu_private_key.public_key_openssh

  controlplane_count = var.controlplane_count
  controlplane_ips = var.controlplane_ips

  providers = {
    proxmox = proxmox
  }
}

module "workers" {
  source             = "./modules/workers"
  # file_id            = proxmox_virtual_environment_download_file.latest_talos_linux_nocloud_img.id
  file_id            = "local:iso/nocloud-amd64-secureboot.iso"
  public_key_openssh = tls_private_key.ubuntu_private_key.public_key_openssh

  worker_count = var.worker_count
  worker_ips = var.worker_ips

  providers = {
    proxmox = proxmox
  }
}

# module "nfs_server" {
#   source = "./modules/nfs_server"
#   # file_id            = proxmox_virtual_environment_download_file.latest_ubuntu_22_jammy_qcow2_img.id
#   file_id            = "local:noble-server-cloudimg-amd64.img"
#   public_key_openssh = tls_private_key.ubuntu_private_key.public_key_openssh
#
# nfs_ips = [
#   "192.168.254.107"
# ]
#
#   providers = {
#     proxmox = proxmox
#   }
# }

module "load_balancers" {
  source             = "./modules/load_balancer"
  # file_id            = proxmox_virtual_environment_download_file.latest_ubuntu_22_jammy_qcow2_img.id
  file_id            = "local:iso/noble-server-cloudimg-amd64.img"
  public_key_openssh = tls_private_key.ubuntu_private_key.public_key_openssh

  load_balancer_count = var.load_balancer_count
  load_balancer_ips = var.load_balancer_ips

  cpu_cores = 2
  dedicated_memory = 2048

  providers = {
    proxmox = proxmox
  }
}

# module "ansible_control_node" {
#   source             = "./modules/ansible_control_node"
#   # file_id            = proxmox_virtual_environment_download_file.latest_ubuntu_22_jammy_qcow2_img.id
#   file_id            = "local:iso/noble-server-cloudimg-amd64.img"
#   public_key_openssh = tls_private_key.ubuntu_private_key.public_key_openssh

#   ansible_ips = var.ansible_ips

#   providers = {
#     proxmox = proxmox
#   }
# }

# Ansible Section 

resource "ansible_host" "controlplane" {
  name   = module.controlplanes.ip[count.index]
  groups = ["controlplanes", "controlplane_${count.index + 1}"]

  variables = {
    ansible_user                 = module.controlplanes.vm_user
    ansible_ssh_private_key_file = "./.ssh/my-private-key.pem"
    ansible_python_interpreter   = "/usr/bin/python3"
    host_name                    = module.controlplanes.name[count.index]
    private_ip                   = module.controlplanes.ip[count.index]
  }
  count = module.controlplanes.controlplane_count

  # Add depends_on to destroy this node before nfs server, otherwise will get stuck with nfs error restricting shutdown.
  # depends_on = [ansible_host.nfs]
}

resource "ansible_host" "worker" {
  name   = module.workers.ip[count.index]
  groups = ["workers", "worker_${count.index + 1}"]

  variables = {
    ansible_user                 = module.workers.vm_user
    ansible_ssh_private_key_file = "./.ssh/my-private-key.pem"
    ansible_python_interpreter   = "/usr/bin/python3"
    host_name                    = module.workers.name[count.index]
    private_ip                   = module.workers.ip[count.index]
  }
  count = module.workers.worker_count
}

# resource "ansible_host" "nfs" {
#   name   = module.nfs_server.ip[count.index]
#   groups = ["nfs"]

#   variables = {
#     ansible_user                 = module.nfs_server.vm_user
#     ansible_ssh_private_key_file = "./.ssh/my-private-key.pem"
#     ansible_python_interpreter   = "/usr/bin/python3"
#     host_name                    = module.nfs_server.name[count.index]
#     private_ip                   = module.nfs_server.ip[count.index]
#   }

#   count = module.nfs_server.nfs_count
# }

resource "ansible_host" "load_balancer" {
  name   = module.load_balancers.ip[count.index]
  groups = ["load_balancers", "load_balancer_${count.index + 1}"]

  variables = {
    ansible_user                 = module.load_balancers.vm_user
    ansible_ssh_private_key_file = "./.ssh/my-private-key.pem"
    ansible_python_interpreter   = "/usr/bin/python3"
    host_name                    = module.load_balancers.name[count.index]
    private_ip                   = module.load_balancers.ip[count.index]
  }
  count = module.load_balancers.load_balancer_count
}

# resource "ansible_host" "ansible_control_node" {
#   name   = module.ansible_control_node.ip
#   groups = ["ansible_control_node"]

#   variables = {
#     ansible_user                 = module.ansible_control_node.vm_user
#     ansible_ssh_private_key_file = "./.ssh/my-private-key.pem"
#     ansible_python_interpreter   = "/usr/bin/python3"
#     host_name                    = module.ansible_control_node.name
#     private_ip                   = module.ansible_control_node.ip
#   }
# }

resource "ansible_group" "controlplanes" {
  name = "controlplanes"
}

resource "ansible_group" "workers" {
  name = "workers"
}

resource "ansible_group" "cluster" {
  name     = "cluster"
  children = ["controlplanes", "workers"]
}

# resource "ansible_group" "nfs" {
#   name = "nfs"
# }

# resource "ansible_group" "ansible_control_node" {
#   name = "ansible_control_node"
# }

resource "ansible_group" "load_balancers" {
  name = "load_balancers"
}

# Export Terraform variable values to an Ansible var_file
resource "local_file" "tf_ansible_vars_file_new" {
  content  = <<-DOC
    # Ansible vars_file containing variable values from Terraform.
    # Generated by Terraform mgmt configuration.

    tf_controlplane_ip:
    %{for ip in module.controlplanes.ip~}
  - ${ip}
    %{endfor}
    tf_worker_ip:
    %{for ip in module.workers.ip~}
  - ${ip}
    %{endfor}
    tf_load_balancer_ip:
    %{for ip in module.load_balancers.ip~}
  - ${ip}
    %{endfor}
    DOC

  ##  Add this to configuration if enabled
  #   tf_ansible_control_node_ip: ${module.ansible_control_node.ip}

  #   tf_nfs_server_ip:
  #   %{for ip in module.nfs_server.ip~}
  # - ${ip}
  #   %{endfor}
  
  filename = "./ansible/group_vars/all/tf_ansible_vars_file.yaml"
}
