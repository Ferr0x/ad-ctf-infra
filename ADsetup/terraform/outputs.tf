output "gameserver_ip" {
  description = "Gameserver IP address"
  value       = module.gameserver.gameserver_ip_addr
}

output "vulnboxes_ip" {
  description = "A list of all the vulnboxes IPs"
  value       = values(module.vulnboxes)[*].vulnbox_ip
}

