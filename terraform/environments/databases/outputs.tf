output mysql_development_address {
  value = aws_db_instance.development.address
}

output mysql_development_port {
  value = aws_db_instance.development.port
}

output mysql_development_endpoint {
  value = aws_db_instance.development.endpoint
}

output mysql_username {
  value       = var.db_username
  description = "MySQL admin username"
  sensitive   = true
}

output mysql_password {
  value       = var.db_password
  description = "MySQL admin password"
  sensitive   = true
}
