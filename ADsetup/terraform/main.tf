terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "eu-west-1"
}

module "vpc" {
  source = "./modules/vpc"
}

locals {
  ami = "ami-055cb4a9ada798dbe" # auto gen, cambiare questo dopo packer build 
}

module "gameserver" {
  source = "./modules/gameserver"

  igw_id = module.vpc.main_internet_gateway_id

  vpc_id    = module.vpc.id
  ami_id    = local.ami
  subnet_id = module.vpc.public_subnet_id

  instance_type = "t3.micro" # cambiare questo setup di default per non pagare.
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

