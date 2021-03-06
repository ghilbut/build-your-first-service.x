output github_www_aws_access_key_id {
  value = aws_iam_access_key.github.id
}

output github_www_aws_secret_access_key {
  value = aws_iam_access_key.github.secret
}

output test {
  value = data.terraform_remote_state.mysql.outputs.mysql_development_address
}
