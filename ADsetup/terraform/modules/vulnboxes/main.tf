data "aws_internet_gateway" "igw" {
  internet_gateway_id = var.igw_id
}

data "aws_security_group" "vsg" {
  id = var.security_group_id
}

resource "aws_instance" "vulnbox" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  associate_public_ip_address = true

  depends_on = [data.aws_internet_gateway.igw]

  # Every vulnbox has the same security group applied.
  vpc_security_group_ids = [data.aws_security_group.vsg.id]

  root_block_device {
    volume_size = var.volume_size
  }

  metadata_options {
    http_endpoint = "disabled"
  }
}

