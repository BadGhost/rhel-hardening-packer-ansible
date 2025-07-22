// packer/rhel9-cis.pkr.hcl

packer {
  required_plugins {
    hyperv = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/hyperv"
    }
    ansible = {
      version = ">= 1.0.0"
      source = "github.com/hashicorp/ansible"
    }
  }
}

source "hyperv-iso" "rhel9" {
  # --- Hyper-V Settings ---
  vm_name              = var.vm_name
  vswitch              = var.hyperv_vswitch
  enable_secure_boot   = true
  generation           = 2

  # --- VM Hardware ---
  cpus                 = 2
  memory               = 4096
  disk_size            = 40960

  # --- Installation Media ---
  iso_path             = var.iso_path
  iso_checksum         = "none" // For local ISOs

  # --- Unattended Installation ---
  http_directory       = "http"
  boot_wait            = "5s"
  boot_command         = [
    "<up><wait><tab>",
    " inst.ks=http://{{.HTTPIP}}:{{.HTTPPort}}/ks.cfg",
    "<enter>"
  ]

  # --- Connection for Provisioners ---
  ssh_username         = "packer"
  ssh_password         = var.packer_user_password
  ssh_timeout          = "30m"

  # --- Output ---
  output_directory     = "output"
}

build {
  sources = ["source.hyperv-iso.rhel9"]

  provisioner "ansible" {
    playbook_file = "../ansible/hardening.yml"
    user          = "packer"
  }
}
