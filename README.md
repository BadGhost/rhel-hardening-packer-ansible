# RHEL 9.6 Secure Image Build & Hardening Guide

This project automates the creation of a secure and optimized RHEL 9.6 image using Packer and Ansible, following CIS security benchmarks. The process is designed for Windows users and leverages VirtualBox as the virtualization provider.

---

## Prerequisites

1. **Download RHEL 9.6 ISO**
   - Ensure the ISO is located at: `C:\Users\ifirdaus\Downloads\rhel-9.6-x86_64-dvd.iso`

2. **Install Required Software**
   - [VirtualBox](https://www.virtualbox.org/wiki/Downloads)
   - [Packer](https://developer.hashicorp.com/packer/install)
   - [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html) (Windows users: install via WSL or use [Cygwin](https://www.cygwin.com/) / [Ansible for Windows](https://docs.ansible.com/ansible/latest/user_guide/windows.html))
   - (Optional) [WSL2](https://learn.microsoft.com/en-us/windows/wsl/install) for easier Ansible usage

---

## Project Structure

- `packer/` — Packer templates and configuration files
- `ansible/` — Ansible playbooks and roles for hardening (CIS)
- `README.md` — This guide

---

## Step-by-Step Usage

### 1. Install Prerequisites
- Install VirtualBox and Packer.
- Set up Ansible (recommended via WSL2 for Windows users).

### 2. Configure Packer Template
- Edit the Packer template in `packer/` to ensure the ISO path matches your system:
  ```json
  "iso_url": "C:/Users/ifirdaus/Downloads/rhel-9.6-x86_64-dvd.iso"
  ```
- Adjust any other variables as needed (e.g., VM RAM, CPUs).

### 3. Prepare Ansible Playbooks
- The `ansible/` directory contains playbooks and roles for CIS hardening.
- Review and customize variables as needed for your environment.

### 4. Build the Image
- Open a terminal (PowerShell or WSL).
- Navigate to the project root directory.
- Run the following command to build the image:
  ```powershell
  packer build packer/template.json
  ```
- Packer will:
  - Create a VM in VirtualBox
  - Install RHEL 9.6 from the ISO
  - Use Ansible to apply CIS hardening automatically

### 5. Output
- The resulting VirtualBox image will be available in the output directory specified in the Packer template.

---

## Notes & Best Practices
- **CIS Hardening**: The included Ansible roles are based on the CIS benchmark. You can later add STIG roles as needed.
- **Customization**: Adjust playbooks and Packer variables to fit your organization’s requirements.
- **Future Updates**: To switch to STIG, add or update Ansible roles in the `ansible/` directory.

---

## Troubleshooting
- Ensure all paths use forward slashes (`/`) or double backslashes (`\\`) in JSON files.
- If Ansible is not found, ensure it is installed in your WSL environment and accessible from your terminal.
- For VirtualBox networking or driver issues, consult the [VirtualBox documentation](https://www.virtualbox.org/manual/UserManual.html).

---

## References
- [Packer Documentation](https://developer.hashicorp.com/packer/docs)
- [Ansible Documentation](https://docs.ansible.com/)
- [CIS Benchmarks](https://www.cisecurity.org/cis-benchmarks)

---

For questions or to request enhancements, please contact the project maintainer.
