# Create a public-facing Application Load Balancer across both public subnets.
resource "aws_lb" "doiteasy_alb" {
  name               = "doiteasy-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_security_group.id]
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]

  tags = {
    Name = "doiteasy-alb"
  }
}

# Create a target group for HTTP traffic to the EC2 instances.
resource "aws_lb_target_group" "web_target_group" {
  name     = "doiteasy-web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.doiteasy_vpc.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "doiteasy-web-tg"
  }
}

# Attach the first EC2 instance to the target group.
resource "aws_lb_target_group_attachment" "web_1_attachment" {
  target_group_arn = aws_lb_target_group.web_target_group.arn
  target_id        = aws_instance.web_1.id
  port             = 80
}

# Attach the second EC2 instance to the target group.
resource "aws_lb_target_group_attachment" "web_2_attachment" {
  target_group_arn = aws_lb_target_group.web_target_group.arn
  target_id        = aws_instance.web_2.id
  port             = 80
}

# Create an HTTP listener that forwards requests to the target group.
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.doiteasy_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_target_group.arn
  }
}
