// packer/variables.pkr.hcl

variable "hyperv_vswitch" {
  type    = string
  default = "Default Switch"
}

variable "iso_path" {
  type    = string
  default = "C:\\Users\\ifirdaus\\Downloads\\rhel-9.6-x86_64-dvd.iso"
}

variable "vm_name" {
  type    = string
  default = "rhel9-cis-template"
}

variable "packer_user_password" {
  type      = string
  sensitive = true
}

