// packer/main.pkr.hcl

packer {
  required_plugins {
    hyperv = {
      version = ">= 1.1.2"
      source  = "github.com/hashicorp/hyperv"
    }
    ansible = {
      version = ">= 1.1.1"
      source  = "github.com/hashicorp/ansible"
    }
  }
}

variable "packer_user_password" {
  type      = string
  sensitive = true
}

variable "vm_name" {
  type    = string
  default = "rhel9-cis-template"
}

variable "iso_path" {
  type    = string
  default = "/mnt/c/Users/ifirdaus/Downloads/rhel-9.6-x86_64-dvd.iso"
}

source "hyperv-iso" "rhel9" {
  # --- VM and Hardware ---
  vm_name    = var.vm_name
  generation = 2
  cpus       = 2
  memory     = 4096
  disk_size  = 40960

  # --- Installation Media ---
  iso_urls     = [var.iso_path]
  iso_checksum = "sha256:febcc1359fd68faceff82d7eed8d21016e022a17e9c74e0e3f9dc3a78816b2bb"

  # --- Unattended Installation ---
  http_directory = "http"
  boot_wait      = "10s"
  boot_command   = [
    "<up><wait><tab>",
    " inst.ks=http://{{.HTTPIP}}:{{.HTTPPort}}/ks.cfg",
    "<enter>"
  ]

  # --- Connection and Shutdown ---
  ssh_username     = "packer"
  ssh_password     = var.packer_user_password
  ssh_timeout      = "45m"
  shutdown_command = "sudo /sbin/halt -p"

  # --- Output ---
  output_directory = "output/${var.vm_name}"
}

build {
  sources = ["source.hyperv-iso.rhel9"]

  provisioner "ansible" {
    # CORRECTED: The path must go up one directory level
    playbook_file = "ansible/playbook.yaml"
    user          = "packer"
  }

  provisioner "shell" {
    inline = [
      "echo 'Running cleanup script'",
      "/usr/bin/dnf clean all",
      "sudo dd if=/dev/zero of=/EMPTY bs=1M || echo 'dd exit code is ignored'",
      "sudo rm -f /EMPTY",
      "sudo sync"
    ]
  }
}