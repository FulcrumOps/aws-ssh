provider "aws" {
  region = "us-east-1" # Set your desired AWS region
}

data "aws_availability_zones" "available" {}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_vpc" "example_vpc" {
  cidr_block = "10.0.0.0/16" # Replace with your desired VPC CIDR block

  tags = {
    Name = "example-vpc"
  }
}

resource "aws_subnet" "example_subnet" {
  count                   = 1 # You can create multiple subnets in different availability zones
  vpc_id                  = aws_vpc.example_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "example-subnet-${count.index}"
  }
}

resource "aws_internet_gateway" "example_igw" {
  vpc_id = aws_vpc.example_vpc.id

  tags = {
    Name = "example-igw"
  }
}

resource "aws_route_table" "example_route_table" {
  vpc_id = aws_vpc.example_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.example_igw.id
  }

  tags = {
    Name = "example-route-table"
  }
}

resource "aws_route_table_association" "example_subnet_association" {
  count          = length(aws_subnet.example_subnet)
  subnet_id      = aws_subnet.example_subnet[count.index].id
  route_table_id = aws_route_table.example_route_table.id
}

resource "aws_security_group" "ssh-access" {
  name        = "ssh-access"
  description = "Allow SSH traffic"
  vpc_id      = aws_vpc.example_vpc.id
  # Inbound SSH rule open to all (0.0.0.0/0)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = -1 # ICMP doesn't use port numbers
    to_port     = -1 # ICMP doesn't use port numbers
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "aws_key_pair" "example" {
  key_name   = "demo"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM+rDERByezKu26QcRt1JfNbadcQH90qBPeDMydbwQ+w Pete Emerson"
}

resource "aws_instance" "web" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  count                       = var.num_web_instances
  associate_public_ip_address = true
  security_groups             = [aws_security_group.ssh-access.id]
  subnet_id                   = aws_subnet.example_subnet[0].id
  key_name                    = "demo"

  user_data = <<-EOF
              #!/bin/bash
              echo "127.0.0.1 web00${count.index + 1}" >> /etc/hosts
              echo "::1 web00${count.index + 1}" >> /etc/hosts
              hostnamectl set-hostname web00${count.index + 1}

              echo "Updated /etc/hosts with custom hostname"
              EOF

  tags = {
    Name        = "web00${count.index + 1}.us-east-1.dev.fulcrumops.com"
    Region      = "us-east-1"
    Environment = "dev"
    Type        = "web"
    Domain      = "fulcrumops.com"
  }
}

resource "aws_instance" "api" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  count                       = var.num_api_instances
  associate_public_ip_address = true
  security_groups             = [aws_security_group.ssh-access.id]
  subnet_id                   = aws_subnet.example_subnet[0].id
  key_name                    = "demo"

  user_data = <<-EOF
              #!/bin/bash
              echo "127.0.0.1 web00${count.index + 1}" >> /etc/hosts
              echo "::1 web00${count.index + 1}" >> /etc/hosts
              hostnamectl set-hostname web00${count.index + 1}
              echo "Updated /etc/hosts with custom hostname"
              EOF

  tags = {
    Name        = "api00${count.index + 1}.us-east-1.dev.fulcrumops.com"
    Region      = "us-east-1"
    Environment = "dev"
    Type        = "api"
    Domain      = "fulcrumops.com"
  }
}

resource "aws_instance" "db" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  count                       = var.num_db_instances
  associate_public_ip_address = true
  security_groups             = [aws_security_group.ssh-access.id]
  subnet_id                   = aws_subnet.example_subnet[0].id
  key_name                    = "demo"

  user_data = <<-EOF
              #!/bin/bash
              echo "127.0.0.1 web00${count.index + 1}" >> /etc/hosts
              echo "::1 web00${count.index + 1}" >> /etc/hosts
              hostnamectl set-hostname web00${count.index + 1}
              echo "Updated /etc/hosts with custom hostname"
              EOF

  tags = {
    Name        = "db00${count.index + 1}.us-east-1.dev.fulcrumops.com"
    Region      = "us-east-1"
    Environment = "dev"
    Type        = "db"
    Domain      = "fulcrumops.com"
  }
}
