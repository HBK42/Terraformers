terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.3.0"
backend "s3" {
    bucket         = "terraform-state-kazem-sindy"
    key            = "terraform/state/terraform.tfstate"
    region         = "us-east-1"
  }
}
# AWS Provider konfigurieren
provider "aws" {
  region = "us-east-1" # Region, in der die Ressourcen bereitgestellt werden
}

# VPC erstellen
resource "aws_vpc" "custom_vpc" {
  cidr_block = "10.0.0.0/16" # Netzbereich für die VPC
  tags = {
    Name = "CustomVPC"
  }
}

# Internet Gateway erstellen
resource "aws_internet_gateway" "custom_igw" {
  vpc_id = aws_vpc.custom_vpc.id
  tags = {
    Name = "CustomInternetGateway"
  }
}

# Route Table erstellen
resource "aws_route_table" "custom_route_table" {
  vpc_id = aws_vpc.custom_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.custom_igw.id
  }
  tags = {
    Name = "CustomRouteTable"
  }
}

# Subnetz 1 erstellen
resource "aws_subnet" "custom_subnet_1" {
  vpc_id                  = aws_vpc.custom_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
  tags = {
    Name = "CustomSubnet1"
  }
}

# Subnetz 2 erstellen
resource "aws_subnet" "custom_subnet_2" {
  vpc_id                  = aws_vpc.custom_vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1b"
  tags = {
    Name = "CustomSubnet2"
  }
}

# Route Table mit Subnetzen verbinden
resource "aws_route_table_association" "custom_subnet_assoc_1" {
  subnet_id      = aws_subnet.custom_subnet_1.id
  route_table_id = aws_route_table.custom_route_table.id
}

resource "aws_route_table_association" "custom_subnet_assoc_2" {
  subnet_id      = aws_subnet.custom_subnet_2.id
  route_table_id = aws_route_table.custom_route_table.id
}

# Security Group erstellen
resource "aws_security_group" "web_sg" {
  vpc_id      = aws_vpc.custom_vpc.id
  name        = "web_security_group"
  description = "Allow HTTP inbound traffic and all outbound traffic"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "WebSecurityGroup"
  }
}

# Load Balancer erstellen
resource "aws_lb" "web_lb" {
  name               = "web-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_sg.id]
  subnets            = [
    aws_subnet.custom_subnet_1.id,
    aws_subnet.custom_subnet_2.id
  ]

  tags = {
    Name = "WebLoadBalancer"
  }
}

# EC2-Instanzen erstellen
resource "aws_instance" "web_server" {
  count                   = 2
  ami                     = "ami-0866a3c8686eaeeba" # Ubuntu AMI für us-east-1
  instance_type           = "t2.micro"
  subnet_id               = aws_subnet.custom_subnet_1.id
  security_groups         = [aws_security_group.web_sg.id]

  user_data = <<-EOF
    #!/bin/bash
    sudo apt-get update
    sudo apt-get install -y apache2
    sudo systemctl start apache2
    sudo systemctl enable apache2
    echo "<h1>Hello from EC2 Instance $(hostname)</h1>" | sudo tee /var/www/html/index.html
  EOF

  tags = {
    Name = "ApacheWebServer-${count.index}"
  }
}

# Load Balancer Listener erstellen
resource "aws_lb_listener" "web_lb_listener" {
  load_balancer_arn = aws_lb.web_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.web_lb_tg.arn
  }
}

# Load Balancer Target Group erstellen
resource "aws_lb_target_group" "web_lb_tg" {
  name        = "web-lb-target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.custom_vpc.id
  target_type = "instance"

  health_check {
    path                = "/"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# EC2-Instanzen zum Load Balancer Target Group hinzufügen
resource "aws_lb_target_group_attachment" "web_lb_attachment" {
  count             = 2
  target_group_arn  = aws_lb_target_group.web_lb_tg.arn
  target_id         = aws_instance.web_server[count.index].id
  port              = 80
}

# Load Balancer DNS als Output
output "load_balancer_dns" {
  value       = aws_lb.web_lb.dns_name
  description = "DNS Name des Load Balancers"
}
