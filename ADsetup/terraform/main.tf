terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.4"
    }
  }

  required_version = ">= 1.2.0"
}

variable "aws_region" {
  type    = string
  default = "eu-west-1"
}

variable "ami_id" {
  type    = string
  default = null
}

variable "ssh_public_key_url" {
  description = "URL to fetch SSH public keys from (first key is used)."
  type        = string
  default     = "https://github.com/ferr0x.keys"
}

variable "ssh_key_name" {
  description = "Name for the EC2 key pair."
  type        = string
  default     = "ad-ctf-key"
}

provider "aws" {
  region = var.aws_region
}

data "aws_ami" "ubuntu_24" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/*ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

data "http" "ssh_keys" {
  url = var.ssh_public_key_url
}

module "vpc" {
  source = "./modules/vpc"
}

locals {
  ami = var.ami_id != null && var.ami_id != "" ? var.ami_id : data.aws_ami.ubuntu_24.id
  ssh_public_keys = [
    for key in split("\n", trimspace(data.http.ssh_keys.response_body)) :
    trimspace(key)
    if trimspace(key) != ""
  ]
  ssh_user_data = <<-EOF
  #!/bin/bash
  set -euo pipefail

  install -d -m 0700 -o ubuntu -g ubuntu /home/ubuntu/.ssh
  cat > /home/ubuntu/.ssh/authorized_keys <<'KEYS'
  ${join("\n", local.ssh_public_keys)}
  KEYS
  chown ubuntu:ubuntu /home/ubuntu/.ssh/authorized_keys
  chmod 0600 /home/ubuntu/.ssh/authorized_keys
  EOF
}

resource "aws_key_pair" "deployer" {
  key_name   = var.ssh_key_name
  public_key = local.ssh_public_keys[0]
}

module "gameserver" {
  source = "./modules/gameserver"

  igw_id = module.vpc.main_internet_gateway_id

  vpc_id    = module.vpc.id
  ami_id    = local.ami
  subnet_id = module.vpc.public_subnet_id

  instance_type = "t3.micro" # cambiare questo setup di default per non pagare.
  ssh_key_name  = aws_key_pair.deployer.key_name
  user_data     = local.ssh_user_data
}

module "security_groups" {
  source = "./modules/security_groups"

  vpc_id = module.vpc.id
}

module "vulnboxes" {
  source = "./modules/vulnboxes"

  for_each = fileset("${path.module}/../deploy/vulnboxes/wg", "team*")

  igw_id = module.vpc.main_internet_gateway_id

  security_group_id = module.security_groups.sg_vulnbox_id
  vpc_id            = module.vpc.id
  ami_id            = local.ami
  subnet_id         = module.vpc.public_subnet_id

  name = each.value
  ssh_key_name = aws_key_pair.deployer.key_name
  user_data    = local.ssh_user_data

  # instance_type = "c5.xlarge" # this is ste right instance 
  instance_type = "t3.micro"
}

resource "local_file" "ansible_inventory" {
  content = templatefile("templates/ansible-inventory.tftmpl",
    {
      vulnboxes  = module.vulnboxes
      gameserver = module.gameserver.gameserver_ip_addr
    }
  )
  filename = "../deploy/inventory.ini"
}
