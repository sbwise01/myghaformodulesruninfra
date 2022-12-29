terraform {
  required_version = ">= 1.0"

  backend "s3" {
    bucket = "bw-terraform-state-us-east-2"
    key    = "myghaformodulesruninfra.tfstate"
    region = "us-east-2"
  }
}

provider "aws" {
  region  = "us-east-2"
}

variable "gha_agent_account_id" {
  default = "509680183794"
}

resource "aws_iam_role" "ghatesting" {
  name               = "ghatesting-sandbox"
  assume_role_policy = data.aws_iam_policy_document.trust_policy.json
}

data "aws_iam_policy_document" "trust_policy" {
  statement {
    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.gha_agent_account_id}:role/ghaagent-sandbox"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ghatesting-policy-attachment" {
  role       = aws_iam_role.ghatesting.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
