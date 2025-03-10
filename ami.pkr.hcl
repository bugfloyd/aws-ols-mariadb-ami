
variable "aws_region_main" {
  type = string
}

variable "aws_region_backup" {
  type = string
}

variable "s3_backup_bucket" {
  type = string
}

variable "s3_backup_dir" {
  type    = string
  default = "ec2-backups/ols"
}

variable "mariadb_admin_user" {
  type    = string
  default = "dbadmin"
}

variable "ols_admin_user" {
  type    = string
  default = "admin"
}


packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1"
    }
    ansible = {
      version = "~> 1"
      source  = "github.com/hashicorp/ansible"
    }
  }
}

source "amazon-ebs" "ols_mariadb" {
  region          = var.aws_region_main
  instance_type   = "t3.small"
  ssh_username    = "ubuntu"
  ami_name        = "openlitespeed-mariadb-ami-{{timestamp}}"
  ami_description = "Ubuntu 24 based API including: OpenLightSpeed, LSPHP, MariaDB"

  source_ami_filter {
    filters = {
      name                = "ubuntu-pro-server*24.04-amd64*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    owners      = ["099720109477"] # Canonical's AWS Account ID for Ubuntu
    most_recent = true
  }

  tags = {
    Name = "PackerBuilder"
  }
}

build {
  sources = ["source.amazon-ebs.ols_mariadb"]

  provisioner "ansible" {
    playbook_file = "playbook.yml"
    extra_arguments = [
      "-e", "s3_backup_bucket=${var.s3_backup_bucket}",
      "-e", "s3_backup_dir=${var.s3_backup_dir}",
      "-e", "aws_region_backup=${var.aws_region_backup}",
      "-e", "mariadb_admin_user=${var.mariadb_admin_user}",
      "-e", "ols_admin_user=${var.ols_admin_user}",
      "--scp-extra-args", "'-O'" # To resolve https://github.com/hashicorp/packer/issues/11783
    ]
  }
}
