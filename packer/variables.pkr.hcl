variable "iso_url" {
  type        = string
  description = "URL to the RHEL ISO file"
}

variable "iso_checksum" {
  type        = string
  description = "Checksum of the ISO file"
}

variable "ssh_username" {
  type        = string
  description = "Username for SSH connection"
  default     = "root"
}

variable "ssh_password" {
  type        = string
  description = "Password for SSH connection"
  sensitive   = true
}

variable "output_directory" {
  type        = string
  description = "Directory where the VM will be exported"
  default     = "output-rhel9-cis"
}