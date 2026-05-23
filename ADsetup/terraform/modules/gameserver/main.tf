data "aws_internet_gateway" "igw" {
  internet_gateway_id = var.igw_id
}

resource "aws_security_group" "gameserver" {
  name        = "Gameserver Security Group"
  description = "Disable all connectivity other than WireGuards."
  vpc_id      = var.vpc_id

  # Allow connectivity to the internet, disallow incoming connections 
  # from the local VPC.
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port        = 5182
    to_port          = 5182
    protocol         = "udp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "disable_connectivity_gameserver"
  }
}

resource "aws_network_interface" "gameserver" {
  subnet_id       = var.subnet_id
  private_ips     = ["172.241.241.241"]
  security_groups = [aws_security_group.gameserver.id]

  tags = {
    Name = "gameserver_network_interface"
  }
}

resource "aws_eip" "gameserver" {
  domain     = "vpc"
  depends_on = [data.aws_internet_gateway.igw]
  instance   = aws_instance.gameserver.id
}

resource "aws_instance" "gameserver" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.ssh_key_name
  user_data     = var.user_data
  user_data_replace_on_change = true

  network_interface {
    network_interface_id = aws_network_interface.gameserver.id
    device_index         = 0
  }

  root_block_device {
    volume_size = var.volume_size
  }

  tags = {
    Name = "gameserver"
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  depends_on = [data.aws_internet_gateway.igw]
}
