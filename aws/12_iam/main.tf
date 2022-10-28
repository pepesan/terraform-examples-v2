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

