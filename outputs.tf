output "aws_lb_external" {
  value = aws_lb.external-lb.dns_name
}
output "aws_lb_internal" {
  value = aws_lb.internal-lb.dns_name
} 
output "database_endpoint" {
  value = aws_db_instance.database.endpoint
}