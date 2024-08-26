#########################
# EFS for media storage #
#########################

resource "aws_efs_file_system" "media" { # It's kind of a wrapper we can use as a file system we can add resources to
  encrypted = true                       # Disk is encrypted when the files are at rest
  tags = {
    Name = "${local.prefix}-media"
  }
}

