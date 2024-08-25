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