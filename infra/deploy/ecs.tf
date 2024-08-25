#########################################
# ECS Cluster for running app on Fargate.
#########################################


resource "aws_iam_policy" "task_execution_role_policy" {
  name        = "${local.prefix}-task-exec-role-policy"
  path        = "/"
  description = "Allow ECS to retrieve images and add to logs"
  policy      = file("./templates/ecs/task-execution-role-policy.json")
}

resource "aws_iam_role" "task_execution_role" {
  name               = "${local.prefix}-task-execution-role"
  assume_role_policy = file("./templates/ecs/task-assume-role-policy.json")
}

resource "aws_iam_role_policy_attachment" "task_execution_role" {
  role       = aws_iam_role.task_execution_role.name
  policy_arn = aws_iam_policy.task_execution_role_policy.arn
}


resource "aws_iam_role" "app_task" {
  name               = "${local.prefix}-app-task"
  assume_role_policy = file("./templates/ecs/task-assume-role-policy.json")
}

resource "aws_iam_policy" "task_ssm_policy" {
  name        = "${local.prefix}-task-ssm-role-policy"
  path        = "/"
  description = "Policy to allow System Manager to executed in container"
  policy      = file("./templates/ecs/task-ssm-policy.json")
}

resource "aws_iam_role_policy_attachment" "task_ssm_policy" {
  role       = aws_iam_role.app_task.name
  policy_arn = aws_iam_policy.task_ssm_policy.arn
}

resource "aws_cloudwatch_log_group" "ecs_task_logs" {
  name = "${local.prefix}-api"
}
resource "aws_ecs_cluster" "main" {
  name = "${local.prefix}-cluster"
}

# All we need to create a new cluster in AWS
# The cluster we'll be adding our services and our tasks to
# It'll be the wrapper around the other resources.

resource "aws_ecs_task_definition" "api" {
  family = "${local.prefix}-api" # Essentially a name
  # Each task definition, once it updates, creates a new version
  # That new version comes under the family task of that definition
  requires_compatibilities = ["FARGATE"]                          # We're using fargate, serverless
  network_mode             = "awsvpc"                             # The type of network that will be used in our task
  cpu                      = 256                                  # Cpu, the lowest cpu
  memory                   = 512                                  # The lowest memory you can put
  execution_role_arn       = aws_iam_role.task_execution_role.arn # ECS allowed to pull images
  task_role_arn            = aws_iam_role.app_task.arn            # role assigned to task, permission for ssm manager


  # Definition containers that are going to the task

  container_definitions = jsonencode([
    {
      name              = "api"
      image             = var.ecr_app_image
      essential         = true
      memoryReservation = 256
      user              = "django-user"
      environment = [
        {
          name  = "DJANGO_SECRET_KEY"
          value = var.django_secret_key

        },
        {
          name  = "DB_HOST" # Host name of the database
          value = aws_db_instance.main.address
        },
        {
          name  = "DB_NAME" # Name of the database inside postgres django is going to use
          value = aws_db_instance.main.db_name
        },
        {
          name  = "DB_USER" # Username to authenticate
          value = aws_db_instance.main.username
        },
        {
          name  = "DB_PASS" # Password to authenticate
          value = aws_db_instance.main.password
        },
        {
          name  = "ALLOWED_HOSTS" # A list of domain names allowed to make requests
          value = "*"
        }
      ]
      mountPoints = [
        {
          readOnly      = false # Django needs to be able to write files to this location to save static files
          containerPath = "/vol/web/static"
          sourceVolume  = "static"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group          = aws_cloudwatch_log_group.ecs_task_logs.name
          awslogs-region         = data.aws_region.current.name
          awslogs-stream-prefix = "api"
        }
      }
    },

    {
      name              = "proxy"             # The proxy is going to receive requests via HTTP, serve the static, and serve rest of request to app
      image             = var.ecr_proxy_image # Image is pulled from ecr
      essential         = true                # Container is essential to service, will restart if unhealthy
      memoryReservation = 256                 # Amount of memory reserved for this task, mustn't exceed 512
      user              = "nginx"             # Name of the user
      portMappings = [                        # What maps the network ports from container to the host
        {
          containerPort = 8000
          hostPort      = 8000
        }
      ]
      environment = [ # Enviroment variables set for the container, the host that the app is running on when we run the task
        {
          name  = "APP_HOST"
          value = "127.0.0.1"
        }
      ]
      mountPoints = [ # Where you map the volumes, static
        {
          readOnly      = true
          containerPath = "/vol/static"
          sourceVolume  = "static"
        }
      ]
      logConfiguration = { # Tells ecs where to store our logs
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs_task_logs.name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "proxy"
        }
      }
    }
  ])

  # Definition of containers that are going to the task

  volume {
    name = "static" # The volume available to our ECS task definition, docker volume
  }

  runtime_platform { # The type of server our containers are going to run on 
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
}

resource "aws_security_group" "ecs_service" {
  description = "Access rules for the ECS service"
  name        = "${local.prefix}-ecs-service"
  vpc_id      = aws_vpc.main.id

  # Outbound access to endpoints
  egress { # allows us to access endpoints which are on 443
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # RDS connectivity
  egress { # allows us to access our database
    from_port = 5432
    to_port   = 5432
    protocol  = "tcp"
    cidr_blocks = [
      aws_subnet.private_a.cidr_block,
      aws_subnet.private_b.cidr_block
    ]
  }

  # HTTP inbound access
  ingress { # allows anything from ports 8000 to enter, same port as proxy
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecs_service" "api" {                            # Resource to allow us to create an ecs service
  name                   = "${local.prefix}-api"              # Name of the ecs service 
  cluster                = aws_ecs_cluster.main.name          # Cluster we're adding service to
  task_definition        = aws_ecs_task_definition.api.family # Task definition we've defined aboce
  desired_count          = 1                                  # Number of running instances in our service
  launch_type            = "FARGATE"
  platform_version       = "1.4.0" # Versioning system fargate has
  enable_execute_command = true    # Allows us to run exec command on our running containers

  # Defines the network for our service
  # Public acces for now for our test, afterwards false because only access from load balancer
  network_configuration {
    assign_public_ip = true

    subnets = [
      aws_subnet.public_a.id,
      aws_subnet.public_b.id
    ]

    security_groups = [aws_security_group.ecs_service.id]
  }
}