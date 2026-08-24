
variable "aws_region" {
  type = string
}

# Which kind of image to build.
#
#   standalone - self-contained web server: OpenLiteSpeed, MariaDB, phpMyAdmin,
#                first-boot credential generation and the ols-wp-backup scripts.
#                Everything the instance needs lives on the instance.
#
#   web        - web tier only, for use behind a load balancer with shared
#                storage and a managed database. No MariaDB, no phpMyAdmin, no
#                per-instance credentials. Adds EFS and MySQL client tooling.
variable "profile" {
  type    = string
  default = "standalone"

  validation {
    condition     = contains(["standalone", "web"], var.profile)
    error_message = "Profile must be one of: standalone, web."
  }
}

variable "mariadb_admin_user" {
  type    = string
  default = "dbadmin"
}

variable "ols_admin_user" {
  type    = string
  default = "admin"
}


locals {
  # The standalone profile keeps the Ubuntu Pro base image the blog post uses.
  # The web profile takes plain Ubuntu instead: Pro carries an hourly surcharge
  # ($0.0271/hr vs $0.0236/hr for t3.small in eu-west-2) and playbook_pre.yml
  # removes the Pro client packages anyway, so nothing is given up.
  source_ami_name = (
    var.profile == "web"
    ? "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"
    : "ubuntu-pro-server*24.04-amd64*"
  )

  ami_name_prefix = var.profile == "web" ? "openlitespeed-web-ami" : "openlitespeed-mariadb-ami"

  ami_description = (
    var.profile == "web"
    ? "Ubuntu 24 web tier: OpenLiteSpeed, LSPHP, EFS and MySQL client tooling"
    : "Ubuntu 24 based API including: OpenLightSpeed, LSPHP, MariaDB"
  )

  playbook_file = var.profile == "web" ? "playbook_web.yml" : "playbook.yml"
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
  region          = var.aws_region
  instance_type   = "t3.small"
  ssh_username    = "ubuntu"
  ami_name        = "${local.ami_name_prefix}-{{timestamp}}"
  ami_description = local.ami_description

  source_ami_filter {
    filters = {
      name                = local.source_ami_name
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    owners      = ["099720109477"] # Canonical's AWS Account ID for Ubuntu
    most_recent = true
  }

  tags = {
    Name    = "OLS-Webserver"
    Profile = var.profile
  }
}

build {
  sources = ["source.amazon-ebs.ols_mariadb"]

  provisioner "ansible" {
    playbook_file = local.playbook_file
    extra_arguments = [
      "-e", "mariadb_admin_user=${var.mariadb_admin_user}",
      "-e", "ols_admin_user=${var.ols_admin_user}",
      "--scp-extra-args", "'-O'" # To resolve https://github.com/hashicorp/packer/issues/11783
    ]
  }
}
