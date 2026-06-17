# Output the custom VPC ID.
output "vpc_id" {
  description = "ID of the custom VPC"
  value       = aws_vpc.doiteasy_vpc.id
}

# Output both public subnet IDs.
output "public_subnet_ids" {
  description = "IDs of the two public subnets"
  value       = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
}

# Output the public IP addresses of both EC2 instances.
output "ec2_public_ips" {
  description = "Public IP addresses of the EC2 instances"
  value       = [aws_instance.web_1.public_ip, aws_instance.web_2.public_ip]
}

# Output the DNS name of the public Application Load Balancer.
output "load_balancer_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.doiteasy_alb.dns_name
}
