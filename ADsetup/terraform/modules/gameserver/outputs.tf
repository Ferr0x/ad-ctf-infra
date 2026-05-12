output "gameserver_ip_addr" {
  value = aws_eip.gameserver.public_ip
}

