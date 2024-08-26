#################
# Load Balancer #
#################

resource "aws_security_group" "lb" {
  description = "Configure access for the Application Load Balancer"
  name        = "${local.prefix}-alb-access"
  vpc_id      = aws_vpc.main.id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "tcp"
    from_port   = 8000
    to_port     = 8000
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "api" { # Actually creating our resource ALB
  name               = "${local.prefix}-lb"
  load_balancer_type = "application"
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]
  security_groups    = [aws_security_group.lb.id]
}

resource "aws_lb_target_group" "api" {
  name        = "${local.prefix}-api"
  protocol    = "HTTP" # These requests are going to be forwarded in our request
  vpc_id      = aws_vpc.main.id
  target_type = "ip"
  port        = 8000

  health_check {
    path = "/api/health-check"
  }
}

resource "aws_lb_listener" "api" { # Incoming component of the load balancer
  load_balancer_arn = aws_lb.api.arn
  port              = 80
  protocol          = "HTTP" # We can't add HTTPS until later on, when we add custom domain name, to register a certificate

  default_action { # Forward request to our target group
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }
}