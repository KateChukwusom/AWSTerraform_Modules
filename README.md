# AWS Terraform Modules

A collection of reusable Terraform modules for provisioning AWS infrastructure. Each module is built to be referenced and composed by consuming projects through variables alone — no module needs to be cloned and edited to be used.

As more modules are added to this repository, each one follows the same pattern: its own top-level folder, its own `README.md`, and its own `examples/` subfolder showing a real, working composition.

## Available modules

| Module | Description | Docs |
|--------|-------------|------|
| [`IAM`](./IAM) | Reusable AWS IAM module for users, groups, roles, and policies | [IAM/README.md](./IAM/README.md) |

## Design philosophy

Every module in this repository follows the same principles:

- **Nothing is hardcoded.** No resource names, identities, or environment-specific values live inside a module's own code, everything comes in through variables.
- **Optional features default to empty.** A consuming project only pays for what it actually uses; unused sections of a module simply create nothing.
- **Validated at `plan` time.** Variables include validation blocks wherever a mistake (a typo, an invalid value) could otherwise surface as a confusing AWS API error or, worse, succeed silently with the wrong result.
- **Composable, not forkable.** Modules are meant to be referenced from your own project and driven by your own `.tfvars`  not cloned and modified. If a module doesn't support something you need, that's a signal to open an issue or pull request here.

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.5.0
- An AWS account and credentials configured locally (via `aws configure`, environment variables, or an assumed role)
- Familiarity with HCL syntax, `for_each`/`count`, and the Terraform state model is assumed, each module's own README covers its specific resources and variables in depth

## Using a module from this repository

See the individual module's README for its full variable reference and usage examples. In general, a module here is referenced the same way as any Terraform module:

```hcl
module "example" {
  source = "git::https://github.com/<your-username>/AWSTerraform_Modules.git//IAM"

  # variables go in here
}
```

Pin to a specific release tag if you want your project insulated from future changes until you deliberately upgrade:

```hcl
source = "git::https://github.com/<your-username>/AWSTerraform_Modules.git//IAM?ref=v1.0.0"
```

## Examples

Every module includes an `examples/` folder with a complete, runnable composition, real variable values, a working `terraform.tfvars`, and its own README walking through what gets created and why. These examples are the fastest way to see a module in action before integrating it into your own project.

## Contributing

Issues and pull requests are welcome. If you're proposing a change to an existing module, please update its `examples/` folder and README to reflect the change, so the documentation and the working example never drift apart.

