terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.36"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "eu-central-1"
}

locals {
  envs = { for tuple in regexall("(.*)=(.*)", file(".env")) : tuple[0] => tuple[1] }
}

resource "aws_instance" "hsa26_instance_1" {
  ami           = "ami-0bf463e49ccd368ed"
  instance_type = "t4g.micro"
}

resource "aws_instance" "hsa26_instance_2" {
  ami           = "ami-0bf463e49ccd368ed"
  instance_type = "t4g.micro"
}

resource "aws_lb" "hsa26_lb" {
  name = "hsa26-lb"
  internal = false
  load_balancer_type = "application"
  subnets = [local.envs["SUBNET_1"], local.envs["SUBNET_2"]]
}

resource "aws_lb_target_group" "hsa26_lb_target" {
  name = "hsa26-target"
  port = 80
  protocol = "HTTP"
  target_type = "instance"
  vpc_id = local.envs["VPC_ID"]

  health_check {
    enabled = true
    path = "/"
    port = "8000"
    protocol = "HTTP"
    healthy_threshold = 3
    unhealthy_threshold = 2
    interval = 90
    timeout = 20
    matcher = "200"
  }

  depends_on = [aws_lb.hsa26_lb]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.hsa26_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.hsa26_lb_target.arn
  }
}

resource "aws_lb_target_group_attachment" "target_instance_1" {
  target_group_arn = aws_lb_target_group.hsa26_lb_target.arn
  target_id        = aws_instance.hsa26_instance_1.id
  port             = 8000
}

resource "aws_lb_target_group_attachment" "target_instance_2" {
  target_group_arn = aws_lb_target_group.hsa26_lb_target.arn
  target_id        = aws_instance.hsa26_instance_2.id
  port             = 8000
}
