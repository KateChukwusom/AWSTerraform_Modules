locals {
  # This is the base combination, reused everywhere
  team_environment = "${var.team}-${var.environment}"

  # tags applied to resource blocks that allows tags argument
  resource_tags = {
    Team        = var.team
    Environment = var.environment
  }
}

#This creates iam users, as many as needed, the for_each argument loops over the users and creates them each
resource "aws_iam_user" "cob-iamusers" {
  for_each = toset(var.iam_users)
  name = each.value
  tags = local.resource_tags
}

#This creates iam users login profile along side
resource "aws_iam_user_login_profile" "cob-loginuser-profile" {
  for_each = aws_iam_user.cob-iamusers
  user    = each.value.name
  
}

#This creates permission policy document in json file for each user
data "aws_iam_policy_document" "cob-user-policy-document" {
  for_each = var.cob-user-policy-statements

  dynamic "statement" {
    for_each = each.value
    content {
      effect = statement.value.effect
      actions = statement.value.actions
      resources = statement.value.resources
    }
  }
}

#This creates the user permissions policy to be attached to individual users
resource "aws_iam_policy" "cob-user-policy" {
  for_each = var.cob-user-policy-statements
  name = "${local.team_environment}-${each.key}-policy"
  policy = data.aws_iam_policy_document.cob-user-policy-document[each.key].json
}

#This attaches the permissions policy document to the users that are created and not added to a group
resource "aws_iam_user_policy_attachment" "user_policy_attachment" {
  for_each = var.cob-user-policy-statements

  user       = each.key
  policy_arn = aws_iam_policy.cob-user-policy[each.key].arn
}


#This creates iam group
resource "aws_iam_group" "cob-group" {
  name = "${local.team_environment}-${var.cob_iam_group_name}"
  
}

#This automatically adds users that are created to the group being created.
#The variable called selected group members, exist to add to the group only selected members and not all users in cases where it applies
#note all selected group members must be a user already existing

resource "aws_iam_user_group_membership" "cob-user-group" {
  for_each = toset(var.selected_group_members)

  user = aws_iam_user.cob-iamusers[each.value].name
  groups = [
    aws_iam_group.cob-group.name
  ]
}

#This creates permission policy statements in json file for the group(s) to the created
data "aws_iam_policy_document" "cob_group_policy_document" {
 dynamic "statement" {
   for_each = var.cob-group-policy-statements
   content {
     effect = statement.value.effect
     actions = statement.value.actions
     resources = statement.value.resources
   }
 }
}

#This creates the group policy resource
resource "aws_iam_policy" "cob-group-policy" {
  name        = "${local.team_environment}-${var.cob_iam_group_name}-policy"
  policy = data.aws_iam_policy_document.cob_group_policy_document.json
  tags = local.resource_tags
}

#This attaches the group policy being created to the group
resource "aws_iam_group_policy_attachment" "cob-group-policy-attachment" {
  group      = aws_iam_group.cob-group.name
  policy_arn = aws_iam_policy.cob-group-policy.arn
}

#This following creates resources for IAM role, trusted policy and permissions policy
#This creates the json document for trust Assume role policy
data "aws_iam_policy_document" "cob_trust_policy" {
  for_each = var.cob_iam_assume_role
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = each.value.trusted_principal_type
      identifiers = each.value.trusted_identifiers

  }
}
}

#This creates the iam roles
resource "aws_iam_role" "cob_iamroles" {
  for_each = var.cob_iam_assume_role
  name               = each.key
  assume_role_policy = data.aws_iam_policy_document.cob_trust_policy[each.key].json
  tags = local.resource_tags
}

#This creates the json document for the role permission policy
data "aws_iam_policy_document" "cob_permissions_policy" {
  for_each = var.cob_iam_role_policy_statements
  dynamic "statement" {
    for_each = each.value
    content {
      effect    = statement.value.effect
      actions   = statement.value.actions
    resources = statement.value.resources
    }
  }
}
 #This create the resource, permissions policy document
resource "aws_iam_policy" "cob_role_policy" {
  for_each = var.cob_iam_role_policy_statements
  name        = "${local.team_environment}-${each.key}-policy"
  policy      = data.aws_iam_policy_document.cob_permissions_policy[each.key].json
  tags = local.resource_tags
}

#This attaches the policy to the role 
resource "aws_iam_role_policy_attachment" "cob_role_attachment" {
  for_each = var.cob_iam_role_policy_statements
  role       = aws_iam_role.cob_iamroles[each.key].name
  policy_arn = aws_iam_policy.cob_role_policy[each.key].arn
}

#This creates an instance profile 
resource "aws_iam_instance_profile" "cob_instance_profile" {
  for_each = var.instance_profiles
  name     = "${local.team_environment}-${each.key}"
  role     = aws_iam_role.cob_iamroles[each.value].name
}



