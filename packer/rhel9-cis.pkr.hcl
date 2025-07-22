packer {
  required_plugins {
    ansible = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/ansible"
    }
    vmware = {
      version = ">= 1.0.8"
      source  = "github.com/hashicorp/vmware"
    }
  }
}

source "vmware-iso" "rhel9" {
  iso_url            = var.iso_url
  iso_checksum       = var.iso_checksum
  ssh_username       = var.ssh_username
  ssh_password       = var.ssh_password
  shutdown_command   = "echo '${var.ssh_password}' | sudo -S shutdown -P now"
  guest_os_type      = "rhel9-64"
  cpus               = 2
  memory             = 4096
  disk_size          = 40000
  vm_name            = "rhel9-cis-hardened"
  http_directory     = "../http"
  boot_command       = [
    "<up><wait><tab><wait> inst.text inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ks.cfg<enter><wait>"
  ]
  boot_wait          = "10s"
  headless           = true
  output_directory   = "${var.output_directory}"
}

build {
  name = "rhel9-cis-hardened"
  sources = ["source.vmware-iso.rhel9"]

  provisioner "shell" {
    inline = [
      "echo 'Installing prerequisites for Ansible...'",
      "sudo yum -y install python3 python3-pip",
      "sudo pip3 install ansible"
    ]
  }

  provisioner "ansible-local" {
    playbook_file   = "../ansible/hardening.yml"
    playbook_dir    = "../ansible"
    extra_arguments = [
      "--extra-vars", "ansible_python_interpreter=/usr/bin/python3"
    ]
  }

  post-processor "manifest" {
    output = "manifest.json"
    strip_path = true
  }
}