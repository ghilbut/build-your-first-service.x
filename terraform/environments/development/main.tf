locals {
  tags = {
    organization = var.organization
    owner = "terraform"
    "terraform:workspace" = "development:${terraform.workspace}"
  }
}


################################################################
##
##  logical database for stage
##

data terraform_remote_state mysql {
  backend   = "s3"
  workspace = "default"

  config = {
    bucket  = "byfs-terraform"
    key     = "databases.tfstate"

    profile = "byfs-terraform"
    region  = "ap-northeast-2"
    encrypt = true
  }
}


output endpoint {
  value = data.terraform_remote_state.mysql.outputs.mysql_development_endpoint
}
#output username {
#  value = data.terraform_remote_state.mysql.mysql_username
#}
#output password {
#  value = data.terraform_remote_state.mysql.mysql_password
#}


provider mysql {
  endpoint = data.terraform_remote_state.mysql.outputs.mysql_development_endpoint
  username = data.terraform_remote_state.mysql.outputs.mysql_username
  password = data.terraform_remote_state.mysql.outputs.mysql_password
}


resource mysql_database default {
  default_character_set = "utf8mb4"
  default_collation     = "utf8mb4_unicode_ci"
  name                  = var.db_name
}

resource mysql_user default {
  user               = var.db_username
  host               = "%"
  plaintext_password = var.db_password
}

resource mysql_grant default {
  user       = mysql_user.default.user
  host       = mysql_user.default.host
  database   = mysql_database.default.name
  privileges = ["ALL"]
}


################################################################
##
##  SPA hosting
##
/*
resource aws_s3_bucket www {
  bucket = "${var.www_domain}"
  acl    = "public-read"

  website {
    index_document = "index.html"
    error_document = "error.html"
  }

  tags = "${merge(
    map(
      "Name",  "${var.www_domain}",
      "stage", terraform.workspace,
    ),
    local.tags, 
  )}"
}


locals {
  iam_name = "byfs-s3-webhosting-${terraform.workspace}"
}

resource aws_iam_user hosting {
  name = local.iam_name
  path = "/byfs/"

  tags = "${merge(
    map(
      "Name",  local.iam_name,
      "stage", terraform.workspace,
    ),
    local.tags, 
  )}"
}

resource aws_iam_user_policy hosting {
  name = "github"
  user = aws_iam_user.hosting.name

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": "arn:aws:s3:::${var.www_domain}"
        }
    ]
}
EOF
}

resource aws_iam_access_key github {
  user = aws_iam_user.hosting.name
}


data aws_route53_zone public {
  name         = var.root_domain
  private_zone = false
}

resource aws_route53_record www {
  zone_id = data.aws_route53_zone.public.zone_id
  name    = var.www_domain
  type    = "A"

  alias {
    name    = aws_s3_bucket.www.website_domain
    zone_id = aws_s3_bucket.www.hosted_zone_id
    evaluate_target_health = true
  }
}
*/
