# **Automating the Creation of CIS-Hardened RHEL 9 Golden Images with Packer and Ansible**

## **Architecting a Modern, Secure Image Factory**

The creation of a secure and compliant virtual machine (VM) image is not merely a configuration task; it is an industrial process. To achieve a state of consistent security and operational excellence, it is essential to move away from ad-hoc, manual configurations towards an automated, version-controlled image factory. This report details the architecture, tools, and procedures required to build a robust pipeline for generating Red Hat Enterprise Linux (RHEL) 9 "golden images" hardened to the Center for Internet Security (CIS) standards using HashiCorp Packer and Ansible.

### **The Philosophy: Immutable Infrastructure as a Security Posture**

The foundational principle of a modern image factory is **immutable infrastructure**. In this paradigm, servers are never modified after they are deployed. Instead of applying patches or configuration changes to a running system (a mutable approach), the entire server image is replaced with a new, updated version built from a controlled, automated process.1  
This philosophy offers profound security and operational advantages:

* **Elimination of Configuration Drift:** In mutable environments, manual changes, one-off scripts, and inconsistent updates lead to "configuration drift," where servers that were once identical diverge over time. This creates an unpredictable environment where security vulnerabilities can emerge unnoticed. Immutability ensures that every instance deployed from a given image version is identical.  
* **Simplified Rollbacks and Updates:** If a new image introduces a problem, rolling back is as simple as deploying the previous, known-good version. Updates are handled by building a new image, testing it, and rolling it out, rather than performing complex in-place upgrades.  
* **Enhanced Security and Compliance:** By building security controls directly into the image, compliance is established and verified *before* deployment. This "shift-left" approach to security ensures that every server starts from a hardened, known-secure state. The image creation process itself becomes a verifiable audit trail.

HashiCorp Packer is the cornerstone of this approach. It is an open-source tool designed specifically to create identical machine images for multiple platforms from a single, version-controlled source configuration file.3 It automates the entire lifecycle of image creation, from provisioning a temporary machine to installing an operating system, applying configurations, and saving the final artifact.

### **The Core Workflow: Packer and Ansible, Better Together**

The combination of Packer and Ansible provides a powerful, agentless workflow for building secure images.1 Ansible, with its simple YAML syntax and vast ecosystem of modules and roles, is perfectly suited for the configuration and hardening phase of the image build.1  
The end-to-end process for creating a CIS-hardened RHEL 9 image is as follows:

1. **Trigger:** A change is committed to the project's Git repository—for example, an update to an Ansible role variable or the Packer template itself.  
2. **CI/CD Integration:** A Continuous Integration/Continuous Deployment (CI/CD) pipeline (e.g., GitHub Actions, Jenkins) detects the change and triggers a packer build command on a dedicated build host.5  
3. **Provisioning:** Packer communicates with the target virtualization platform (e.g., VMware vSphere) and provisions a new, temporary VM from a base RHEL 9 ISO file.  
4. **Unattended OS Installation:** Packer sends a sequence of boot commands to the VM's console. These commands direct the RHEL installer (Anaconda) to fetch a Kickstart configuration file from a local HTTP server running on the build host. The Kickstart file automates the entire OS installation, including disk partitioning, package selection, and the creation of a temporary user for Ansible to connect with.7  
5. **Configuration and Hardening:** Once the OS is installed and the VM reboots, Packer's ansible provisioner establishes an SSH connection to the temporary VM using the credentials of the user created by Kickstart.9 It then executes a specified Ansible playbook. This playbook applies all the CIS hardening controls, disables unnecessary services, and configures the firewall.  
6. **Final Cleanup:** The last task in the Ansible playbook is a critical security step: it removes the temporary user account and its associated SSH key, ensuring no "backdoor" access exists in the final image.  
7. **Image Finalization:** Packer gracefully shuts down the VM. It then instructs the virtualization platform to convert the VM into a template, which becomes the "golden image."  
8. **Teardown:** Packer cleans up after itself by deleting the temporary VM and any associated build artifacts, leaving only the pristine, hardened template in the vSphere inventory.

This workflow ensures the entire process is automated, repeatable, and leaves no residual build-time artifacts on the final image.

### **Proposed Architecture: The Dedicated Build Host**

The described workflow necessitates a shift from a fragmented setup (e.g., playbooks on a Windows workstation, Ansible on a separate VM) to a centralized and more professional architecture. The recommended model is a **dedicated Linux build host**. This can be a VM or a container that houses all the necessary tools and project files.  
This architecture provides numerous benefits:

* **Centralized Dependency Management:** The build host contains the specific versions of Packer, Ansible, and any required libraries (e.g., pyvmomi for vSphere), ensuring a consistent and reproducible build environment.  
* **Simplified Networking:** The build host becomes the single point of contact with the virtualization platform's API (e.g., vCenter). This simplifies firewall rules and network configuration.  
* **Reproducibility and Version Control:** The entire project, including Packer templates, Ansible playbooks, and Kickstart files, is checked out from a Git repository onto the build host. This ensures that any build is performed from a specific, versioned state of the code.  
* **Security Isolation:** Credentials for accessing the virtualization platform are stored securely on the build host, limiting their exposure. The build process is isolated from developer workstations.

If a container-based approach is chosen, it is important to note that the official HashiCorp Packer container image often does not include Ansible. Therefore, a custom container image may need to be built that includes both Packer and Ansible to facilitate this workflow.5

## **Establishing the Build Environment & Project Structure**

With the architecture defined, the next step is to prepare the build environment and establish a logical project structure. This foundation is critical for the long-term maintainability and scalability of the image factory.

### **Preparing the Linux Build Host**

The dedicated build host should be a stable Linux distribution, such as RHEL, Rocky Linux, or AlmaLinux. The following steps outline the preparation process.

1. **Install HashiCorp Packer:** Follow the official HashiCorp instructions to download and install the Packer binary. It is typically placed in /usr/local/bin.10  
2. **Install Ansible and Dependencies:** Use the system's package manager to install a recent version of Ansible and the necessary Python libraries for interacting with VMware vSphere.  
   Bash  
   \# For RHEL/Rocky/Alma 9  
   sudo dnf install \-y ansible-core python3-pip  
   sudo pip3 install pyvmomi

   It is crucial to use a modern version of ansible-core (e.g., 2.13 or newer) as many community and official roles require features available only in recent releases.11

### **A Professional Project Structure**

A well-organized directory structure is a form of "configuration as code" for the automation process itself. It makes the project self-documenting, separates concerns, and simplifies maintenance.13 The following structure is recommended for this project:

rhel9-cis-image-factory/  
├── ansible.cfg                 \# Ansible configuration file  
├── packer/                     \# All Packer-related files  
│   ├── rhel9-cis.pkr.hcl       \# Main Packer template for RHEL 9  
│   ├── variables.pkr.hcl       \# Packer variable definitions  
│   └── secrets.pkrvars.hcl     \# Secret variables (add to.gitignore)  
├── http/                       \# Local web server root for Kickstart  
│   └── ks.cfg                  \# RHEL 9 Kickstart configuration file  
├── ansible/                    \# All Ansible-related files  
│   ├── inventory/              \# Static inventory (not used by Packer)  
│   ├── group\_vars/  
│   │   └── all/  
│   │       ├── cis\_settings.yml \# Customizations for the CIS role  
│   │       └── vault.yml       \# Encrypted secrets for Ansible  
│   ├── roles/                  \# Downloaded Ansible roles (via ansible-galaxy)  
│   └── hardening.yml           \# The main playbook Packer will execute  
└── README.md                   \# Project documentation

This structure cleanly separates the image definition (packer/) from the configuration logic (ansible/). It centralizes configuration overrides in group\_vars/ and provides clear locations for securing secrets used by both Packer (secrets.pkrvars.hcl) and Ansible (vault.yml).13

### **Configuring Ansible (ansible.cfg)**

An ansible.cfg file in the project's root directory provides local configuration settings for Ansible, overriding system-wide defaults.

Ini, TOML

\# ansible.cfg  
\[defaults\]  
inventory      \=./ansible/inventory  
roles\_path     \=./ansible/roles  
retry\_files\_enabled \= False  
host\_key\_checking \= False

\[ssh\_connection\]  
pipelining \= True

**Key Settings Explained:**

* roles\_path: Tells Ansible where to find roles downloaded by ansible-galaxy.  
* host\_key\_checking \= False: This is a critical setting for Packer integration. During a build, Packer creates a new VM with a new, unknown SSH host key on every run. Disabling host key checking allows Ansible to connect without manual intervention. This is considered safe in this specific, ephemeral context because the connection is made to a temporary machine on a trusted local network that exists only for the duration of the build.  
* pipelining \= True: This is an optimization that reduces the number of SSH connections required to execute a module, speeding up playbook execution.

## **Building the Base: The Packer RHEL 9 Template**

The core of the image creation process is the Packer template. This file, written in HashiCorp Configuration Language (HCL), defines every step of the build.

### **Anatomy of a Packer HCL Template**

A Packer template is composed of several key blocks 3:

* packer {}: Defines the required Packer version and any necessary plugins.  
* variable {}: Declares input variables, allowing for parameterization of the build.  
* locals {}: Defines local variables for use within the template, often for constructing complex values from other variables.  
* source {}: The "builder" block. This defines *what* to build and *where*. For this project, the source will be vsphere-iso, which builds a VM in vSphere from an ISO file.  
* build {}: The main execution block. It references one or more sources and defines the sequence of provisioner and post-processor blocks to run.

### **Parameterization with Variables (variables.pkr.hcl)**

Hardcoding values like passwords or server names directly into the main template is a poor practice. Variables make templates reusable and secure.2  
First, define the variables in packer/variables.pkr.hcl:

Terraform

// packer/variables.pkr.hcl

variable "vsphere\_server" {  
  type    \= string  
  default \= "vcenter.corp.local"  
}

variable "vsphere\_user" {  
  type    \= string  
  default \= "packer-svc@vsphere.local"  
}

variable "vsphere\_password" {  
  type      \= string  
  sensitive \= true // Hides the value in Packer logs  
}

variable "vsphere\_datacenter" {  
  type    \= string  
  default \= "Datacenter1"  
}

//... other variables for cluster, datastore, network, etc.

variable "iso\_path" {  
  type    \= string  
  default \= "\[datastore1\] ISOs/rhel-9.4-x86\_64-dvd.iso"  
}

variable "vm\_name" {  
  type    \= string  
  default \= "rhel9-cis-template"  
}

Next, place sensitive values in a separate file, packer/secrets.pkrvars.hcl, and ensure this file is added to your .gitignore file to prevent it from being committed to version control.

Terraform

\# packer/secrets.pkrvars.hcl  
vsphere\_password \= "YourSuperSecretPassword"

This file is then loaded at build time using the \-var-file flag: packer build \-var-file=packer/secrets.pkrvars.hcl.

### **The vsphere-iso Builder in Detail**

The source block defines how Packer will build the initial VM. The following is an annotated example for the vsphere-iso builder, drawing on common configurations.15

Terraform

\# packer/rhel9-cis.pkr.hcl

source "vsphere-iso" "rhel9" {  
  \# \--- vSphere Connection \---  
  vcenter\_server      \= var.vsphere\_server  
  username            \= var.vsphere\_user  
  password            \= var.vsphere\_password  
  insecure\_connection \= true // Use false if vCenter has a valid, trusted cert

  \# \--- vSphere Inventory Location \---  
  datacenter          \= var.vsphere\_datacenter  
  cluster             \= var.vsphere\_cluster  
  datastore           \= var.vsphere\_datastore  
  folder              \= var.vsphere\_vm\_folder

  \# \--- VM Hardware Configuration \---  
  guest\_os\_type       \= "rhel9\_64Guest"  
  vm\_name             \= var.vm\_name  
  CPUs                \= 2  
  RAM                 \= 4096 // in MB  
  disk\_controller\_type \= \["pvscsi"\]  
  storage {  
    disk\_size             \= 40960 // in MB  
    disk\_thin\_provisioned \= true  
  }  
  network\_adapters {  
    network      \= var.vsphere\_network  
    network\_card \= "vmxnet3"  
  }

  \# \--- Installation Media \---  
  iso\_paths \= \[  
    var.iso\_path  
  \]

  \# \--- Unattended Installation \---  
  http\_directory      \= "http"  
  boot\_wait           \= "5s"  
  boot\_command \=

  \# \--- Connection for Provisioners \---  
  ssh\_username        \= "packer"  
  ssh\_password        \= var.packer\_user\_password  
  ssh\_timeout         \= "30m"

  \# \--- Final Image \---  
  convert\_to\_template \= true  
}

The boot\_command is the mechanism that enables a fully unattended installation. It simulates keyboard presses at the bootloader prompt to append the inst.ks kernel argument. Packer automatically starts a temporary HTTP server serving files from the http\_directory and substitutes the {{.HTTPIP }} and {{.HTTPPort }} variables, pointing the installer to the Kickstart file.15

### **Automating Installation with Kickstart (http/ks.cfg)**

The Kickstart file is the blueprint for the RHEL installation. It automates every step, from partitioning to user creation, ensuring a consistent base system for Ansible to configure. A robust Kickstart file is essential for true automation.7

Code snippet

\# http/ks.cfg

\# Use graphical install  
graphical

\# System language  
lang en\_US.UTF-8

\# Keyboard layouts  
keyboard \--vckeymap=us \--xlayouts='us'

\# Network information  
network \--bootproto=dhcp \--device=link \--activate  
network \--hostname=localhost.localdomain

\# Root password (locked by default, will be managed by Ansible)  
rootpw \--iscrypted \--lock \*

\# Firewall configuration (will be managed by Ansible)  
firewall \--disabled

\# System services (will be managed by Ansible)  
services \--enabled="sshd"

\# Do not configure the X Window System  
skipx

\# System timezone  
timezone America/New\_York \--isUtc

\# System bootloader configuration  
bootloader \--location=mbr \--boot-drive=sda

\# Partition clearing information  
clearpart \--all \--initlabel  
\# Disk partitioning information  
part /boot \--fstype="xfs" \--ondisk=sda \--size=1024  
part pv.01 \--fstype="lvmpv" \--ondisk=sda \--size=1 \--grow  
volgroup rhel \--pesize=4096 pv.01  
logvol / \--fstype="xfs" \--name=root \--vgname=rhel \--size=1 \--grow

%packages \--ignoremissing \--excludedocs \--nobase  
@^server-product-environment  
cloud-init  
\# Minimal packages for base system and tools  
\-fprintd-pam  
\-intltool  
%end

%post \--log=/root/ks-post.log  
\# Create the temporary packer user for Ansible  
/usr/sbin/useradd packer \-c "Packer User"  
\# Set a temporary password for the packer user  
echo "YourTempPassword" | /usr/bin/passwd \--stdin packer  
\# Grant passwordless sudo to the packer user  
echo "packer ALL=(ALL) NOPASSWD: ALL" \> /etc/sudoers.d/packer  
chmod 0440 /etc/sudoers.d/packer  
%end

\# Reboot after installation  
reboot

This Kickstart file performs several critical functions:

* It sets up a minimal LVM-based partitioning scheme.  
* It installs a minimal set of packages (@^server-product-environment) suitable for a server.  
* The %post section is the most important part. It runs after the package installation is complete and creates the packer user, sets its password, and configures passwordless sudo. This prepares the system for the Ansible provisioner to connect and take over configuration.

### **The Ansible Provisioner (provisioner "ansible")**

The choice between Packer's ansible and ansible-local provisioners is a key architectural decision. The ansible-local provisioner requires installing Ansible on the target machine, which increases the image's size and attack surface.1 The  
ansible provisioner, which runs Ansible from the build host and connects via SSH, is the superior choice for creating minimal, secure golden images.9  
The provisioner block is added to the build section of the Packer template.

Terraform

\# packer/rhel9-cis.pkr.hcl

build {  
  sources \= \["source.vsphere-iso.rhel9"\]

  provisioner "ansible" {  
    playbook\_file    \= "../ansible/hardening.yml"  
    user             \= "packer" // The temporary user created by Kickstart  
    extra\_arguments  \= \["--vault-password-file", "../.vault\_pass"\] // Example for vault  
    ansible\_env\_vars \=  
  }

  \#... other provisioners or post-processors...  
}

This block instructs Packer to run the hardening.yml playbook located in the ansible/ directory, connecting as the packer user.

## **The Heart of Hardening: The Ansible CIS Playbook**

With the base image built, the focus shifts to configuration and security hardening using Ansible. Manually implementing hundreds of CIS controls is an error-prone and unsustainable task. The most effective and maintainable approach is to leverage a pre-existing, community-vetted Ansible role designed specifically for this purpose.

### **The Power of Roles: Don't Reinvent the Security Wheel**

The Ansible community has produced several high-quality roles for implementing CIS benchmarks. These roles encapsulate the collective expertise of security professionals and are regularly updated to align with new benchmark versions. Using such a role saves immense development time and results in a more robust and accurate implementation.12  
Two prominent roles for RHEL 9 CIS hardening are:

* ansible-lockdown/RHEL9-CIS: A community-driven, highly configurable role focused on remediation and providing a built-in auditing mechanism.12  
* RedHatOfficial/rhel9-cis: A role generated from OpenSCAP security content, reflecting Red Hat's official interpretation of the benchmark.18

This guide will focus on the ansible-lockdown/RHEL9-CIS role due to its excellent documentation, granular control via variables, and its powerful, lightweight auditing feature.

### **Comparison of RHEL 9 CIS Ansible Roles**

The following table provides a comparison to aid in selecting the appropriate role for a given environment.

| Feature | ansible-lockdown/RHEL9-CIS | RedHatOfficial/rhel9-cis | Notes |
| :---- | :---- | :---- | :---- |
| **Maintainer** | Ansible Lockdown Community | Red Hat Official | Community-driven vs. Vendor-supported. |
| **Primary Source** | Manual interpretation of CIS PDF | Generated from OpenSCAP content 19 | The Lockdown role may offer more pragmatic interpretations. |
| **Configurability** | Highly configurable via variables in defaults/main.yml 12 | Configurable via variables, but may be less granular. | The Lockdown role is explicitly designed for easy overrides. |
| **Auditing Method** | Built-in audit mode using goss binary 12 | Relies on external OpenSCAP scans for auditing.17 | goss provides a very fast, lightweight, in-playbook audit capability. |
| **Check Mode Support** | Not officially supported; audit mode is preferred.12 | Supported. | The role's complexity makes true check mode difficult. |
| **Community/Support** | Active Discord server and GitHub community.12 | Supported as part of Red Hat's ecosystem. |  |

### **Implementing the ansible-lockdown/RHEL9-CIS Role**

1. **Install the Role:** Use ansible-galaxy to install the role and its dependencies into the project's ansible/roles/ directory.  
   Bash  
   \# Run from the project root directory  
   ansible-galaxy role install \-p ansible/roles ansible-lockdown.RHEL9-CIS

2. **Create the Main Playbook (hardening.yml):** This playbook is the entry point that Packer will call. It includes the CIS role and a final cleanup play.  
   YAML  
   \# ansible/hardening.yml  
   \- name: Harden RHEL 9 Server to CIS Benchmark  
     hosts: all  
     become: true  
     gather\_facts: true

     roles:  
       \- role: ansible-lockdown.RHEL9-CIS  
         tags:  
           \- level2-server \# Apply Level 2 controls for servers

   \- name: Final Image Cleanup  
     hosts: all  
     become: true  
     gather\_facts: false

     tasks:  
       \- name: Remove the temporary packer user  
         ansible.builtin.user:  
           name: packer  
           state: absent  
           remove: true \# Also removes the user's home directory

       \- name: Remove the packer sudoers file  
         ansible.builtin.file:  
           path: /etc/sudoers.d/packer  
           state: absent

   Using the level2-server tag ensures that the most stringent set of server-focused security controls from the benchmark is applied.12 The final play is a critical security measure to ensure the temporary build user is completely removed from the final image.

### **Customization and Control with group\_vars**

All customizations to the hardening role should be done by overriding its default variables in the ansible/group\_vars/all/cis\_settings.yml file. **Never modify the role's files directly**, as this makes updates difficult and breaks the principle of reusable components.12  
For example, the CIS benchmark recommends disabling numerous services. If a specific service like cockpit is required for web-based administration, its removal can be prevented by overriding the relevant variable:

YAML

\# ansible/group\_vars/all/cis\_settings.yml

\# CIS Rule 2.1.1 recommends disabling many services.  
\# By default, the role provides a list of services to disable.  
\# We override that list here, commenting out 'cockpit' to keep it enabled.  
rhel9cis\_rule\_2\_1\_1\_services\_disabled:  
  \- autofs  
  \- avahi-daemon  
  \# \- cockpit  
  \- cups  
  \- dhcpd  
  \- dnsmasq  
  \#... and so on for other services from the role's default list

### **Securing Secrets with Ansible Vault**

Any sensitive data required by Ansible, such as passwords or API keys, must be encrypted using Ansible Vault.14

1. **Create an Encrypted Vault File:**  
   Bash  
   \# This will prompt for a vault password  
   ansible-vault create ansible/group\_vars/all/vault.yml

   Add sensitive variables to this file, for example: db\_password: "MySecretDBPassword".  
2. **Provide the Vault Password to Packer:** The vault password must be supplied when Packer runs Ansible. This can be done by storing the password in a file (e.g., .vault\_pass in the project root, added to .gitignore) and referencing it in the Packer provisioner's extra\_arguments.9

## **Deep Dive: Critical Hardening Tasks**

This section examines the specific hardening areas mentioned in the initial query—disabling services and configuring the firewall—to illustrate how the CIS Ansible role manages them.

### **Disabling Non-Essential Services**

Minimizing the system's attack surface by disabling all non-essential services is a core tenet of system hardening.21 The  
ansible-lockdown role automates this by iterating through a list of services defined in a variable and ensuring they are stopped and disabled using the ansible.builtin.service module.23 As demonstrated in section 4.4, administrators can precisely control which services are disabled by overriding the  
rhel9cis\_rule\_2\_1\_1\_services\_disabled variable in their group\_vars file. This provides a declarative and auditable method for managing the system's running processes.

### **Configuring a firewalld Bastion**

The CIS benchmark for RHEL 9 specifies a robust configuration for the host-based firewall, firewalld.21 Key requirements include:

* A default policy of DROP or REJECT for incoming traffic.  
* Explicit rules to allow traffic only for necessary services (e.g., SSH).  
* Correct configuration of network zones and loopback traffic.

The ansible-lockdown role implements these controls automatically. For a deeper understanding, the following tasks illustrate how one could manually configure firewalld using the ansible.posix.firewalld module, reflecting the logic within the role 23:

YAML

\- name: "CIS 4.2.2.3 | Ensure default deny firewall policy"  
  ansible.posix.firewalld:  
    zone: public  
    target: DROP  
    permanent: true  
    state: enabled  
  notify: Reload firewalld

\- name: "CIS 4.2.2.5 | Ensure loopback traffic is configured"  
  ansible.posix.firewalld:  
    zone: trusted  
    interface: lo  
    permanent: true  
    state: enabled  
  notify: Reload firewalld

\- name: "Allow required services (SSH)"  
  ansible.posix.firewalld:  
    service: "ssh"  
    permanent: true  
    state: enabled  
    immediate: yes \# Apply immediately without needing the handler

This declarative approach ensures the firewall state is consistently enforced every time the playbook is run.

### **Overview of CIS RHEL 9 Benchmark Control Families**

The CIS benchmark is a comprehensive document covering nearly every aspect of the operating system. To provide context for the hundreds of tasks being executed by the Ansible role, the following table summarizes the main control families.21

| Section | Control Family | Description | Key Examples |
| :---- | :---- | :---- | :---- |
| **1** | **Initial Setup** | Fundamental configurations affecting the entire system, including filesystem, packages, and boot settings. | Disabling unused filesystem modules, configuring separate partitions for /tmp and /var, setting bootloader passwords, enabling SELinux. |
| **2** | **Services** | Managing inetd, standalone system services, and time synchronization. | Disabling unnecessary network daemons (FTP, Telnet), configuring chrony for time sync, restricting cron and at access. |
| **3** | **Network** | Securing network parameters and host settings. | Disabling IP forwarding, ignoring ICMP broadcasts, enabling TCP SYN cookies and reverse path filtering. |
| **4** | **Host Based Firewall** | Configuring firewalld or nftables for host-level network protection. | Setting a default-deny policy, allowing only essential services, configuring loopback traffic. |
| **5** | **Access Control** | Configuring SSH, sudo, PAM, and user account policies. | Hardening SSHD configuration, setting password complexity and history rules, configuring account lockout policies, setting default umask. |
| **6** | **Logging and Auditing** | Configuring auditd, rsyslog, and file integrity checking with AIDE. | Enabling auditd rules to monitor privileged actions, configuring log forwarding, setting up AIDE for integrity checks. |
| **7** | **System Maintenance** | Setting permissions on critical system files and ensuring user/group integrity. | Securing permissions on /etc/passwd and /etc/shadow, finding and removing world-writable files, reviewing SUID/SGID files. |

## **Execution, Verification, and Iteration**

Building the image is only the first step. A mature process includes robust execution, verification of compliance, and a tight feedback loop for continuous improvement.

### **Running the Full Pipeline**

With all the configuration files in place, the end-to-end build can be executed from the root of the project directory on the build host with the following sequence of commands:

1. **Clone the Project Repository:**  
   Bash  
   git clone https://your-git-server/your-repo/rhel9-cis-image-factory.git  
   cd rhel9-cis-image-factory

2. **Install Ansible Roles:**  
   Bash  
   ansible-galaxy role install \-p ansible/roles ansible-lockdown.RHEL9-CIS

3. **Start the Local HTTP Server for Kickstart:**  
   Bash  
   \# Open a new terminal or run in the background  
   python3 \-m http.server \--directory http 8080 &

4. **Execute the Packer Build:**  
   Bash  
   \# Ensure you have a.vault\_pass file or use \--ask-vault-pass  
   packer build \-var-file=packer/secrets.pkrvars.hcl packer/rhel9-cis.pkr.hcl

   Packer will now begin the automated build process, providing detailed output at each stage. Upon successful completion, a new VM template named rhel9-cis-template will be available in vSphere.

### **Verifying Compliance: Trust but Verify**

A secure process demands verification. Simply running a hardening playbook is not enough; it is essential to confirm that the resulting image is truly compliant. The ansible-lockdown/RHEL9-CIS role provides a powerful, built-in auditing capability using a lightweight Go binary named goss.12  
To run an audit, the run\_audit variable is set to true and the playbook is executed with the audit tag.

1. **Modify group\_vars for Auditing:**  
   YAML  
   \# ansible/group\_vars/all/cis\_settings.yml  
   run\_audit: true

2. **Run the Playbook in Audit Mode:**  
   Bash  
   \# This command would be run by a provisioner in a separate Packer build  
   \# or on a running instance for verification.  
   ansible-playbook ansible/hardening.yml \--tags "audit"

This will produce a detailed report showing which controls are passing and which are failing, providing a fast and efficient way to validate the security posture of the image without relying on external scanning tools. Alternatively, tools like OpenSCAP can be used for more in-depth analysis against the official security content.17

### **The Feedback Loop: The Image as Code**

The entire collection of Packer templates and Ansible playbooks in Git represents the "source code" for the golden image. This enables a powerful, iterative development cycle:

* A new security requirement emerges (e.g., a new port needs to be opened).  
* A developer modifies the relevant Ansible variable in group\_vars.  
* The change is committed to Git, triggering the CI/CD pipeline.  
* A new, versioned, fully hardened, and verified golden image is automatically produced.

This "Image as Code" approach transforms system administration from a manual, reactive task into a programmatic, proactive discipline.

## **Advanced Concepts and Best Practices Summary**

To further mature the image factory, several advanced concepts and best practices should be considered.

### **Integrating with CI/CD**

Automating the execution step via a CI/CD pipeline is the final step in creating a true, hands-off image factory. The following is a conceptual example of a GitHub Actions workflow that triggers on a push to the main branch.5

YAML

\#.github/workflows/packer-build.yml  
name: Build RHEL9 CIS Golden Image

on:  
  push:  
    branches: \[ main \]

jobs:  
  build:  
    runs-on: ubuntu-latest  
    steps:  
    \- name: Checkout repository  
      uses: actions/checkout@v4

    \- name: Set up Packer  
      uses: hashicorp/setup-packer@main  
      with:  
        version: 'latest'

    \- name: Install Ansible  
      run: |  
        sudo apt-get update  
        sudo apt-get install \-y ansible python3-pip  
        pip3 install pyvmomi

    \- name: Build Image  
      run: |  
        packer build \\  
          \-var "vsphere\_password=${{ secrets.VSPHERE\_PASSWORD }}" \\  
          \-var-file=packer/variables.pkr.hcl \\  
          packer/rhel9-cis.pkr.hcl  
      env:  
        PACKER\_LOG: 1

### **Image Lifecycle Management**

Once an image is built, its entire lifecycle should be managed. This includes:

* **Storage:** Storing the final templates in a centralized, versioned repository like the vSphere Content Library.  
* **Discovery:** Using a registry like HCP Packer allows other automation tools, such as Terraform, to easily discover and consume the latest version of a golden image for deployments.5  
* **Deprecation:** Establishing policies for deprecating and retiring old, insecure image versions.

### **Packer & Ansible Security Best Practices Summary**

The following table consolidates the key security best practices discussed throughout this report.

| Category | Best Practice | Rationale |
| :---- | :---- | :---- |
| **Secret Management** | Use Ansible Vault and Packer sensitive variables. Store secrets in separate, .gitignore'd files.2 | Prevents hardcoding credentials in version control, reducing risk of exposure. |
| **Idempotency** | Ensure all Ansible tasks are idempotent. Use modules that inherently manage state.13 | Prevents unintended changes on subsequent runs and ensures a consistent final state. |
| **Principle of Least Privilege** | Use a temporary, unprivileged user for the build process. Grant sudo only for the duration of the build and remove the user in the final step.20 | Minimizes the attack surface on the final image. The build-time user should not exist in production. |
| **Version Control** | Store all Packer, Ansible, and Kickstart files in a Git repository.2 | Provides a full audit trail of all changes to the image's "source code" and enables automated CI/CD. |
| **Modularity** | Use Ansible roles for complex tasks like CIS hardening. Do not reinvent the wheel.13 | Leverages community expertise, improves maintainability, and separates logic from execution. |
| **Verification** | Do not assume a build is compliant. Use auditing tools (goss, OpenSCAP) to verify the image against the security baseline.12 | "Trust but verify" is a core security principle. Auditing provides proof of compliance. |

### **Ansible Project Best Practices Summary**

Adhering to established project conventions improves the quality, readability, and maintainability of automation code.

| Area | Best Practice | Why It Matters |
| :---- | :---- | :---- |
| **Directory Structure** | Use a standardized, hierarchical layout that separates concerns (e.g., Packer, Ansible, roles, vars).13 | Makes the project easy to navigate, understand, and scale. |
| **Roles** | Encapsulate all complex logic within roles. Keep playbooks simple, primarily as a list of roles to execute.13 | Promotes reusability, modularity, and testability. |
| **Variables** | Define variables in group\_vars and host\_vars. Override role defaults in group\_vars, not in the role itself.14 | Centralizes configuration and makes it easy to manage settings for different environments without altering code. |
| **Playbooks** | Keep playbooks concise. Their purpose is to map roles to hosts.13 | Improves clarity and focuses the playbook on orchestration rather than implementation. |
| **Naming Conventions** | Use consistent, descriptive names for variables, tasks, and files. Prefix role variables with the role name.13 | Reduces ambiguity, prevents variable collisions, and makes the code self-documenting. |
| **Version Control** | Commit frequently with clear messages. Use tags for releases.27 | Creates a clear history of changes, simplifies collaboration, and enables reliable rollbacks. |

By adopting these principles and practices, an organization can move from manual system configuration to a fully automated, secure, and efficient image factory, producing compliant RHEL 9 golden images on demand.

#### **Works cited**

1. Using Packer and Ansible to Build Immutable Infrastructure \- CloudBees, accessed July 21, 2025, [https://www.cloudbees.com/blog/packer-ansible](https://www.cloudbees.com/blog/packer-ansible)  
2. Mastering Packer: A Comprehensive Guide to Automated Machine Image Creation | by Warley's CatOps | Medium, accessed July 21, 2025, [https://medium.com/@williamwarley/mastering-packer-a-comprehensive-guide-to-automated-machine-image-creation-61cd7d8ac9ed](https://medium.com/@williamwarley/mastering-packer-a-comprehensive-guide-to-automated-machine-image-creation-61cd7d8ac9ed)  
3. Migrating from HashiCorp Packer to EC2 Image Builder | AWS Cloud Operations Blog, accessed July 21, 2025, [https://aws.amazon.com/blogs/mt/migrating-from-hashicorp-packer-to-ec2-image-builder/](https://aws.amazon.com/blogs/mt/migrating-from-hashicorp-packer-to-ec2-image-builder/)  
4. Using Ansible and Packer, From Provisioning to Orchestration \- Red Hat, accessed July 21, 2025, [https://www.redhat.com/en/blog/ansible-and-packer-why-they-are-better-together](https://www.redhat.com/en/blog/ansible-and-packer-why-they-are-better-together)  
5. Using Hashicorp Cloud, Packer, Ansible, GCP, and Github Actions to create machine images | by Anderson Dario | DevOps.dev, accessed July 21, 2025, [https://blog.devops.dev/using-hashicorp-cloud-packer-ansible-gcp-and-github-actions-to-create-machine-images-f70f77ecb93d](https://blog.devops.dev/using-hashicorp-cloud-packer-ansible-gcp-and-github-actions-to-create-machine-images-f70f77ecb93d)  
6. Build Images in CI/CD | Packer \- HashiCorp Developer, accessed July 21, 2025, [https://developer.hashicorp.com/packer/guides/packer-on-cicd/build-image-in-cicd](https://developer.hashicorp.com/packer/guides/packer-on-cicd/build-image-in-cicd)  
7. Can the Ansible Nutanix collection install a rhel9.iso with a kickstart file? \- Reddit, accessed July 21, 2025, [https://www.reddit.com/r/ansible/comments/1juv314/can\_the\_ansible\_nutanix\_collection\_install\_a/](https://www.reddit.com/r/ansible/comments/1juv314/can_the_ansible_nutanix_collection_install_a/)  
8. Explain provisioner ansible please \- Packer \- HashiCorp Discuss, accessed July 21, 2025, [https://discuss.hashicorp.com/t/explain-provisioner-ansible-please/60941](https://discuss.hashicorp.com/t/explain-provisioner-ansible-please/60941)  
9. Ansible Provisioner | Integrations | Packer \- HashiCorp Developer, accessed July 21, 2025, [https://developer.hashicorp.com/packer/integrations/hashicorp/ansible/latest/components/provisioner/ansible](https://developer.hashicorp.com/packer/integrations/hashicorp/ansible/latest/components/provisioner/ansible)  
10. Building Docker image with Packer and provisioning with Ansible \- GitHub Gist, accessed July 21, 2025, [https://gist.github.com/maxivak/2d014f591fc8b7c39d484ac8d17f2a55](https://gist.github.com/maxivak/2d014f591fc8b7c39d484ac8d17f2a55)  
11. hasnimehdi91.cis\_hardening \- Ansible Galaxy, accessed July 21, 2025, [https://galaxy.ansible.com/ui/repo/published/hasnimehdi91/cis\_hardening/](https://galaxy.ansible.com/ui/repo/published/hasnimehdi91/cis_hardening/)  
12. ansible-lockdown/RHEL9-CIS: Automated CIS Benchmark ... \- GitHub, accessed July 21, 2025, [https://github.com/ansible-lockdown/RHEL9-CIS](https://github.com/ansible-lockdown/RHEL9-CIS)  
13. Good Practices for Ansible \- GPA \- Red Hat Communities of Practice, accessed July 21, 2025, [https://redhat-cop.github.io/automation-good-practices/](https://redhat-cop.github.io/automation-good-practices/)  
14. Ansible Best Practices and Examples | by Amareswer \- Medium, accessed July 21, 2025, [https://medium.com/@amareswer/ansible-best-practices-and-examples-72893d8b19be](https://medium.com/@amareswer/ansible-best-practices-and-examples-72893d8b19be)  
15. Ansible Packer Role for VM/ISO Image Creation \- GitHub, accessed July 21, 2025, [https://github.com/myllynen/ansible-packer](https://github.com/myllynen/ansible-packer)  
16. vmware/packer-examples-for-vsphere: Packer Examples ... \- GitHub, accessed July 21, 2025, [https://github.com/vmware/packer-examples-for-vsphere](https://github.com/vmware/packer-examples-for-vsphere)  
17. High automation coverage for Center for Information Security in Red Hat Enterprise Linux 9, accessed July 21, 2025, [https://www.redhat.com/en/blog/high-automation-coverage-cis-rhel-9](https://www.redhat.com/en/blog/high-automation-coverage-cis-rhel-9)  
18. RedHatOfficial.rhel9-cis \- Ansible Galaxy, accessed July 21, 2025, [https://galaxy.ansible.com/ui/standalone/roles/RedHatOfficial/rhel9-cis/](https://galaxy.ansible.com/ui/standalone/roles/RedHatOfficial/rhel9-cis/)  
19. RedHatOfficial/ansible-role-rhel9-cis: CIS Red Hat ... \- GitHub, accessed July 21, 2025, [https://github.com/RedHatOfficial/ansible-role-rhel9-cis](https://github.com/RedHatOfficial/ansible-role-rhel9-cis)  
20. Ansible Security Best Practices \- IPSpecialist, accessed July 21, 2025, [https://ipspecialist.net/ansible-security-best-practices/](https://ipspecialist.net/ansible-security-best-practices/)  
21. CIS Red Hat Enterprise Linux 9 Benchmark \- RayaSec, accessed July 21, 2025, [https://rayasec.com/wp-content/uploads/CIS-Benchmark/Red-Hat-Enterprise-Linux/CIS\_Red\_Hat\_Enterprise\_Linux\_9\_Benchmark\_v2.0.0.pdf](https://rayasec.com/wp-content/uploads/CIS-Benchmark/Red-Hat-Enterprise-Linux/CIS_Red_Hat_Enterprise_Linux_9_Benchmark_v2.0.0.pdf)  
22. dbernaci/CIS-Debian10-Ansible: Ansible role for Debian 10 CIS hardening \- GitHub, accessed July 21, 2025, [https://github.com/dbernaci/CIS-Debian10-Ansible](https://github.com/dbernaci/CIS-Debian10-Ansible)  
23. 5 ways to harden your Linux server with Ansible \- Red Hat, accessed July 21, 2025, [https://www.redhat.com/en/blog/ansible-linux-server-security](https://www.redhat.com/en/blog/ansible-linux-server-security)  
24. ansible.posix.firewalld module – Manage arbitrary ports/services with firewalld, accessed July 21, 2025, [https://docs.ansible.com/ansible/latest/collections/ansible/posix/firewalld\_module.html](https://docs.ansible.com/ansible/latest/collections/ansible/posix/firewalld_module.html)  
25. Guide to the Secure Configuration of Red Hat Enterprise Linux 9 \- Static OpenSCAP, accessed July 21, 2025, [https://static.open-scap.org/ssg-guides/ssg-rhel9-guide-cis.html](https://static.open-scap.org/ssg-guides/ssg-rhel9-guide-cis.html)  
26. Track your VM Templates in VMware vSphere with HCP Packer | by Stéphane Este-Gracias, accessed July 21, 2025, [https://sestegra.medium.com/track-your-vm-templates-in-vmware-vsphere-with-hcp-packer-11524ed465d6](https://sestegra.medium.com/track-your-vm-templates-in-vmware-vsphere-with-hcp-packer-11524ed465d6)  
27. Best Practices \- Ansible Documentation, accessed July 21, 2025, [https://docs.ansible.com/ansible/2.8/user\_guide/playbooks\_best\_practices.html](https://docs.ansible.com/ansible/2.8/user_guide/playbooks_best_practices.html)  
28. 50 Ansible Best Practices to Follow \[Tips & Tricks\] \- Spacelift, accessed July 21, 2025, [https://spacelift.io/blog/ansible-best-practices](https://spacelift.io/blog/ansible-best-practices)