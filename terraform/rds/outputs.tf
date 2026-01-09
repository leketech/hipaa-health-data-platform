# Output values for the RDS module

output "db_instance_id" {
  description = "ID of the RDS instance"
  value       = aws_db_instance.postgres.id
}

output "db_endpoint" {
  description = "Endpoint of the RDS instance"
  value       = aws_db_instance.postgres.endpoint
  sensitive   = true
}

output "db_port" {
  description = "Port of the RDS instance"
  value       = aws_db_instance.postgres.port
}

output "db_name" {
  description = "Name of the database"
  value       = aws_db_instance.postgres.db_name
}

output "db_subnet_group_name" {
  description = "Name of the DB subnet group"
  value       = aws_db_subnet_group.main.name
}