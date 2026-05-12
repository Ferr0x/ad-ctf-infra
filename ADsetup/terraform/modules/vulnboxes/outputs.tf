output "vulnbox_ip" {
  value = aws_instance.vulnbox.public_ip
}

output "name" {
  value = var.name
}

