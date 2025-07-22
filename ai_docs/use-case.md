I have a VM that has ansible installed. The VM ip is 172.17.0.18. So currently I want to execute my ansible playbook that located on windows 11. My VM is within local network. So my project is to use packer to create image for RHEL and use ansible to make the hardening. Guide me on how to achieve that and give me best practices about ansible and packer.

I also want to produce a golden image and a very secure machine image. The RHEL image needs to meet CIS hardening security standards, and the hardening process should include steps like disabling unnecessary services and configuring firewall rules. Refer to CIS benchmarks for RHEL hardening. Provide a step-by-step guide with code snippets for each part of the process. 

Currently, I don't have vmware but I do have hyper-v