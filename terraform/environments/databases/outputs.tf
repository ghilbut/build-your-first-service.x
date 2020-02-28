output mysql_development_address {
  value = aws_db_instance.development.address
}

output mysql_development_port {
  value = aws_db_instance.development.port
}

output mysql_development_endpoint {
  value = aws_db_instance.development.endpoint
}
