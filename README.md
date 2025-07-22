# Automating CIS-Hardened RHEL 9 Golden Images with Packer and Ansible on Hyper-V

This guide provides a step-by-step walkthrough for creating a secure, CIS-hardened RHEL 9 "golden image" on a Windows 11 machine using Hyper-V, Packer, and Ansible. It adapts the best practices from the "Automating the Creation of CIS-Hardened RHEL 9 Golden Images with Packer and Ansible" document to a Hyper-V environment.

## 1. The Build Environment: Windows Subsystem for Linux (WSL)

To create a consistent and powerful build environment on your Windows 11 machine, we will use the Windows Subsystem for Linux (WSL). This allows you to run a Linux distribution directly on Windows, providing a native environment for Ansible and Packer.

### 1.1. Installing WSL

1.  **Open PowerShell as Administrator** and run:
    ```powershell
    wsl --install
    ```
2.  This command will install the latest Ubuntu distribution by default. After the installation, **reboot your machine**.
3.  After rebooting, a terminal window will open to complete the installation. You will be prompted to create a username and password for your new Linux distribution.

### 1.2. Installing Packer and Ansible in WSL

1.  **Open your WSL terminal** (e.g., Ubuntu).
2.  **Install Packer:**
    ```bash
    sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
    wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
    sudo apt-get update && sudo apt-get install packer
    ```
3.  **Install Ansible:**
    ```bash
    sudo apt-get install -y ansible
    ```

## 2. Project Structure

A well-organized project is crucial for maintainability. The following directory structure should be created within your project's root folder (`rhel9-cis-image-factory/`):

```
rhel9-cis-image-factory/
├── ansible.cfg
├── packer/
│   ├── rhel9-cis.pkr.hcl
│   ├── variables.pkr.hcl
│   └── secrets.pkrvars.hcl
├── http/
│   └── ks.cfg
├── ansible/
│   ├── inventory/
│   ├── group_vars/
│   │   └── all/
│   │       ├── cis_settings.yml
│   │       └── vault.yml
│   ├── roles/
│   └── hardening.yml
└── README.md
```

## 3. Configuring Packer for Hyper-V

Packer will use the `hyperv-iso` builder to create the RHEL 9 image on Hyper-V.

### 3.1. Packer Variables (`packer/variables.pkr.hcl`)

This file defines the variables for your Packer build.

```hcl
// packer/variables.pkr.hcl

variable "hyperv_vswitch" {
  type    = string
  default = "Default Switch"
}

variable "iso_path" {
  type    = string
  default = "C:\ISOs\rhel-9.4-x86_64-dvd.iso"
}

variable "vm_name" {
  type    = string
  default = "rhel9-cis-template"
}

variable "packer_user_password" {
  type      = string
  sensitive = true
}
```

### 3.2. Packer Secrets (`packer/secrets.pkrvars.hcl`)

Store your sensitive data in this file and **add it to your `.gitignore` file**.

```hcl
# packer/secrets.pkrvars.hcl
packer_user_password = "YourSecurePassword"
```

### 3.3. The Packer Template (`packer/main.pkr.hcl`)

This is the main Packer template for building the RHEL 9 image on Hyper-V.

```hcl
// packer/main.pkr.hcl

packer {
  required_plugins {
    hyperv = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/hyperv"
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
```

## 4. Automating the RHEL 9 Installation

### 4.1. Kickstart Configuration (`http/ks.cfg`)

This file automates the RHEL 9 installation.

```
# http/ks.cfg

# Use graphical install
graphical

# System language
lang en_US.UTF-8

# Keyboard layouts
keyboard --vckeymap=us --xlayouts='us'

# Network information
network  --bootproto=dhcp --device=link --activate
network  --hostname=localhost.localdomain

# Root password (locked by default)
rootpw --iscrypted --lock *

# Firewall configuration
firewall --disabled

# System services
services --enabled="sshd"

# Do not configure the X Window System
skipx

# System timezone
timezone America/New_York --isUtc

# System bootloader configuration
bootloader --location=mbr --boot-drive=sda

# Partition clearing information
clearpart --all --initlabel
# Disk partitioning information
part /boot --fstype="xfs" --ondisk=sda --size=1024
part pv.01 --fstype="lvmpv" --ondisk=sda --size=1 --grow
volgroup rhel --pesize=4096 pv.01
logvol / --fstype="xfs" --name=root --vgname=rhel --size=1 --grow

%packages --ignoremissing --excludedocs --nobase
@^server-product-environment
cloud-init
-fprintd-pam
-intltool
%end

%post --log=/root/ks-post.log
# Create the temporary packer user for Ansible
/usr/sbin/useradd packer -c "Packer User"
# Set a temporary password for the packer user
echo "YourSecurePassword" | /usr/bin/passwd --stdin packer
# Grant passwordless sudo to the packer user
echo "packer ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/packer
chmod 0440 /etc/sudoers.d/packer
%end

# Reboot after installation
reboot
```

**Important:** Replace `"YourSecurePassword"` in the `%post` section with the same password you set in `packer/secrets.pkrvars.hcl`.

## 5. Hardening with Ansible

### 5.1. Ansible Configuration (`ansible.cfg`)

Create this file in the root of your project.

```ini
# ansible.cfg
[defaults]
inventory      = ./ansible/inventory
roles_path     = ./ansible/roles
retry_files_enabled = False
host_key_checking = False

[ssh_connection]
pipelining = True
```

### 5.2. Ansible Playbook (`ansible/hardening.yml`)

This playbook will execute the CIS hardening role.

```yaml
# ansible/hardening.yml
- name: Harden RHEL 9 Server to CIS Benchmark
  hosts: all
  become: true
  gather_facts: true

  roles:
    - role: ansible-lockdown.RHEL9-CIS
      tags:
        - level2-server

- name: Final Image Cleanup
  hosts: all
  become: true
  gather_facts: false

  tasks:
    - name: Remove the temporary packer user
      ansible.builtin.user:
        name: packer
        state: absent
        remove: true

    - name: Remove the packer sudoers file
      ansible.builtin.file:
        path: /etc/sudoers.d/packer
        state: absent
```

### 5.3. Installing the CIS Role

From your WSL terminal, run the following command from the root of your project directory:

```bash
ansible-galaxy role install -p ansible/roles ansible-lockdown.rhel9_cis,2.0.2
```

### 5.4. Customizing the Hardening (`ansible/group_vars/all/cis_settings.yml`)

You can override the default settings of the CIS role in this file. For example, to keep the `cockpit` service enabled:

```yaml
# ansible/group_vars/all/cis_settings.yml

rhel9cis_rule_2_1_1_services_disabled:
  - autofs
  - avahi-daemon
  # - cockpit
  - cups
  - dhcpd
  - dnsmasq
```

## 6. Building the Golden Image

1.  **Open your WSL terminal** and navigate to your project directory.
2.  **Initialize Packer** to install the required plugins:
    ```bash
    packer init packer
    ```
3.  **Start the local HTTP server** for the Kickstart file:
    ```bash
    python3 -m http.server --directory http 8080 &
    ```
4.  **Run the Packer build:**
    ```bash
    packer build -var-file=packer/secrets.pkrvars.hcl packer
    ```

Packer will now create the Hyper-V VM, install RHEL 9 using the Kickstart file, run the Ansible playbook to harden the OS, and finally, create the golden image in the `output` directory.
