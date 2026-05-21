resource "aws_vpc" "primary_vpc" {
  cidr_block = var.primary_vpc_cidr
  provider = aws.primary
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "Primary-VPC-${var.primary_region}"
    Purpose = "VPC-Peering"
  }
}

resource "aws_vpc" "secondary_vpc" {
  cidr_block = var.secondary_vpc_cidr
  provider = aws.secondary
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "Secondary-VPC-${var.secondary_region}"
    Purpose = "VPC-Peering"
  }
}

resource "aws_vpc" "tertiary_vpc" {
  cidr_block = var.tertiary_vpc_cidr
  provider = aws.tertiary
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "Tertiary-VPC-${var.tertiary_region}"
    Purpose = "VPC-Peering"
  }
}

resource "aws_subnet" "primary_vpc_subnet" {
  vpc_id     = aws_vpc.primary_vpc.id
  cidr_block = var.primary_subnet_cidr
  provider = aws.primary
  availability_zone = var.aws_availability_zones[0]
  map_public_ip_on_launch = true # Assign public IPs so instances can be accessed from the internet
}  

resource "aws_subnet" "secondary_vpc_subnet" {
  vpc_id     = aws_vpc.secondary_vpc.id
  cidr_block = var.secondary_subnet_cidr
  provider = aws.secondary
  availability_zone = var.aws_availability_zones[1]
  map_public_ip_on_launch = true # Assign public IPs so instances can be accessed from the internet
}

resource "aws_subnet" "tertiary_vpc_subnet" {
  vpc_id     = aws_vpc.tertiary_vpc.id
  cidr_block = var.tertiary_subnet_cidr
  provider = aws.tertiary
  availability_zone = var.aws_availability_zones[2]
  map_public_ip_on_launch = true # Assign public IPs so instances can be accessed from the internet
}

resource "aws_instance" "primary_vpc_instance" {
  ami           = "ami-0233214e13e500f77"
  instance_type = "t2.micro"
  provider = aws.primary
  subnet_id = aws_subnet.primary_vpc_subnet.id
  vpc_security_group_ids = [aws_security_group.primary_security_group.id]
  key_name = var.primary_key_name

  user_data = local.primary_user_data
}

resource "aws_instance" "secondary_vpc_instance" {
  ami           = "ami-0233214e13e500f77"
  instance_type = "t2.micro"
  provider = aws.secondary
  subnet_id = aws_subnet.secondary_vpc_subnet.id
  vpc_security_group_ids = [aws_security_group.secondary_security_group.id]
  key_name = var.secondary_key_name
  user_data = local.secondary_user_data
}

resource "aws_instance" "tertiary_vpc_instance" {
  ami           = "ami-0233214e13e500f77"
  instance_type = "t2.micro"
  provider = aws.tertiary
  subnet_id = aws_subnet.tertiary_vpc_subnet.id
  vpc_security_group_ids = [aws_security_group.tertiary_security_group.id]
  key_name = var.tertiary_key_name
  user_data = local.tertiary_user_data
}

resource "aws_security_group" "primary_security_group" {
   name        = "primary_security_group"
   vpc_id      = aws_vpc.primary_vpc.id
   provider = aws.primary

   ingress {
    description = "Allow SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allow_from_anywhere_cidr]
   }

   ingress {
    description = "Allow ICMP from secondary VPC"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [aws_vpc.secondary_vpc.cidr_block]
   }

   ingress {
    description = "Allow ICMP from tertiary VPC"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [aws_vpc.tertiary_vpc.cidr_block]
   }

   ingress {
    description = "Allow all traffic from secondary VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks   = [aws_vpc.secondary_vpc.cidr_block]
   }

   ingress {
    description = "Allow all traffic from tertiary VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks   = [aws_vpc.tertiary_vpc.cidr_block]
   }

   egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks   = [var.allow_from_anywhere_cidr]
   }
}

resource "aws_security_group" "secondary_security_group" {
   name        = "secondary_security_group"
   vpc_id      = aws_vpc.secondary_vpc.id
   provider = aws.secondary

   ingress {
    description = "Allow SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks   = [var.allow_from_anywhere_cidr]
   }

   ingress {
    description = "Allow ICMP from primary VPC"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks   = [aws_vpc.primary_vpc.cidr_block]
   }

   ingress {
    description = "Allow ICMP from tertiary VPC"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks   = [aws_vpc.tertiary_vpc.cidr_block]
   }

   ingress {
    description = "Allow all traffic from primary VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks   = [aws_vpc.primary_vpc.cidr_block]
   }

   ingress {
    description = "Allow all traffic from tertiary VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks   = [aws_vpc.tertiary_vpc.cidr_block]
   }

   egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks   = [var.allow_from_anywhere_cidr]
   }
}

resource "aws_security_group" "tertiary_security_group" {
   name        = "tertiary_security_group"
   vpc_id      = aws_vpc.tertiary_vpc.id
   provider = aws.tertiary

   ingress {
    description = "Allow SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks   = [var.allow_from_anywhere_cidr]
   }

   ingress {
    description = "Allow ICMP from primary VPC"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks   = [aws_vpc.primary_vpc.cidr_block]
   }

   ingress {
    description = "Allow ICMP from secondary VPC"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks   = [aws_vpc.secondary_vpc.cidr_block]
   }

   ingress {
    description = "Allow all traffic from primary VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks   = [aws_vpc.primary_vpc.cidr_block]
   }

   ingress {
    description = "Allow all traffic from secondary VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks   = [aws_vpc.secondary_vpc.cidr_block]
   }

   egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks   = [var.allow_from_anywhere_cidr]
   }
}

resource "aws_internet_gateway" "primary_vpc_igw" {
  vpc_id = aws_vpc.primary_vpc.id
  provider = aws.primary
}

resource "aws_internet_gateway" "secondary_vpc_igw" {
  vpc_id = aws_vpc.secondary_vpc.id
  provider = aws.secondary
}

resource "aws_internet_gateway" "tertiary_vpc_igw" {
  vpc_id = aws_vpc.tertiary_vpc.id
  provider = aws.tertiary
}

resource "aws_route_table" "primary_vpc_route_table" {
  vpc_id = aws_vpc.primary_vpc.id
  provider = aws.primary

  route {
    cidr_block = var.allow_from_anywhere_cidr
    gateway_id = aws_internet_gateway.primary_vpc_igw.id
  }
}

resource "aws_route_table" "secondary_vpc_route_table" {
  vpc_id = aws_vpc.secondary_vpc.id
  provider = aws.secondary

  route {
    cidr_block = var.allow_from_anywhere_cidr
    gateway_id = aws_internet_gateway.secondary_vpc_igw.id
  }
}

resource "aws_route_table" "tertiary_vpc_route_table" {
  vpc_id = aws_vpc.tertiary_vpc.id
  provider = aws.tertiary

  route {
    cidr_block = var.allow_from_anywhere_cidr
    gateway_id = aws_internet_gateway.tertiary_vpc_igw.id
  }
}

resource "aws_route_table_association" "primary_vpc_route_table_association" {
  route_table_id = aws_route_table.primary_vpc_route_table.id
  subnet_id = aws_subnet.primary_vpc_subnet.id
  provider = aws.primary
}

resource "aws_route_table_association" "secondary_vpc_route_table_association" {
  route_table_id = aws_route_table.secondary_vpc_route_table.id
  subnet_id = aws_subnet.secondary_vpc_subnet.id
  provider = aws.secondary
}

resource "aws_route_table_association" "tertiary_vpc_route_table_association" {
  route_table_id = aws_route_table.tertiary_vpc_route_table.id
  subnet_id = aws_subnet.tertiary_vpc_subnet.id
  provider = aws.tertiary
}

resource "aws_vpc_peering_connection" "primary_to_secondary_vpc_peering_connection" {
  provider = aws.primary
  peer_vpc_id   = aws_vpc.secondary_vpc.id
  vpc_id        = aws_vpc.primary_vpc.id
  peer_region = var.secondary_region
  auto_accept = false
}

resource "aws_vpc_peering_connection" "secondary_to_tertiary_vpc_peering_connection" {
  provider = aws.secondary
  peer_vpc_id   = aws_vpc.tertiary_vpc.id
  vpc_id        = aws_vpc.secondary_vpc.id
  peer_region = var.tertiary_region
  auto_accept = false   
}

resource "aws_vpc_peering_connection" "primary_to_tertiary_vpc_peering_connection" {
  provider = aws.primary
  peer_vpc_id   = aws_vpc.tertiary_vpc.id
  vpc_id        = aws_vpc.primary_vpc.id
  peer_region = var.tertiary_region
  auto_accept = false  
}

resource "aws_vpc_peering_connection_accepter" "primary_to_secondary_vpc_peering_connection_accepter" {
  provider = aws.secondary
  vpc_peering_connection_id = aws_vpc_peering_connection.primary_to_secondary_vpc_peering_connection.id
  auto_accept = true
}

resource "aws_vpc_peering_connection_accepter" "secondary_to_tertiary_vpc_peering_connection_accepter" {
  provider = aws.tertiary
  vpc_peering_connection_id = aws_vpc_peering_connection.secondary_to_tertiary_vpc_peering_connection.id
  auto_accept = true
}

resource "aws_vpc_peering_connection_accepter" "primary_to_tertiary_vpc_peering_connection_accepter" {
  provider = aws.tertiary
  vpc_peering_connection_id = aws_vpc_peering_connection.primary_to_tertiary_vpc_peering_connection.id
  auto_accept = true
}

resource "aws_route" "primary_to_secondary_peering_connection_route" {
  provider = aws.primary
  route_table_id            = aws_route_table.primary_vpc_route_table.id
  vpc_peering_connection_id = aws_vpc_peering_connection.primary_to_secondary_vpc_peering_connection.id
  destination_cidr_block    = aws_vpc.secondary_vpc.cidr_block  
  depends_on = [aws_vpc_peering_connection_accepter.primary_to_secondary_vpc_peering_connection_accepter]
}

resource "aws_route" "secondary_to_primary_peering_connection_route" {
  provider = aws.secondary
  route_table_id            = aws_route_table.secondary_vpc_route_table.id
  vpc_peering_connection_id = aws_vpc_peering_connection.primary_to_secondary_vpc_peering_connection.id
  destination_cidr_block    = aws_vpc.primary_vpc.cidr_block
  depends_on = [aws_vpc_peering_connection_accepter.primary_to_secondary_vpc_peering_connection_accepter]
}

resource "aws_route" "secondary_to_tertiary_peering_connection_route" {
  provider = aws.secondary
  route_table_id            = aws_route_table.secondary_vpc_route_table.id
  vpc_peering_connection_id = aws_vpc_peering_connection.secondary_to_tertiary_vpc_peering_connection.id
  destination_cidr_block    = aws_vpc.tertiary_vpc.cidr_block  
  depends_on = [aws_vpc_peering_connection_accepter.secondary_to_tertiary_vpc_peering_connection_accepter]
}

resource "aws_route" "tertiary_to_secondary_peering_connection_route" {
  provider = aws.tertiary
  route_table_id            = aws_route_table.tertiary_vpc_route_table.id
  vpc_peering_connection_id = aws_vpc_peering_connection.secondary_to_tertiary_vpc_peering_connection.id
  destination_cidr_block    = aws_vpc.secondary_vpc.cidr_block
  depends_on = [aws_vpc_peering_connection_accepter.secondary_to_tertiary_vpc_peering_connection_accepter]
}

resource "aws_route" "primary_to_tertiary_peering_connection_route" {
  provider = aws.primary
  route_table_id            = aws_route_table.primary_vpc_route_table.id
  vpc_peering_connection_id = aws_vpc_peering_connection.primary_to_tertiary_vpc_peering_connection.id
  destination_cidr_block    = aws_vpc.tertiary_vpc.cidr_block  
  depends_on = [aws_vpc_peering_connection_accepter.primary_to_tertiary_vpc_peering_connection_accepter]
}

resource "aws_route" "tertiary_to_primary_peering_connection_route" {
  provider = aws.tertiary
  route_table_id            = aws_route_table.tertiary_vpc_route_table.id
  vpc_peering_connection_id = aws_vpc_peering_connection.primary_to_tertiary_vpc_peering_connection.id
  destination_cidr_block    = aws_vpc.primary_vpc.cidr_block
  depends_on = [aws_vpc_peering_connection_accepter.primary_to_tertiary_vpc_peering_connection_accepter]
}