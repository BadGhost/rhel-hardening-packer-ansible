# RHEL Hardening with Packer and Ansible

This project creates a CIS-hardened RHEL 9 golden image using Packer and Ansible.

## Prerequisites

- Packer (latest version)
- Ansible (latest version)
- VMware Workstation/Fusion or VirtualBox
- RHEL 9 ISO file

## Project Structure

```
rhel-hardening-packer-ansible/
├── ansible/
│   ├── group_vars/
│   │   └── all/
│   │       └── cis_settings.yaml
│   ├── inventory/
│   │   └── hosts
│   └── hardening.yml
├── http/
│   └── ks.cfg
├── packer/
│   ├── rhel9-cis.pkr.hcl
│   ├── secrets.pkrvars.hcl
│   └── variables.pkr.hcl
├── ansible.cfg
└── README.md
```

## Usage

### 1. Configure Variables

Update the `packer/secrets.pkrvars.hcl` file with your RHEL ISO URL, checksum, and credentials.

### 2. Update Kickstart File

Modify the `http/ks.cfg` file with your desired partitioning scheme and initial configuration.

### 3. Customize CIS Settings

Adjust the CIS hardening settings in `ansible/group_vars/all/cis_settings.yaml` to match your security requirements.

### 4. Build the Image

```bash
cd packer
packer init rhel9-cis.pkr.hcl
packer build -var-file=secrets.pkrvars.hcl rhel9-cis.pkr.hcl
```

### 5. Running Ansible Separately

To run the Ansible hardening playbook on an existing VM:

```bash
ansible-playbook -i ansible/inventory/hosts ansible/hardening.yml
```

## CIS Hardening Controls

This project implements the following CIS controls:

1. Initial Setup
   - Filesystem Configuration
   - Software Updates
   - Secure Boot Settings
   - Additional Process Hardening
   - Mandatory Access Control

2. Services
   - Special Purpose Services
   - Service Clients

3. Network Configuration
   - Network Parameters
   - Firewall Configuration

4. Logging and Auditing
   - Configure System Accounting
   - Configure Logging

5. Access, Authentication and Authorization
   - Configure cron
   - SSH Server Configuration
   - PAM Configuration
   - User Accounts and Environment

6. System Maintenance
   - System File Permissions
   - User and Group Settings

## Best Practices

1. Always use version control for your infrastructure code
2. Store sensitive information in a secure vault
3. Test hardened images in a non-production environment first
4. Regularly update your hardening standards as new CIS benchmarks are released
5. Document any deviations from CIS benchmarks with justification