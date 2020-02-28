locals {
  tags = {
    organization = var.organization
    owner = "terraform"
    "terraform:environment" = "database"
  }
}


#data aws_vpc default {
#  default = true
#}


data aws_iam_user terraform {
  user_name = "byfs-terraform"
}

/*
resource aws_iam_user_policy rds {
  name = "byfs-terraform-rds"
  user = data.aws_iam_user.terraform.user_name

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "rds:*",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:AuthorizeSecurityGroupEgress",
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:DeleteSecurityGroup",
                "ec2:RevokeSecurityGroupEgress",
                "ec2:RevokeSecurityGroupIngress"
            ],
            "Resource": "arn:aws:ec2:*:*:security-group/*",
            "Condition": {
                "ArnEquals": {
                    "ec2:Vpc": "arn:aws:ec2:*:*:vpc/vpc-vpc-id"
                }
            }
        },
        {
            "Action": [
                "ec2:DescribeSecurityGroups",
                "ec2:DescribeSecurityGroupReferences",
                "ec2:DescribeStaleSecurityGroups",
                "ec2:DescribeVpcs"
            ],
            "Effect": "Allow",
            "Resource": "*"
        }
    ]
}
EOF
}
*/

resource aws_iam_user_policy rds {
  name = "byfs-terraform-rds"
  user = data.aws_iam_user.terraform.user_name

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "*",
            "Resource": "*"
        }
    ]
}
EOF
}



################################################################
##
##  RDS
##

resource aws_security_group development {
  depends_on = [
    aws_iam_user_policy.rds,
  ]

  name = "rds-sg-byfs-development"
  description = "Allow MySQL inbound traffic"

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }



  tags = merge(
    map(
      "Name",  "sg-byfs-rds-development",
    ),
    local.tags, 
  )
}


resource aws_db_parameter_group utf8mb4 {
  name   = "rds-pg-utf8mb4"
  family = "mysql5.7"

  parameter {
    name  = "character_set_client"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_connection"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_database"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_results"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  tags = merge(
    map(
      "Name",  "rds-pg-byfs",
    ),
    local.tags, 
  )
}


resource aws_db_instance development {
  depends_on = [
    aws_iam_user_policy.rds,
  ]

  allocated_storage     = 20
  availability_zone     = "ap-northeast-2a"
  storage_type          = "gp2"
  engine                = "mysql"
  engine_version        = "5.7"
  instance_class        = "db.t3.micro"
  name                  = "byfs"
  username              = var.db_username
  password              = var.db_password
  parameter_group_name  = aws_db_parameter_group.utf8mb4.id

  identifier = "rds-byfs-development"

  skip_final_snapshot = true
  publicly_accessible = true

  vpc_security_group_ids = [
    aws_security_group.development.id,
  ]

  tags = merge(
    map(
      "Name",  "rds-byfs-development",
      "purpose", "development",
    ),
    local.tags, 
  )
}


data aws_route53_zone public {
  name         = var.root_domain
  private_zone = false
}

resource aws_route53_record db {
  zone_id = data.aws_route53_zone.public.zone_id
  name    = "byfs-dev.db.${var.root_domain}"

  type    = "CNAME"
  ttl     = 5
  records = [
    aws_db_instance.development.address
  ]
}
