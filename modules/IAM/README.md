# REUSABLE IAM Module

A reusable Terraform module for creating AWS IAM users, groups, and roles  built so any team can compose their own identities and permissions purely through variables, with no changes to the module's code.

## Why this module exists

Manually clicking through the AWS console (or hand-writing a Terraform resource per person) doesn't scale, and it doesn't compose. This module lets a consuming team define "WHO" needs access and "WHAT" they need, entirely in their own `.tfvars`, and get a fully wired set of IAM resources ;users, group membership, individual policies, roles, and instance profiles  without touching this module's internals.

## Design principles

- **Nothing is hardcoded.** No username, group name, or role identity lives inside the module itself, every identity comes in through a variable.
- **Everything optional has an empty default.** A team that doesn't need individual user policies, roles, or instance profiles simply omits that variable  nothing breaks, nothing is forced on them.
- **`for_each` over one-off resources.** Every resource that can repeat (users, per-user policies, roles) is built with `for_each`, so scaling from 1 user to 100 requires no code changes, only more data.
- **Validation catches mistakes before `apply`.** Every variable that could reasonably contain bad input (a typo'd role name, a duplicate username, an invalid `effect`) is checked at `plan` time, so mistakes surface immediately with a clear message instead of a AWS API error.

---

## Variables

### `team` (string, required)

The team that wants users appears as a tag on every created user. Validated to be 30 characters or fewer.

### `environment` (string, required)

Deployment environment. Restricted to `"dev"` or `"prod"`. Catches typos like `"production"` or `"staging"` before they create mismatched infrastructure.

### `iam_users` (list(string), default: `[]`)

Usernames to create as IAM users. Defaults to empty — a team that only wants roles, with no human users, can skip this entirely. Validated for uniqueness (no duplicate names).

### `cob_iam_group_name` (string, required)

Name of the IAM group created. Required — no sensible default exists for a group name. Validated against AWS's actual naming rule: 1–128 characters, letters/digits/`+=,.@_-` only.

### `selected_group_members` (list(string), default: `[]`)

This determines which of the users in `iam_users` should actually join the group. Kept separate from `iam_users` deliberately because "who should exist" and "who belongs in this group" are different questions. Validated: every name here must also appear in `iam_users`.

### `cob-group-policy-statements` (list(object), default: `[]`)

Permission statements attached to the group, applies to every group member equally. Validated: `effect` must be `"Allow"` or `"Deny"`; every statement needs at least one action and one resource.

```hcl
cob-group-policy-statements = [
  {
    effect    = "Allow"
    actions   = ["ec2:Describe*"]
    resources = ["*"]
  }
]
```

### `cob-user-policy-statements` (map(list(object)), default: `{}`)

Per-user permission statements, this is ayered on top of whatever the group grants. Keyed by username; a user with no entry here gets only group-level permissions. Validated: every `effect` is `"Allow"`/`"Deny"`, and every key must exist in `iam_users`.

```hcl
cob-user-policy-statements = {
  maya = [
    { effect = "Allow", actions = ["ec2:*"], resources = ["*"] },
    { effect = "Allow", actions = ["s3:GetObject", "s3:PutObject"], resources = ["*"] }
  ]
  yama = [
    { effect = "Allow", actions = ["s3:PutObject"], resources = ["*"] }
  ]
}
```

### `cob_iam_roles` (map(object), default: `{}`)

Roles to create, keyed by role name. Each entry defines the role's trust relationship this who or what is allowed to assume it. Validated: `trusted_principal_type` must be `"Service"`, `"AWS"`, or `"Federated"`; every role needs at least one identifier.

```hcl
cob_iam_roles = {
  ec2-role = {
    trusted_principal_type = "Service"
    trusted_identifiers    = ["ec2.amazonaws.com"]
  }
  lambda-role = {
    trusted_principal_type = "Service"
    trusted_identifiers    = ["lambda.amazonaws.com"]
  }
}
```

### `cob_iam_role_policy_statements` (map(list(object)), default: `{}`)

What each role is allowed to do once assumed. Keyed by role name, must match a key in `cob_iam_roles`. Validated the same way as group/user policy statements, plus a cross-check that every key exists in `cob_iam_roles`.

```hcl
cob_iam_role_policy_statements = {
  ec2-role = [
    { effect = "Allow", actions = ["s3:GetObject"], resources = ["*"] }
  ]
}
```

### `instance_profiles` (map(string), default: `{}`)

Which roles should get an EC2 instance profile, and what each profile should be named. Keyed by the instance profile name, with the value being the role name it attaches to (must match a key in `cob_iam_roles`). Required if an EC2 instance needs to actually carry the role at launch.

The name and the role are kept as separate parts of the same entry — rather than assuming the profile name is the role name so a mismatched or misspelled role key fails at `plan` time with a clear error, instead of silently producing a broken profile. Validated: every value must exist as a key in `cob_iam_roles`.

---

## Outputs

| Output | Description |
| --- | --- |
| `user_names` | List of created IAM usernames |
| `user_arns` | Map of username → user ARN |
| `group_name` | Name of the created group |
| `group_arn` | ARN of the created group |
| `role_arns` | Map of role name → role ARN |
| `role_names` | Map of role name → role name |
| `instance_profile_names` | Map of role name → instance profile name |
| `instance_profile_arns` | Map of role name → instance profile ARN |

---

## Writing policy statements: actions reference

Every policy statement follows the same shape — `effect`, `actions`, `resources` but the action strings are specific to each AWS service, and typing them by hand from memory is how typos slip in. Below are the most commonly needed actions for popular services, so you don't need to go through the console.

**Format:** `service:ActionName`, the wildcard `*` matches any suffix (e.g. `ec2:Describe*` matches every read-only EC2 describe call).

### EC2

| Action | What it allows |
| --- | --- |
| `ec2:Describe*` | Read-only visibility into all EC2 resources (instances, volumes, AMIs, etc.) |
| `ec2:RunInstances` | Launch new instances |
| `ec2:TerminateInstances` | Terminate instances |
| `ec2:StartInstances` / `ec2:StopInstances` | Start/stop instances |
| `ec2:*` | Full EC2 access |

### S3

| Action | What it allows |
| --- | --- |
| `s3:GetObject` | Read/download an object |
| `s3:PutObject` | Upload/overwrite an object |
| `s3:DeleteObject` | Delete an object |
| `s3:ListBucket` | List objects in a bucket (note: this is a *bucket*-level permission, not object-level — needs the bucket ARN, not `bucket/*`) |
| `s3:*` | Full S3 access |

### DynamoDB

| Action | What it allows |
| --- | --- |
| `dynamodb:GetItem` | Read a single item |
| `dynamodb:PutItem` | Write/overwrite an item |
| `dynamodb:Query` / `dynamodb:Scan` | Query or scan a table |
| `dynamodb:DeleteItem` | Delete an item |
| `dynamodb:*` | Full DynamoDB access |

### IAM (for roles that manage other IAM resources)

| Action | What it allows |
| --- | --- |
| `iam:PassRole` | Required for a role/user to hand a role to a service (e.g. attaching a role to an EC2 instance) |
| `iam:GetRole` | Read a role's details |
| `iam:ListRoles` | List roles in the account |

### Lambda

| Action | What it allows |
| --- | --- |
| `lambda:InvokeFunction` | Invoke a function |
| `lambda:GetFunction` | Read function configuration |
| `lambda:UpdateFunctionCode` | Deploy new code to a function |

### Resources field

`resources = ["*"]` applies to everything of that service. To scope tightly, use the resource's ARN instead — e.g.:

```hcl
resources = ["arn:aws:s3:::my-bucket/*"]
resources = ["arn:aws:dynamodb:us-east-1:123456789012:table/my-table"]
```

**Full authoritative reference:** AWS publishes the complete, current list of every action per service, this is the source of truth if something isn't covered above:
[Actions, resources, and condition keys for AWS services](https://docs.aws.amazon.com/service-authorization/latest/reference/reference_policies_actions-resources-contextkeys.html)

---

## A note on validation

Every variable in this module includes a `validation` block that checks either **content validity** (is this an allowed value, like `effect` being `"Allow"`/`"Deny"`) or **cross-reference validity** (does this key/name actually exist in the other variable it depends on, like a `selected_group_members` entry existing in `iam_users`). These run at `terraform plan`, before any AWS API call, catching mistakes immediately instead of letting them surface as a confusing AWS error, or worse, silently succeed with the wrong result.
