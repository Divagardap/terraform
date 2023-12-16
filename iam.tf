resource "aws_iam_user" "lb" {
  name = "loadbalancer"
  path = "/system/"

  tags = {
    tag-key = "tag-value"
  }
}

resource "aws_iam_group" "tester" {
  name = "tester"
}

resource "aws_iam_user_group_membership" "example_membership" {
  user  = aws_iam_user.lb.name
  groups = [aws_iam_group.tester.name]
}

resource "aws_iam_account_password_policy" "strict" {
  minimum_password_length        = 8
  require_lowercase_characters   = true
  require_numbers                = true
  require_uppercase_characters   = false
  require_symbols                = false
  allow_users_to_change_password = true
}

resource "aws_iam_access_key" "lb" {
  user = aws_iam_user.lb.name
}

data "aws_iam_policy_document" "lb_ro" {
  statement {
    effect    = "Allow"
    actions   = ["ec2:Describe*"]
    resources = ["*"]
  }
}

resource "aws_iam_user_policy" "lb_ro" {
  name   = "test"
  user   = aws_iam_user.lb.name
  policy = data.aws_iam_policy_document.lb_ro.json
}

resource "aws_iam_user_login_profile" "lb" {
  user    = aws_iam_user.lb.name
  pgp_key = file("public.gpg")
}


output "password" {
  value = aws_iam_user_login_profile.lb.encrypted_password
}
