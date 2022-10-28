variable "region" {}

provider "aws" {
  region      = var.region
}


resource "aws_iam_user" "demouser" {
  name = "tuckerdemo"
}



resource "aws_iam_user" "demo" {
  count = 3
  name = "tuckerdemo.${count.index}"
}

resource "aws_iam_user" "example" {
  for_each = toset(["tucker3", "annie3", "josh3"])
  name     = each.value
}

variable "username2" {
  type = list(string)
  default = ["tucker2","annie2","josh2"]
}

resource "aws_iam_user" "demo2" {
  count = length(var.username2)
  name = element(var.username2,count.index )
}

resource "aws_iam_user_policy" "newemp_policy" {
  count = length(var.username2)
  name = "new"
  user = element(var.username2,count.index)
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:Describe*"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

output "user_arn" {
  value = aws_iam_user.demo.*.arn
}

output "user_arn_demo2" {
  value = aws_iam_user.demo2.*.arn
}

resource "aws_iam_group" "administrators" {
  name = "Administrators"
  path = "/"
}

data "aws_iam_policy" "administrator_access" {
  name = "AdministratorAccess"
}
resource "aws_iam_group_policy_attachment" "administrators" {
  group      = aws_iam_group.administrators.name
  policy_arn = data.aws_iam_policy.administrator_access.arn
}

resource "aws_iam_user" "administrator" {
  name = "Administrator"
}

resource "aws_iam_user_group_membership" "devstream" {
  user   = aws_iam_user.administrator.name
  groups = [aws_iam_group.administrators.name]
}

resource "aws_iam_user_login_profile" "administrator" {
  user                    = aws_iam_user.administrator.name
  password_reset_required = true
}

output "password" {
  value     = aws_iam_user_login_profile.administrator.password
  #sensitive = true
}


