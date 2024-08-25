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

  container_definitions = jsonencode([]) # Definition of containers that are going to the task

  volume {
    name = "static" # The volume available to our ECS task definition, docker volume
  }

  runtime_platform { # The type of server our containers are going to run on 
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
}