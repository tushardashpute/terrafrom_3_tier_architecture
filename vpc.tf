provider "aws" {
  region = "us-east-1"
  shared_credentials_file = "C:\\Users\\Tushar Dashpute\\.aws\\credentials"
  profile                 = "customprofile"
}

# VPC Creation

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "myvpc"
  }
}

# Creating Internet Gateway

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "my-test-igw"
  }
}

# Public Route Table

resource "aws_route_table" "public_route" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "my-test-public-route"
  }
}

# Private Route Table

resource "aws_default_route_table" "private_route" {
  default_route_table_id = aws_vpc.main.default_route_table_id

  route {
    nat_gateway_id = aws_nat_gateway.my-test-nat-gateway.id
    cidr_block     = "0.0.0.0/0"
  }

  tags = {
    Name = "my-private-route-table"
  }
}

# Public Subnet
resource "aws_subnet" "public_subnet" {
  cidr_block              = var.public_cidr
  vpc_id                  = aws_vpc.main.id
  map_public_ip_on_launch = true
  availability_zone       = var.availability_zone

  tags = {
    Name = "my-test-public-subnet"
  }
}

# Private Subnet
resource "aws_subnet" "private_subnet" {
  cidr_block        = var.private_cidr
  vpc_id            = aws_vpc.main.id
  map_public_ip_on_launch = "true"
  availability_zone = var.availability_zone

  tags = {
    Name = "my-test-private-subnet"
  }
}

resource "aws_subnet" "private_subnet1" {
  cidr_block              = var.private_cidr1
  vpc_id                  = aws_vpc.main.id
  map_public_ip_on_launch = true
  availability_zone       = var.availability_zone1

  tags = {
    Name = "my-test-private-subnet1"
  }
}

# Associate Public Subnet with Public Route Table
resource "aws_route_table_association" "public_subnet_assoc" {
  route_table_id = aws_route_table.public_route.id
  subnet_id      = aws_subnet.public_subnet.id
  depends_on     = [aws_route_table.public_route, aws_subnet.public_subnet]
}

# Associate Private Subnet with Private Route Table
resource "aws_route_table_association" "private_subnet_assoc" {
  count          = 2
  route_table_id = aws_default_route_table.private_route.id
  subnet_id      = aws_subnet.private_subnet.id
  depends_on     = [aws_default_route_table.private_route, aws_subnet.private_subnet]
}

resource "aws_route_table_association" "private_subnet1_assoc" {
  route_table_id = aws_default_route_table.private_route.id
  subnet_id      = aws_subnet.private_subnet1.id
  depends_on     = [aws_default_route_table.private_route, aws_subnet.private_subnet1]
}

# Security Group Creation
resource "aws_security_group" "sg" {
  name   = "my-test-sg"
  vpc_id = aws_vpc.main.id
}

# Ingress Security Port 22
resource "aws_security_group_rule" "ssh_inbound_access" {
  from_port         = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.sg.id
  to_port           = 22
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "RDS_postgress_db_access" {
  from_port         = 5432
  protocol          = "tcp"
  security_group_id = aws_security_group.sg.id
  to_port           = 5432
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

# All OutBound Access
resource "aws_security_group_rule" "all_outbound_access" {
  from_port         = 0
  protocol          = "-1"
  security_group_id = aws_security_group.sg.id
  to_port           = 0
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_eip" "my-test-eip" {
  vpc = true
}

resource "aws_nat_gateway" "my-test-nat-gateway" {
  allocation_id = aws_eip.my-test-eip.id
  subnet_id     = aws_subnet.public_subnet.id
}

 resource "aws_instance" "public-instance" {
  ami           = var.ami
  instance_type = var.instance_type
  key_name      = var.key_name
  user_data     = "sudo yum install java-1.8.0-openjdk -y"
  subnet_id = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.sg.id]

  tags = {
    Name  = "${var.env}_public_EC2"
  }
}


resource "aws_instance" "private-instance" {
  count         =  var.instance_count
  ami           =  var.ami
  instance_type =  var.instance_type
  key_name      =  var.key_name
  user_data     = "sudo yum install java-1.8.0-openjdk -y"
  subnet_id = aws_subnet.private_subnet.id
  vpc_security_group_ids = [aws_security_group.sg.id]

  tags = {
    Name  = "${var.env}_private_EC2_${count.index}"
  }
} 

##RDS instance creation on EC2_PRIVATE_INSTACNE_1


resource "aws_db_subnet_group" "subnet_group" {
  subnet_ids = [aws_subnet.private_subnet.id, aws_subnet.private_subnet1.id]
}

resource "aws_db_instance" "rds" {

  allocated_storage       = 10
  backup_retention_period = 5
  db_subnet_group_name    = aws_db_subnet_group.subnet_group.id
  engine                  = "postgres"
  engine_version          = "9.5.4"
  instance_class          = "db.t2.medium"
  name                    = "mydb1"
  username                = "mydb1"
  password                = "admin123"
  port                    = 5432
  publicly_accessible     = true
  storage_encrypted       = false
  vpc_security_group_ids = [aws_security_group.sg.id]
}

