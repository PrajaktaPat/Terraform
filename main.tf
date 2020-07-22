provider "aws" {
  region  = "us-east-1"
}
resource "aws_vpc" "test-env" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true
  tags = {
    Name = "test-env"
  }
}
resource "aws_subnet" "subnet-test" {
  cidr_block = "10.0.0.0/24"
  vpc_id = "${aws_vpc.test-env.id}"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = var.mapPublicIP
}

resource "aws_security_group" "MySecurityGroup" {
    name        = "MySG"
    description = "Allow SSH and TCP inbound traffic"
    vpc_id = "${aws_vpc.test-env.id}"
    ingress{
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    }
    ingress{
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "MYSG"
    }
}



resource "aws_internet_gateway" "test-env-gw" {
  vpc_id = "${aws_vpc.test-env.id}"
tags = {
    Name = "test-env-gw"
  }
}

resource "aws_route_table" "route-table-test-env" {
  vpc_id = "${aws_vpc.test-env.id}"
route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.test-env-gw.id}"
  }
tags = {
    Name = "test-env-route-table"
  }
}
resource "aws_route_table_association" "subnet-association" {
  subnet_id      = "${aws_subnet.subnet-test.id}"
  route_table_id = "${aws_route_table.route-table-test-env.id}"
}

resource "aws_instance" "web_server" {
ami = "ami-08f3d892de259504d"
instance_type = "t2.micro"
key_name = "mynewkeyfornvirginia"
security_groups = ["${aws_security_group.MySecurityGroup.id}"]
subnet_id = "${aws_subnet.subnet-test.id}"
user_data = <<-EOF
		#!/bin/bash
		yum install httpd -y
		chkconfig httpd on
		echo "<h1>launched through $(curl http://169.254.169.254/latest/meta-data/local-ipv4)</h1>" > /var/www/html/index.html
		sudo systemctl enable httpd
        sudo systemctl start httpd
        echo successful 
	    EOF
tags ={
    Name = "my_server"
}
}

output "DNS" {
  value = aws_instance.web_server.public_dns
}