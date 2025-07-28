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
   - **Packer VirtualBox Plugin**: Install with:
     ```powershell
     packer plugins install github.com/hashicorp/virtualbox
     ```

---

## Project Structure

- `packer/` — Packer templates and configuration files
- `ansible/` — Ansible playbooks and roles for hardening (CIS)
- `README.md` — This guide

---

## Step-by-Step Usage


### 1. Install Prerequisites
- Install VirtualBox and Packer.
- Set up Ansible (recommended: use a Python virtual environment on Windows):
  1. Install Python for Windows from [python.org](https://www.python.org/downloads/windows/) (check "Add Python to PATH" during install).
  2. Open PowerShell in your project directory.
  3. Create a Python virtual environment:
     ```powershell
     python -m venv ansible-env
     ```
  4. Activate the virtual environment:
     ```powershell
     .\ansible-env\Scripts\Activate
     ```
  5. Install Ansible:
     ```powershell
     pip install ansible
     ```
  6. Verify Ansible is installed:
     ```powershell
     ansible-playbook --version
     ```
  7. Keep the virtual environment activated when running Packer:
     ```powershell
     packer build packer\template.json
     ```
  8. If you close the terminal, reactivate the environment before running Packer again.



### 2. Configure Packer Template
- Edit the Packer template in `packer/` to ensure the ISO path matches your system:
  ```json
  "iso_url": "C:/Users/ifirdaus/Downloads/rhel-9.6-x86_64-dvd.iso",
  "iso_checksum": "none"
  ```
- For the Ansible provisioner, use the absolute Windows path for the playbook file (especially when running from WSL):
  ```json
  "playbook_file": "C:/Users/ifirdaus/Documents/repo/rhel-hardening-packer-ansible/ansible/site.yml"
  ```
- Adjust any other variables as needed (e.g., VM RAM, CPUs).
  - **Note:** The `iso_checksum` field must be set to a valid checksum or to `none` (not `auto`).

### 3. Prepare Ansible Playbooks
- The `ansible/` directory contains playbooks and roles for CIS hardening.
- Review and customize variables as needed for your environment.


### 4. Build the Image


#### Option 1: Run Everything from WSL (Recommended if Ansible is only in WSL)

This method allows you to use Ansible and Packer from your WSL environment. You must ensure VirtualBox is installed on Windows and its command-line tools are accessible from WSL.

**Quick Steps:**
1. Open WSL terminal
2. Add VirtualBox to your WSL PATH:
   ```sh
   export PATH=$PATH:/mnt/c/Program\ Files/Oracle/VirtualBox
   ```
   (Add to `~/.bashrc` for persistence)
3. Install Packer and Ansible in WSL:
   ```sh
   sudo apt-get update && sudo apt-get install -y packer ansible
   ```
4. Edit `packer/template.json` to use WSL-style paths (e.g., `/mnt/c/...`)
5. Change to your project directory:
   ```sh
   cd /mnt/c/Users/ifirdaus/Documents/repo/rhel-hardening-packer-ansible
   ```
6. Run the build:
   ```sh
   packer build packer/template.json
   ```

**Detailed Step-by-step:**
1. Open your WSL terminal.
2. Ensure VirtualBox is installed on Windows. Add VirtualBox to your WSL PATH so Packer can find `VBoxManage`:
   ```sh
   export PATH=$PATH:/mnt/c/Program\ Files/Oracle/VirtualBox
   ```
   To make this permanent, add the above line to your `~/.bashrc` or `~/.zshrc` and restart your WSL terminal.
3. Install Packer in WSL if not already installed:
   ```sh
   sudo apt-get update && sudo apt-get install -y packer
   # Or download from https://developer.hashicorp.com/packer/install
   ```
4. Install Ansible in WSL:
   ```sh
   sudo apt-get install -y ansible
   # Or use pip: pip install --user ansible
   ```
5. Navigate to your project directory in WSL:
   ```sh
   cd /mnt/c/Users/ifirdaus/Documents/repo/rhel-hardening-packer-ansible
   ```
6. Edit your `packer/template.json` so all file paths use WSL/Linux style (e.g., `/mnt/c/Users/ifirdaus/...`). Example:
   ```json
   "playbook_file": "/mnt/c/Users/ifirdaus/Documents/repo/rhel-hardening-packer-ansible/ansible/site.yml"
   ```
7. Run the build:
   ```sh
   packer build packer/template.json
   ```
8. Packer will:
   - Create a VM in VirtualBox (on Windows)
   - Install RHEL 9.6 from the ISO
   - Use Ansible (from WSL) to apply CIS hardening automatically

**Troubleshooting:**
- If you see `VBoxManage: executable file not found in $PATH`, double-check your PATH export and restart your WSL terminal.
- If you see file not found errors, ensure all referenced paths in your Packer template use WSL/Linux style.
- If you see plugin errors, install the VirtualBox builder plugin in WSL:
  ```sh
  packer plugins install github.com/hashicorp/virtualbox
  ```

#### Option 2: Run Packer from Windows (Requires Ansible on Windows)

If you want to run Packer from Windows, you must also have Ansible installed and available in your Windows PATH. See the earlier section for setting up Ansible in a Python virtual environment on Windows.

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
- **If running Packer inside WSL:**
  - Use Linux/WSL-style paths (e.g., `/mnt/c/Users/...`) for files referenced in your Packer template, such as `playbook_file`.
  - Windows-style paths (e.g., `C:/Users/...`) will not work in WSL.
  - Make sure VirtualBox is installed on Windows and its directory is in your WSL PATH:
    ```sh
    export PATH=$PATH:/mnt/c/Program\ Files/Oracle/VirtualBox
    ```
  - Restart your WSL terminal after updating the PATH.
- If Ansible is not found, ensure it is installed in your WSL environment and accessible from your terminal.
- For VirtualBox networking or driver issues, consult the [VirtualBox documentation](https://www.virtualbox.org/manual/UserManual.html).

### Packer Error: `The builder virtualbox-iso is unknown by Packer`
- The VirtualBox builder plugin is not installed.
- To install it, run:
  ```sh
  packer plugins install github.com/hashicorp/virtualbox
  ```
- See the [Packer VirtualBox Integration page](https://developer.hashicorp.com/packer/integrations?filter=virtualbox).

### Packer Error: `Failed creating VirtualBox driver: exec: "VBoxManage": executable file not found in $PATH`
- Packer cannot find the VirtualBox command-line tool (`VBoxManage`).
- Add VirtualBox to your WSL PATH as described above.
- Restart your WSL terminal.
- Packer and VirtualBox must be run from the same environment (both Windows or both WSL with proper path setup).

### Packer Error: `Error running "ansible-playbook --version": exec: "ansible-playbook": executable file not found in %PATH%`
- This means Packer cannot find Ansible.
- **Solution:** Run Packer from WSL, where Ansible is installed and available in the PATH.

---

## References
- [Packer Documentation](https://developer.hashicorp.com/packer/docs)
- [Ansible Documentation](https://docs.ansible.com/)
- [CIS Benchmarks](https://www.cisecurity.org/cis-benchmarks)

---

For questions or to request enhancements, please contact the project maintainer.
