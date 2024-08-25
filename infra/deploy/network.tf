##########################
# Network Infrastructure #
##########################

# Creating the VPC required and the cidr block for the VPC

resource "aws_vpc" "main" {
  cidr_block           = "10.1.0.0/16"
  enable_dns_hostnames = true

  # Enable user friendly name for internal networking of app
  # Can assign dynamic IP addresses to hostnames, same name if IP changes

  enable_dns_support = true

  # Enables support of dns to use for VPC

  tags = {
    Name = "vpc-${local.prefix}-main"
  }
}

#########################################################
# Internet Gateway needed for inbound access to the ALB #
#########################################################

# Creating the internet gateway required for the VPC where it lives

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.prefix}-main"

    # How you give internet gateway a name you can read from the console
  }
}

#########################################################
# Public subnets for load balancer public access #
#########################################################


# Public subnet contain load balancer
# Items in subnet assigned public IP address to access internet

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.1.1.0/24"
  map_public_ip_on_launch = true # Any resource thats loaded in this subnet gets mapped a public ip address
  availability_zone       = "${data.aws_region.current.name}a"

  tags = {
    Name = "${local.prefix}-public-a"
  }
}
# Created the subnet a with 256 ip positions


resource "aws_route_table" "public_a" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.prefix}-public-a"
  }
}
# Created the route table in VPC

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public_a.id
}
# Associated route table with subnet a

resource "aws_route" "public_internet_access_a" {
  route_table_id         = aws_route_table.public_a.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}
# Create AWS route, connected to route table in public a 
# Access through internet gateway, destination to all IP addresses

############
# Subnet-b #
############




# Public subnet contain load balancer
# Items in subnet assigned public IP address to access internet

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.1.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${data.aws_region.current.name}b"

  tags = {
    Name = "${local.prefix}-public-b"
  }
}
# Created the subnet a with 256 ip positions


resource "aws_route_table" "public_b" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.prefix}-public-b"
  }
}
# Created the route table in VPC

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public_b.id
}
# Associated route table with subnet b

resource "aws_route" "public_internet_access_b" {
  route_table_id         = aws_route_table.public_b.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}
# Create AWS route, connected to route table in public b
# Access through internet gateway, destination to all IP addresses
