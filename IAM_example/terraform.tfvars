region = "us-east-1"
team = "platform"
environment = "dev"
iam_users = ["Mark", "Gabriel", "Joshua"]
cob-user-policy-statements = {
   Joshua = [
        { 
            effect = "Allow",
            actions = ["s3:GetObject"]
            resources = ["arn:aws:s3:::platform-dev-reports/*"]
        }]}

cob_iam_group_name = "Developers"

selected_group_members = ["Mark", "Gabriel"]

cob-group-policy-statements = [{
  actions = [ "ec2:Describe*", "ec2:StartInstances", "ec2:StopInstances"]
  effect = "Allow"
  resources = [ "*" ]
}]

cob_iam_assume_role = {
   ec2_app_role = {
    trusted_principal_type = "Service"
    trusted_identifiers = ["ec2.amazonaws.com"]
   }
   ci_cd_deploy_role = {
    trusted_principal_type = "AWS"
    trusted_identifiers = ["arn:aws:iam::123456789012:user/Junior-Cloud-Administrator"]
   }
}

cob_iam_role_policy_statements = {
    ec2_app_role = [{
      actions = [ "s3:GetObject", "s3:PutObject", "s3:ListBucket" ]
      effect = "Allow"
      resources = [ "arn:aws:s3:::platform-dev-app-data",
                    "arn:aws:s3:::platform-dev-app-data/*" ]
    }]
    ci_cd_deploy_role  = [ {
        effect = "Allow"
     actions   = ["ecr:GetDownloadUrlForLayer",
                     "ecr:BatchGetImage",
                    "ecr:GetAuthorizationToken"]
  resources = ["*"]
    }]}