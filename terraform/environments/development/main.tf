locals {
  tags = {
    organization = var.organization
    owner = "terraform"
    "terraform:workspace" = "development:${terraform.workspace}"
  }
}


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
