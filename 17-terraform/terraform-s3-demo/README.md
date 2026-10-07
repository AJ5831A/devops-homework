# Task 1: Terraform S3 Demo

This project creates a private, versioned, AES-256 encrypted S3 bucket. `provider.tf` pins a compatible AWS provider major version; variables are defined separately; `main.tf` describes resources; outputs expose the resulting name and ARN. `bucket_prefix` lets Terraform generate a unique name without borrowing another student's bucket or account details.

## Commands

Prerequisites: Terraform >=1.6, AWS CLI, and a logged-in AWS profile with permission to manage this lab's S3 resources. From this folder:

```bash
export AWS_PROFILE=your-lab-profile
aws sts get-caller-identity
terraform init
terraform fmt
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
terraform show
terraform output
aws s3api get-public-access-block --bucket "$(terraform output -raw bucket_name)"
aws s3api get-bucket-versioning --bucket "$(terraform output -raw bucket_name)"
aws s3api get-bucket-encryption --bucket "$(terraform output -raw bucket_name)"
terraform plan
terraform destroy
```

`init` installs providers; `fmt` normalizes code; `validate` checks configuration; `plan` previews changes; `apply` executes the saved plan; `show` displays state/resources; `output` reads declared outputs; `destroy` previews and removes managed infrastructure after confirmation. A second plan after successful apply should show no changes.

`terraform.tfvars` contains only non-secret lab defaults. Use the AWS credential chain (SSO/profile/environment) instead of putting credentials into Terraform. State maps configuration addresses to AWS resource IDs and can contain sensitive values. Keep `.terraform/`, state, plans and crash logs out of Git; commit `.terraform.lock.hcl` after a successful init. Local state is sufficient for this individual exercise; team use needs a secured remote backend with locking.

## Verification and evidence

Terraform formatting, initialization and validation passed in hosted CI; see [validation evidence](../../evidence/infrastructure/README.md). AWS plan/apply/destroy execution is pending because no authenticated AWS account is configured. Save your real `validate`, plan, apply, output, AWS verification and destroy results in an `evidence/` folder, redact account identifiers as needed, and capture the S3 console. No sample output here is represented as a successful execution.

The bucket starts empty. `force_destroy=false` prevents silently deleting uploaded objects. If you add objects, deliberately remove all versions and delete markers before destroy; deleting only current keys does not empty a versioned bucket. Retain the state until cleanup succeeds.

References: [Terraform AWS tutorial](https://developer.hashicorp.com/terraform/tutorials/aws-get-started), [provider configuration](https://developer.hashicorp.com/terraform/language/block/provider).
