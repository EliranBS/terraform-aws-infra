# Look up a recent Amazon Linux 2023 AMI for EC2 instances.
# If your instructor requires a specific AMI, replace this data source with that AMI ID.
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Create a custom VPC instead of using the default VPC.
resource "aws_vpc" "doiteasy_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "doiteasy-vpc"
  }
}

# Create the first public subnet in availability zone us-east-1a.
resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.doiteasy_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "doiteasy-public-subnet-1"
  }
}

# Create the second public subnet in a different availability zone for the ALB.
resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.doiteasy_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "doiteasy-public-subnet-2"
  }
}

# Create and attach an Internet Gateway so the VPC can reach the internet.
resource "aws_internet_gateway" "doiteasy_igw" {
  vpc_id = aws_vpc.doiteasy_vpc.id

  tags = {
    Name = "doiteasy-igw"
  }
}

# Create a public route table with a default route to the Internet Gateway.
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.doiteasy_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.doiteasy_igw.id
  }

  tags = {
    Name = "doiteasy-public-route-table"
  }
}

# Associate the public route table with the first subnet.
resource "aws_route_table_association" "public_subnet_1_association" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_route_table.id
}

# Associate the public route table with the second subnet.
resource "aws_route_table_association" "public_subnet_2_association" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_route_table.id
}

# Create the first EC2 instance in the first public subnet.
resource "aws_instance" "web_1" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_subnet_1.id
  vpc_security_group_ids      = [aws_security_group.ec2_security_group.id]
  associate_public_ip_address = true

  # Replace this with an existing EC2 key pair name in your AWS account.
  key_name = "REPLACE_WITH_YOUR_KEY_PAIR_NAME"

  tags = {
    Name = "doiteasy-web-1"
  }
}

# Create the second EC2 instance in the second public subnet.
resource "aws_instance" "web_2" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_subnet_2.id
  vpc_security_group_ids      = [aws_security_group.ec2_security_group.id]
  associate_public_ip_address = true

  # Replace this with an existing EC2 key pair name in your AWS account.
  key_name = "REPLACE_WITH_YOUR_KEY_PAIR_NAME"

  tags = {
    Name = "doiteasy-web-2"
  }
}
