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

resource "proxmox_virtual_environment_download_file" "latest_ubuntu_22_jammy_qcow2_img" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = "pve01"
  // url          = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img" 
  // Using latest image will destroy vms when file is changed. Prefer to use specific image.
  url          = "https://cloud-images.ubuntu.com/noble/20250704/noble-server-cloudimg-amd64.img"
  upload_timeout = 4444 // seconds, make it longer to accomodate big files
}

resource "proxmox_virtual_environment_download_file" "latest_talos_linux_nocloud_img" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = "pve01"
  url          = "https://factory.talos.dev/image/ce4c980550dd2ab1b17bbf2b08801c7eb59418eafe8f279833297925d67c7515/v1.10.5/nocloud-amd64-secureboot.iso" 
  // Using latest image will destroy vms when file is changed. Prefer to use specific image.
  // url          = "https://cloud-images.ubuntu.com/jammy/20240710/jammy-server-cloudimg-amd64.img"
  upload_timeout = 4444 // seconds, make it longer to accomodate big files
}


resource "random_password" "vm_password" {
  length           = 16
  override_special = "_%@"
  special          = true
}

module "controlplanes" {
  source = "./modules/controlplanes"
  file_id = proxmox_virtual_environment_download_file.latest_talos_linux_nocloud_img.id
  public_key_openssh = tls_private_key.ubuntu_private_key.public_key_openssh

  providers = {
    proxmox = proxmox
  }
}

module "workers" {
  source = "./modules/workers"
  file_id = proxmox_virtual_environment_download_file.latest_talos_linux_nocloud_img.id
  public_key_openssh = tls_private_key.ubuntu_private_key.public_key_openssh

  providers = {
    proxmox = proxmox
  }
}

module "nfs_server" {
  source = "./modules/nfs_server"
  file_id = proxmox_virtual_environment_download_file.latest_ubuntu_22_jammy_qcow2_img.id
  public_key_openssh = tls_private_key.ubuntu_private_key.public_key_openssh

  providers = {
    proxmox = proxmox
  }
}

module "ceph_monitors" {
  source = "./modules/ceph_monitors"
  file_id = proxmox_virtual_environment_download_file.latest_ubuntu_22_jammy_qcow2_img.id
  public_key_openssh = tls_private_key.ubuntu_private_key.public_key_openssh

  providers = {
    proxmox = proxmox
  }
}

module "ansible_control_node" {
  source = "./modules/ansible_control_node"
  file_id = proxmox_virtual_environment_download_file.latest_ubuntu_22_jammy_qcow2_img.id
  public_key_openssh = tls_private_key.ubuntu_private_key.public_key_openssh

  providers = {
    proxmox = proxmox
  }
}

# Ansible Section 

resource "ansible_host" "controlplane" {
  name   = module.controlplanes.ip[count.index]
  groups = ["controlplanes","controlplane_${count.index+1}"]

  variables = {
    ansible_user                 = module.controlplanes.vm_user
    ansible_ssh_private_key_file = "./.ssh/my-private-key.pem"
    ansible_python_interpreter   = "/usr/bin/python3"
    host_name                    = module.controlplanes.name[count.index]
    greetings                    = "from host!"
    some                         = "variable"
    private_ip                   = module.controlplanes.ip[count.index]
  }
  count = module.controlplanes.controlplane_count

  # Added to destroy this node before nfs server, otherwise will get stuck with nfs error restricting shutdown.
  depends_on = [ ansible_host.nfs ] 
}

resource "ansible_host" "worker" {
  name   = module.workers.ip[count.index]
  groups = ["workers","worker_${count.index+1}"]

  variables = {
    ansible_user                 = module.workers.vm_user
    ansible_ssh_private_key_file = "./.ssh/my-private-key.pem"
    ansible_python_interpreter   = "/usr/bin/python3"
    host_name                    = module.workers.name[count.index]
    greetings                    = "from host!"
    some                         = "variable"
    private_ip                   = module.workers.ip[count.index]
  }
  count = module.workers.worker_count

  depends_on = [ ansible_host.nfs ]
}

resource "ansible_host" "nfs" {
  name   = module.nfs_server.ip[count.index]
  groups = ["nfs"]

  variables = {
    ansible_user                 = module.nfs_server.vm_user
    ansible_ssh_private_key_file = "./.ssh/my-private-key.pem"
    ansible_python_interpreter   = "/usr/bin/python3"
    host_name                    = module.nfs_server.name[count.index]
    greetings                    = "from host!"
    some                         = "variable"
    private_ip                   = module.nfs_server.ip[count.index]
  }

  count = module.nfs_server.nfs_count
}

resource "ansible_host" "ansible_control_node" {
  name   = module.ansible_control_node.ip
  groups = ["ansible_control_node"]

  variables = {
    ansible_user                 = module.ansible_control_node.vm_user
    ansible_ssh_private_key_file = "./.ssh/my-private-key.pem"
    ansible_python_interpreter   = "/usr/bin/python3"
    host_name                    = module.ansible_control_node.name
    private_ip                   = module.ansible_control_node.ip
  }
}

resource "ansible_host" "ceph_monitor" {
  name   = module.ceph_monitors.ip[count.index]
  groups = ["ceph_monitors","ceph_monitor_${count.index+1}"]

  variables = {
    ansible_user                 = module.ceph_monitors.vm_user
    ansible_ssh_private_key_file = "./.ssh/my-private-key.pem"
    ansible_python_interpreter   = "/usr/bin/python3"
    host_name                    = module.ceph_monitors.name[count.index]
    private_ip                   = module.ceph_monitors.ip[count.index]
  }

  count = module.ceph_monitors.ceph_count
}


resource "ansible_group" "controlplanes" {
  name     = "controlplanes"
}

resource "ansible_group" "workers" {
  name     = "workers"
}

resource "ansible_group" "cluster" {
  name     = "cluster"
  children = ["controlplanes", "workers"]
}

resource "ansible_group" "nfs" {
  name     = "nfs"
}

resource "ansible_group" "ansible_control_node" {
  name     = "ansible_control_node"
}

resource "ansible_group" "ceph_monitors" {
  name     = "ceph_monitors"
}

# Export Terraform variable values to an Ansible var_file
resource "local_file" "tf_ansible_vars_file_new" {
  content = <<-DOC
    # Ansible vars_file containing variable values from Terraform.
    # Generated by Terraform mgmt configuration.

    tf_controlplane_ip:
    %{ for ip in module.controlplanes.ip ~}
  - ${ip}
    %{ endfor }
    tf_worker_ip:
    %{ for ip in module.workers.ip ~}
  - ${ip}
    %{ endfor }
    tf_nfs_server_ip:
    %{ for ip in module.nfs_server.ip ~}
  - ${ip}
    %{ endfor }
    tf_ceph_monitor_ip:
    %{ for ip in module.ceph_monitors.ip ~}
  - ${ip}
    %{ endfor }
    tf_ansible_control_node_ip: ${module.ansible_control_node.ip}
    nfs_allowed_access_ip: ${module.nfs_server.nfs_allowed_access_ip}
    DOC
  filename = "./ansible/tf_ansible_vars_file.yaml"
}