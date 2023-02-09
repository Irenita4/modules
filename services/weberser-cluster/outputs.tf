output "public_ip" {
    value       = aws_lb.alohomora.dns_name
    description = "Public IP for server"
}

output "sg_id" {
  value = aws_security_group.lb-irene.id
}