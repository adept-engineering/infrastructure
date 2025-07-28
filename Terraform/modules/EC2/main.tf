resource "aws_instance" "this" {
  ami                    = data.aws_ami.linux.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  key_name               = var.key_name
  iam_instance_profile   = var.iam_instance_profile
  user_data              = var.user_data
  vpc_security_group_ids = [var.security_group_id]
  tags = {
    Name        = "acqua-ec2-${var.environment}"
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "Terraform"
    Owner       = var.owner
  }
  root_block_device {
    encrypted = true
  }
  lifecycle {
    prevent_destroy = var.environment == "prod" ? true : false
  }
}

resource "aws_ebs_volume" "data" {
  availability_zone = aws_instance.this.availability_zone
  size              = var.ebs_volume_size
  encrypted         = true
  tags = {
    Name        = "acqua-ebs-${var.environment}"
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "Terraform"
    Owner       = var.owner
  }
}

resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/xvdb"
  volume_id   = aws_ebs_volume.data.id
  instance_id = aws_instance.this.id
}

data "aws_ami" "linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}
