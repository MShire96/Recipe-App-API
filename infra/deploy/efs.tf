#########################
# EFS for media storage #
#########################

resource "aws_efs_file_system" "media" { # It's kind of a wrapper we can use as a file system we can add resources to
  encrypted = true                       # Disk is encrypted when the files are at rest
  tags = {
    Name = "${local.prefix}-media"
  }
}

resource "aws_security_group" "efs" {
  name   = "${local.prefix}-efs"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port = 2049 # Inbound access to EFS, standard port number for EFS
    to_port   = 2049 # What we need our app in order access the mount points we will add
    protocol  = "tcp"

    security_groups = [ # We want only ecs_service to access our efs file system
      aws_security_group.ecs_service.id
    ]
  }
}

resource "aws_efs_mount_target" "media_a" {
  file_system_id  = aws_efs_file_system.media.id
  subnet_id       = aws_subnet.private_a.id
  security_groups = [aws_security_group.efs.id]
}

resource "aws_efs_mount_target" "media_b" {
  file_system_id  = aws_efs_file_system.media.id
  subnet_id       = aws_subnet.public_b.id
  security_groups = [aws_security_group.efs.id]
}

resource "aws_efs_access_point" "media" {       # Its a way you can split up the locations inside your EFS
  file_system_id = aws_efs_file_system.media.id # And give different access to different things
  root_directory {                              # We're creating one access as we only need one as we're going to store files for our media
    path = "/api/media"                         # All in that location

    creation_info {     # For when the file system are created, need to specify yhe permissions of who can access that in term of linux user ID
      owner_gid   = 101 # Our user, defined in docker with UID 101, to have these owner permissions
      owner_uid   = 101
      permissions = "755" # chmod permissions 
    }
  }
}