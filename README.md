# AWS AMI for Web Server

This project creates an Amazon Machine Image (AMI) for a web server instance, pre-configured with OpenLiteSpeed, MariaDB, PHP, and backup automation. The AMI can be used later to launch identical web server instances on AWS.

## Features

- **Ubuntu 24-based web server** with OpenLiteSpeed, LSPHP, and MariaDB.
- **Automated provisioning** using Packer and Ansible.
- **Automated backups** to an S3 bucket.
- **Security configurations**, including a firewall and database hardening.
- **Pre-installed phpMyAdmin** for database management.

## Prerequisites

- AWS account with necessary permissions.
- Packer installed ([Download Packer](https://developer.hashicorp.com/packer/downloads)).
- AWS CLI installed and configured.
- Ansible installed on your local machine.

## Variables

This project uses the following variables, defined in `variables.pkrvars.hcl`:

| Variable            | Description                                                  |
| ------------------- | ------------------------------------------------------------ |
| `aws_region_main`   | Primary AWS region for building the AMI.                     |
| `aws_region_backup` | Secondary AWS region for backup storage.                     |
| `s3_backup_bucket`  | S3 bucket name for backups.                                  |
| `s3_backup_dir`     | Directory inside the S3 bucket (default: `ec2-backups/ols`). |

Example `variables.pkrvars.hcl` file:

```hcl
aws_region_main = "eu-west-1"
aws_region_backup = "eu-central-1"
s3_backup_bucket = "backups.bucket"
```

## Usage

### 1. Initialize Packer

Run the following command to initialize Packer:

```sh
packer init ami.pkr.hcl
```

### 2. Validate Configuration

Validate the configuration to ensure correctness:

```sh
packer validate -var-file=variables.pkrvars.hcl ami.pkr.hcl
```

### 3. Build the AMI

Build the AMI using Packer:

```sh
packer build -var-file=variables.pkrvars.hcl ami.pkr.hcl
```

## Architecture

### **Packer Configuration (`aws-ami.pkr.hcl`)**

- Uses `amazon-ebs` builder to create an AMI.
- Fetches the latest Ubuntu 24 AMI.
- Uses Ansible for provisioning.
- Tags the AMI with metadata.

### **Ansible Playbooks**

| Playbook                  | Purpose                                                 |
| ------------------------- | ------------------------------------------------------- |
| `playbook_pre.yml`        | Pre-setup tasks (e.g., package updates).                |
| `playbook_webserver.yml`  | Installs OpenLiteSpeed, PHP, and dependencies.          |
| `playbook_db.yml`         | Installs MariaDB and secures database access.           |
| `playbook_phpmyadmin.yml` | Installs and configures phpMyAdmin.                     |
| `playbook_firewall.yml`   | Sets up firewall rules.                                 |
| `playbook_init.yml`       | Setup OpenLiteSpeed & MariaDB first-boot initialization |
| `playbook_post.yml`       | Cleans up temporary files.                              |
| `backup/playbook.yml`     | Backup/Restore script installed through git submodules  |
