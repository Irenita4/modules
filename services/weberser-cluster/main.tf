resource "aws_launch_configuration" "irene-server" {
  image_id        = "ami-00874d747dde814fa"
  instance_type   = "var.instance_type"
  security_groups = [aws_security_group.irene-sg.id]

  user_data = <<-EOF
      #!/bin/bash
      echo "Hala celta" >> index.html
      echo "${data.terraform_remote_state.db.outputs.address}" >> index.html
      echo "${data.terraform_remote_state.db.outputs.port}" >> index.html
      nohup busybox httpd -f -p ${var.server_port} &
      EOF 
  lifecycle {
    create_before_destroy = true
  }    
}

locals {
  http_port = 80
  any_port = 0
  tcp_protocol = "tcp"
  any_protocol = "-1"
  all_ips = "0.0.0.0/0"
}
resource "aws_autoscaling_group" "opugno" {
  launch_configuration = aws_launch_configuration.irene-server.name
  min_size = 2
  max_size = 10
  vpc_zone_identifier  = data.aws_subnets.default.ids
  target_group_arns = [aws_lb_target_group.nox.arn]

  tag {
    key                = "opugno"
    value              = "terraform ejemplito"
    propagate_at_launch = true
  }
}

data "aws_vpc" "default" { 
  default = true
}

data "aws_subnets" "default" {
  filter {
    name  = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "terraform_remote_state" "db" {
  backend = "s3"
  config = {
    bucket = "var.db_remote_state_bucket"
    key = "var.db_remote_state_key"
    region = "us-east-1"
  }
  
}

resource "aws_security_group" "irene-sg" {
  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "lb-irene" {
  name = "lb-irene"
}

resource "aws_security_group_rule" "allow_all_outband" {
  type = "egress"
  from_port = local.any_port
  to_port = local.any_port
  protocol = local.any_protocol
  cidr_blocks = [local.all_ips]
  security_group_id = "lb-irene"
}

resource "aws_security_group_rule" "name" {
  type = "ingress"
  from_port = local.any_port
  to_port = local.any_port
  protocol = local.any_protocol
  cidr_blocks = [local.all_ips]
  security_group_id = "lb-irene"
}

resource "aws_lb" "alohomora" {
  subnets = data.aws_subnets.default.ids
  load_balancer_type = "application"
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alohomora.arn
  port = 80
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.nox.arn
  }
}
resource "aws_lb_target_group" "nox" {
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id
}

resource "aws_security_group" "allow_lb" {
  ingress {
    from_port = local.http_port
    to_port   = local.http_port
    protocol  = local.any_protocol
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

