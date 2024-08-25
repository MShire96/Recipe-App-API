############
# Database #
############

# Needed for db's you create, linking db to subnets you create in network Terraform

resource "aws_db_subnet_group" "main" {
  name = "${local.prefix}-main"
  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id
  ]

  tags = {
    Name = "${local.prefix}-db-subnet-group"
  }
}

# Creating SG, allowing access to RDS DB instance

resource "aws_security_group" "rds" {
  description = "Allow access to the RDS database instance"
  name        = "${local.prefix}-rds-inbound-access"
  vpc_id      = aws_vpc.main.id

  ingress {
    protocol  = "tcp"
    from_port = 5432 # default port for postgres dbs
    to_port   = 5432

    security_groups = [
      aws_security_group.ecs_service.id
    ]
  }

  tags = {
    Name = "${local.prefix}-db-security-group"
  }
}

# This is to create the db instance itself
resource "aws_db_instance" "main" {
  identifier                 = "${local.prefix}-db"          # Name given to resource in AWS console
  db_name                    = "recipe"                      # DB name created for the DB itself
  allocated_storage          = 20                            # Storage for RDS instance, GB
  storage_type               = "gp2"                         # General storage, our app designed for it
  engine                     = "postgres"                    # The engine we'll be using
  engine_version             = "15.4"                        # Version of postgres
  auto_minor_version_upgrade = true                          # AWS able to upgrade minor versions of the DB automatically, security fixes etc
  instance_class             = "db.t4g.micro"                # Size of the server running the DB, smallest size
  username                   = var.db_username               # Username
  password                   = var.db_password               # Password for credentials to use to connect to DB in RDS
  skip_final_snapshot        = true                          # The SS is the SS of the data created inside DB when you remove the instance, keep cost low
  db_subnet_group_name       = aws_db_subnet_group.main.name # References db subnet group above, tells AWS to make db accessible via private a and b subnets
  multi_az                   = false                         # For resilience, false for cost low
  backup_retention_period    = 0                             # Automatically create backups and store them, but cost associated
  vpc_security_group_ids     = [aws_security_group.rds.id]   # References SG above, allowings access to DB

  tags = {
    Name = "${local.prefix}-main"
  }
}