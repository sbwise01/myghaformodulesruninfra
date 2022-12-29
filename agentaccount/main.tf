terraform {
  required_version = ">= 1.0"

  backend "s3" {
    bucket = "brad-terraform-state-us-east-2"
    key    = "myghaformodulesruninfra.tfstate"
    region = "us-east-2"
  }
}

provider "aws" {
  region  = "us-east-2"
}

variable "gha_testing_account_id" {
  default = "238080251717"
}

variable "gha_agent_repo_url" {
  default = "https://github.com/sbwise01/terraform-aws-myghaformodules"
}

variable "gha_agent_token" {
}

variable "subnet_id" {
  default = "subnet-4a50ba23"
}

variable "admin_sg_cidr" {
  default = "98.97.8.169/32"
}

variable "admin_ssh_keypair_name" {
  default = "bwise"
}

data "aws_subnet" "selected" {
  id = var.subnet_id
}

resource "aws_iam_role" "ghaagent" {
  name               = "ghaagent-sandbox"
  assume_role_policy = data.aws_iam_policy_document.trust_policy.json
}

resource "aws_iam_instance_profile" "ghaagent" {
  name = "ghaagent-sandbox"
  role = aws_iam_role.ghaagent.name
}

data "aws_iam_policy_document" "trust_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "ghaagent_policy" {
  name   = "ghaagent-policy-sandbox"
  role   = aws_iam_role.ghaagent.id
  policy = data.aws_iam_policy_document.ghaagent_policy.json
}

data "aws_iam_policy_document" "ghaagent_policy" {
  statement {
    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]
    resources = ["arn:aws:iam::${var.gha_testing_account_id}:role/ghatesting-sandbox"]
  }
}

data "aws_ami" "amzn2" {
  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-2.0*-x86_64-gp2"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

resource "aws_instance" "ghaagent" {
  ami                    = data.aws_ami.amzn2.id
  iam_instance_profile   = aws_iam_instance_profile.ghaagent.name
  instance_type          = "t3.medium"
  key_name               = var.admin_ssh_keypair_name
  vpc_security_group_ids = [aws_security_group.ec2_allow.id]
  user_data_base64       = base64encode(templatefile("./templates/gha_agent_user_data.sh", {gha_agent_repo_url = var.gha_agent_repo_url, gha_agent_token = var.gha_agent_token}))

  tags = {
    Name       = "ghaagent-sandbox"
    CostCenter = "brad@foghornconsulting.com"
  }
}

resource "aws_security_group" "ec2_allow" {
  name   = "ghaagent-sandbox"
  vpc_id = data.aws_subnet.selected.vpc_id
}

resource "aws_security_group_rule" "ec2_ingress_instances_all" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = [var.admin_sg_cidr]
  security_group_id = aws_security_group.ec2_allow.id
}

resource "aws_security_group_rule" "ec2_ingress_instances_self" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.ec2_allow.id
  security_group_id        = aws_security_group.ec2_allow.id
}

resource "aws_security_group_rule" "ec2_egress_instances_all" {
  type              = "egress"
  from_port         = "0"
  to_port           = "65535"
  protocol          = "all"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ec2_allow.id
}
