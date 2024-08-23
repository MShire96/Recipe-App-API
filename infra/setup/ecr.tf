##################################################
# Create ECR for repos for storing Docker Images #
##################################################

resource "aws_ecr_repository" "app" {
  name                 = "recipe-app-api-app"
  image_tag_mutability = "MUTABLE"
  # Allow to have latest tag, pushing different verisions of latest tag
  # Can change contents of latest tag
  force_delete = true
  # Terraform force delete this repo, dont do on production repo 

  image_scanning_configuration {
    # Note: Update to true for real deployment
    scan_on_push = false
    # Best practise true for real deployments 
    # Provides image scan when push new images onto repo
    # Scans for vulnerabilities
  }
}

resource "aws_ecr_repository" "proxy" {
  name                 = "recipe-app-api-proxy"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = false
  }
}