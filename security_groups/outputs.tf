#outputs
output "public_sg_id" {
  description = "The ID of the public security group"
  value       = aws_security_group.public_sg.id
}
output "ext_sg_id" {
  description = "The ID of the external security group"
  value       = aws_security_group.ext_sg.id
}
output "internal_sg_id" {
  description = "The ID of the internal security group"
  value       = aws_security_group.internal_sg.id
  
}
output "app_sg_id" {
  description = "The ID of the application security group"
  value       = aws_security_group.app_sg.id
}
output "db_sg_id" {
  description = "The ID of the database security group"
  value       = aws_security_group.db_sg.id 
}