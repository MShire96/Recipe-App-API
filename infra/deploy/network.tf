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

############################################
# Private subnets for internal access only #
############################################

# Don't need to hook it up with internet gateway

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.1.10.0/24"
  availability_zone = "${data.aws_region.current.name}a"

  tags = {
    Name = "${local.prefix}-private-a"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.1.11.0/24"
  availability_zone = "${data.aws_region.current.name}b"

  tags = {
    Name = "${local.prefix}-private-b"
  }
}

########################################################################
# Endpoints to allow ECS to access ECR, Cloudwatch and Systems Manager #
########################################################################

resource "aws_security_group" "endpoint_access" {
  description = "Access to endpoints"
  name        = "${local.prefix}-endpoint-access"
  vpc_id      = aws_vpc.main.id
  # Security group for endpoints that so that we can connect to endpoints
  # Have to have SGs to provision access to endpoint from resources in subnet
  ingress {                                 # inbound access to what SG is assigned to, inbound acces to endpoint from cidr block
    cidr_blocks = [aws_vpc.main.cidr_block] # Allow ingress from everywhere in cidr
    from_port   = 443                       # All these ports use HTTP so 443
    to_port     = 443
    protocol    = "tcp" # All http/https uses tcp
  }
}

# 
resource "aws_vpc_endpoint" "ecr" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.ecr.api"
  # Name of service the endpoint will connect to, listed in endpoint interface in AWS
  # Connect to ECR from ECS using interface endpoint
  vpc_endpoint_type = "Interface"
  # 2 types of endpoints, gateways and interface, gateways only for S3 atm
  private_dns_enabled = true
  # we get private dns name for ecs so it can easily resolve the endpoint were trying to connect to
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  security_group_ids = [
    aws_security_group.endpoint_access.id
  ]

  tags = {
    Name = "${local.prefix}-ecr-endpoint"
  }
}

# To connect to ECR we need 3 endpoints to make it possible
# The ECR endpoint service above, docker repo service dkr, and S3 which aws uses to store images

resource "aws_vpc_endpoint" "dkr" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  security_group_ids = [
    aws_security_group.endpoint_access.id
  ]

  tags = {
    Name = "${local.prefix}-dkr-endpoint"
  }
}

resource "aws_vpc_endpoint" "cloudwatch_logs" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.logs"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  security_group_ids = [
    aws_security_group.endpoint_access.id
  ]

  tags = {
    Name = "${local.prefix}-cloudwatch-endpoint"
  }
}

resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  security_group_ids = [
    aws_security_group.endpoint_access.id
  ]

  tags = {
    Name = "${local.prefix}-ssmmessages-endpoint"
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids = [
    aws_vpc.main.default_route_table_id
  ]

  tags = {
    Name = "${local.prefix}-s3-endpoint"
  }
}
