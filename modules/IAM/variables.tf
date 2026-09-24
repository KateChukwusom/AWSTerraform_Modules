

#The name of the team 
variable "team" {
  type = string  
  description = "The team that affliates the user"
  validation {
    condition = length(var.team) <= 20
    error_message = "team must be 20 characters or fewer"
  }
}

#Deployment environment
variable "environment" {
  type = string  
  description = "Current environment"
  validation {
    condition = contains(["dev", "prod"], var.environment)
    error_message = "Environment must be dev or prod, it must be spelt that way"
  }
}

#IAM users to be created, it defaults to nothing incase of no users needed
variable "iam_users" {
  type = list(string)
  description = "The names of the IAM user to be created"
  default = []
  validation {
    condition = length(var.iam_users) == length(toset(var.iam_users))
    error_message = "Iam users must not have duplicates"
  }
}

#The following variable block is for individual user policy that do not want to be added to a group

#This is an example of how to use compose this variable(this is a list of map of objects, a map of list of objects) 
# iam_users = ["kate", "john"]

# cob-user-policy-statements = {
#   kate = [
#     {
#       effect    = "Allow"
#       actions   = ["ec2:*"]
#       resources = ["*"]
#     },
#     {
#       effect    = "Allow"
#       actions   = ["s3:GetObject", "s3:PutObject"]
#       resources = ["*"]
#     }
#   ]
#   john = [
#         {effect = "Allow"
#         actions = ["s3:PutObject"]
#         resources = ["*"]
#         }
#         ]

#You can write multiple permission statements for a single user or multiple users
variable "cob-user-policy-statements" {
  type = map(list(object({
    effect = string
    actions = list(string)
    resources = list(string)
  })))
  description = "This creates the permission policies to be attached to the users in a json format"
  default = {}


  validation {
    condition = alltrue([
      for username, statements in var.cob-user-policy-statements :
      alltrue([for s in statements : contains(["Allow", "Deny"], s.effect)])
    ])
    error_message = "Each statement's effect must be either \"Allow\" or \"Deny\"."
  }

  validation {
    condition     = alltrue([for username, statements in var.cob-user-policy-statements : contains(var.iam_users, username)])
    error_message = "Every key in cob-user-policy-statements must be a username that also appears in iam_users."
  }
}

#name of IAM group to be created
variable "cob_iam_group_name" {
  type = string
  description = "This is the name of the group created"
  validation {
    condition = length(var.cob_iam_group_name) > 0 && length(var.cob_iam_group_name) <= 128 && can(regex("^[A-Za-z0-9+=,.@_-]+$", var.cob_iam_group_name))
    error_message = "cob_iam_group_name must be 1-128 characters and contain only letters, digits, and the characters + = , . @ _ -"
  }
}

#This variable block is for some users that are to added to the group being created instead of adding all users to the group
variable "selected_group_members" {
  type        = list(string)
  description = "Usernames to add to this group"
  default     = []
  validation {
    condition     = alltrue([for u in var.selected_group_members : contains(var.iam_users, u)])
    error_message = "Every name in selected_group_members must also appear in iam_users."
  }
}

#These are permission policy statements that define permissions allocated to groups only
variable "cob-group-policy-statements" {
  type = list(object({
    effect = string
    actions = list(string)
    resources = list(string)
  }))
  description = "This creates the permission policies to be attached to the users in a json format"
  default = []

   validation {
    condition     = alltrue([for s in var.cob-group-policy-statements : contains(["Allow", "Deny"], s.effect)])
    error_message = "Each statement's effect must be either \"Allow\" or \"Deny\"."
  }

  validation {
    condition     = alltrue([for s in var.cob-group-policy-statements : length(s.actions) > 0 && length(s.resources) > 0])
    error_message = "Each statement must have at least one action and one resource."
  }
}


# The folllowing variables are used to create IAM role resources
# This is what it should look like:

# cob_iam_roles = {
#   ec2-role = {
#     trusted_principal_type = "Service"
#     trusted_identifiers    = ["ec2.amazonaws.com"]
#   }
#   lambda-role = {
#     trusted_principal_type = "Service"
#     trusted_identifiers    = ["lambda.amazonaws.com"]
#   }
# }

variable "cob_iam_assume_role" {
  type = map(object({
    trusted_principal_type = string
    trusted_identifiers = list(string)
  }))
  description = "This describes the roles created, the identity that assumes the role"
  default = {}
  validation {
    condition = alltrue([
      for role_name, role in var.cob_iam_assume_role :
      contains(["Service", "AWS", "Federated"], role.trusted_principal_type)
    ])
    error_message = "trusted_principal_type must be one of: \"Service\", \"AWS\", or \"Federated\"."
  }

  validation {
    condition     = alltrue([for role_name, role in var.cob_iam_assume_role : length(role.trusted_identifiers) > 0])
    error_message = "Each role must have at least one trusted_identifier."
  }

  }

  variable "cob_iam_role_policy_statements" {
    type = map(list(object({
      effect = string
      actions = list(string)
      resources = list(string)
     
    })))
    description = "This is the permissions policy that is attached to the role resource, it defines what an identity can do"
     default = {}

     validation {
    condition = alltrue([
      for role_name, statements in var.cob_iam_role_policy_statements :
      alltrue([for s in statements : contains(["Allow", "Deny"], s.effect)])
    ])
    error_message = "Each statement's effect must be either \"Allow\" or \"Deny\"."
  }

  validation {
    condition     = alltrue([for role_name, statements in var.cob_iam_role_policy_statements : contains(keys(var.cob_iam_assume_role), role_name)])
    error_message = "Every key in cob_iam_role_policy_statements must match a role name defined in cob_iam_roles."
  }
  }

variable "instance_profiles" {
  description = "Map of instance profile name to the IAM role key it attaches to"
  type        = map(string)
  default = {}
    validation {
    condition     = alltrue([for profile_name, role_name in var.instance_profiles : contains(keys(var.cob_iam_assume_role), role_name)])
    error_message = "Every role name in instance_profiles must match a key defined in cob_iam_roles."
  }
}

