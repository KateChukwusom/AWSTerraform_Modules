variable "region" {
  type = string
}

variable "team" {
  type = string
}

variable "environment" {
  type = string
}

variable "iam_users" {
  type = list(string)
}

variable "cob-user-policy-statements" {
  type = map(list(object({
    effect = string
    actions = list(string)
    resources = list(string)
  })))
}

variable "cob_iam_group_name" {
  type = string
}

variable "selected_group_members" {
  type        = list(string)
}

variable "cob-group-policy-statements" {
  type = list(object({
    effect = string
    actions = list(string)
    resources = list(string)
  }))
}

variable "cob_iam_assume_role" {
  type = map(object({
    trusted_principal_type = string
    trusted_identifiers = list(string)
  }))
}

variable "cob_iam_role_policy_statements" {
  type = map(list(object({
      effect = string
      actions = list(string)
      resources = list(string)
     
    })))
}