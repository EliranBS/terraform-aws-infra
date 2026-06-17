# Security group for the public Application Load Balancer.
resource "aws_security_group" "alb_security_group" {
  name        = "doiteasy-alb-sg"
  description = "Allow public HTTP traffic to the Application Load Balancer"
  vpc_id      = aws_vpc.doiteasy_vpc.id

  ingress {
    description = "Allow HTTP from the internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "doiteasy-alb-sg"
  }
}

# Security group for the EC2 instances.
resource "aws_security_group" "ec2_security_group" {
  name        = "doiteasy-ec2-sg"
  description = "Allow SSH from one public IP and HTTP from the ALB"
  vpc_id      = aws_vpc.doiteasy_vpc.id

  ingress {
    description = "Allow SSH only from your public IP; replace this placeholder CIDR"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["203.0.113.10/32"]
  }

  ingress {
    description     = "Allow HTTP from the ALB security group"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_security_group.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "doiteasy-ec2-sg"
  }
}
