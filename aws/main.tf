
#Export Environment variabled
provider "aws" {
    region = "us-east-1"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}



#Create EC2 instance
/*
resource "aws_instance" "learn-terraform" {
    ami           = data.aws_ami.ubuntu.id
    instance_type = "t3.micro"

    tags = {
        Name = "learn-terraform"
    }
}
*/


#Create VPC
/*
resource "aws_vpc" "Production" {
  cidr_block       = "10.0.0.0/16"
  tags = {
    Name = "production-vpc"
  }
}

#Create subnet
resource "aws_subnet" "Subnet-1" {
  vpc_id     = aws_vpc.Production.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "prod-subnet-1"
  }
}
*/


#PROJECT 1
variable "subnet_prefix" {
  description = "cidr block for block"
  default = ["10.0.55.0/24"]
  type = any
}

resource "aws_vpc" "Production_vpc" {
  cidr_block       = "10.0.0.0/16"
  tags = {
    Name = "production"
  }
}
resource "aws_internet_gateway" "Internet_gateway" {
  vpc_id = aws_vpc.Production_vpc.id

  tags = {
    Name = "Gateway"
  }
}

#Custom route table
resource "aws_route_table" "routetable" {
  vpc_id = aws_vpc.Production_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Internet_gateway.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.Internet_gateway.id
  }

  tags = {
    Name = "route_table"
  }
}

#Create subnet
resource "aws_subnet" "subnet_1" {
  vpc_id     = aws_vpc.Production_vpc.id
  cidr_block = var.subnet_prefix[0].cidr_block
  availability_zone = "us-east-1a"

  tags = {
    Name = var.subnet_prefix[0].name
  }
}

#associate route table with subnet
resource "aws_route_table_association" "route_assocatiation" {
  subnet_id      = aws_subnet.subnet_1.id
  route_table_id = aws_route_table.routetable.id
}

#Create security Group to allow ports 22, 80,443
resource "aws_security_group" "allow_web_traffic" {
  name        = "allow_web_traffic"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.Production_vpc.id

  tags = {
    Name = "allow_web_traffic"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_web_traffic_ipv4_443" {
  security_group_id = aws_security_group.allow_web_traffic.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}
resource "aws_vpc_security_group_ingress_rule" "allow_web_traffic_ipv4_80" {
  security_group_id = aws_security_group.allow_web_traffic.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}
resource "aws_vpc_security_group_ingress_rule" "allow_web_traffic_ipv4_22" {
  security_group_id = aws_security_group.allow_web_traffic.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_web_traffic_ipv6" {
  security_group_id = aws_security_group.allow_web_traffic.id
  cidr_ipv6         = "::/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_web_traffic.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv6" {
  security_group_id = aws_security_group.allow_web_traffic.id
  cidr_ipv6         = "::/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

#Create network interface
resource "aws_network_interface" "web_server_nic" {
  subnet_id       = aws_subnet.subnet_1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web_traffic.id]

#   attachment {
#     instance     = aws_instance.test.id
#     device_index = 1
#   }
}

#Assign Elastic IP to nic
resource "aws_eip" "elastic_IP" {
  #vpc                       = true
  domain                    = "vpc"
  network_interface         = aws_network_interface.web_server_nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [aws_internet_gateway.Internet_gateway,aws_instance.ubuntu_webserver]
}

output "server_public_ip" {
  value = aws_eip.elastic_IP.public_ip
}

#create Key pair
resource "aws_key_pair" "accesskey" {
  key_name   = "webserver-key"
  public_key = file("publickey")
}

#Create Ubuntu server and install apache2
resource "aws_instance" "ubuntu_webserver" {
    ami           = data.aws_ami.ubuntu.id
    instance_type = "t3.micro"
    availability_zone = "us-east-1a"
    key_name = aws_key_pair.accesskey.key_name
    network_interface {
      device_index = 0
      network_interface_id = aws_network_interface.web_server_nic.id
    }
    user_data = <<-EOF
                #!bin/bash
                sudo apt update -y
                sudo apt install apache2 -y
                sudo systemctl start apache2
                sudo bash -c 'echo Webserver project >> /var/www/html/index.html'
                EOF

    tags = {
        Name = "ubuntu_webserver"
    }
}
