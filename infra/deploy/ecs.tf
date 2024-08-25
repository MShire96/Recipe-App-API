#########################################
# ECS Cluster for running app on Fargate.
#########################################

resource "aws_ecs_cluster" "main" {
    name = "${local.prefix}-cluster"
}

# All we need to create a new cluster in AWS
# The cluster we'll be adding our services and our tasks to
# It'll be the wrapper around the other resources.