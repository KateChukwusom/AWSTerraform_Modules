terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.region
}

module "IAM" {
  source = "../modules/IAM"
  team                            = var.team
  environment                     = var.environment
  iam_users                       = var.iam_users
  cob-user-policy-statements      = var.cob-user-policy-statements
  cob_iam_group_name              = var.cob_iam_group_name
  selected_group_members          = var.selected_group_members
  cob-group-policy-statements     = var.cob-group-policy-statements
  cob_iam_assume_role             = var.cob_iam_assume_role
  cob_iam_role_policy_statements  = var.cob_iam_role_policy_statements
}