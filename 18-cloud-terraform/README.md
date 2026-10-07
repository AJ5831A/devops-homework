# Cloud & Terraform in Action — Session 19

The [Terraform project](terraform-vpc/) implements the PDF's full suggested architecture: VPC, subnet, security group, EC2 and S3. It extends the reference's VPC/network-only implementation with a working Nginx EC2 bootstrap and private object storage. Terraform formatting, initialization and validation passed in hosted CI ([evidence](../evidence/infrastructure/README.md)). The real AWS lifecycle completed on 7 October 2026: eleven resources created, Nginx HTTP and security settings verified, no-change plan confirmed, and all eleven resources destroyed. [Runtime evidence](../evidence/aws/18-vpc-ec2-20261007T153930Z/README.md) includes a live browser screenshot and independent deletion checks.

```mermaid
flowchart TD
  TF[Terraform AWS provider] --> VPC[VPC 10.20.0.0/16]
  VPC --> SUB[Public subnet 10.20.1.0/24]
  VPC --> IGW[Internet Gateway]
  SUB --> RT[Default route to Internet Gateway]
  SUB --> EC2[EC2 Amazon Linux / Nginx]
  SG[Security group: learner CIDR port 80] --> EC2
  TF --> S3[Private encrypted versioned S3]
  Browser[Browser on allowed learner network] --> EC2
```

S3 is a separate regional service, not a resource inside the subnet. The EC2 web page is served from its root disk; no EC2-to-S3 permission is needed for this demo.

## Implementation

- **Provider:** `hashicorp/aws` with region and common tags; version constraints are explicit.
- **Variables:** region, EC2 instance type, allowed HTTP CIDR and bucket prefix.
- **Data sources:** an available zone and an Amazon-owned AL2023 x86_64 AMI, avoiding hard-coded account-specific IDs.
- **Resources:** VPC, public subnet, Internet Gateway, route table/association, security group, EC2, encrypted root disk and secured S3 bucket.
- **Dependencies:** references connect subnet → VPC and EC2 → subnet/security group. An explicit dependency waits for the route association before bootstrapping packages.
- **Outputs:** VPC/subnet/instance IDs, web URL and bucket name.
- **State:** Terraform records resource IDs and configuration bindings locally. Do not commit state or plans; preserve state until destroy finishes. For teams use a separately bootstrapped secured remote backend with locking, not the bucket that this same root module destroys.

## Run and verify

Requires Terraform >=1.6, authenticated AWS CLI and permission to create these resources. EC2, EBS, public IPv4 and S3 may incur charges; destroy the lab afterward.

```bash
cd terraform-vpc
cp terraform.tfvars.example terraform.tfvars
# Edit http_cidr to your actual public IPv4 /32 before planning.
export AWS_PROFILE=devops-lab
# Bridge AWS CLI login credentials to the Terraform 5.x AWS provider.
# This evaluates trusted AWS CLI exports; do not print the values or use shell xtrace.
eval "$(aws configure export-credentials --profile "$AWS_PROFILE" --format env)"
aws sts get-caller-identity
terraform init
terraform fmt
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
terraform show
terraform output
aws ec2 wait instance-status-ok --instance-ids "$(terraform output -raw instance_id)"
# Cloud-init package installation may take a few additional minutes.
curl --fail --retry 12 --retry-delay 10 --retry-connrefused "$(terraform output -raw web_url)"
aws s3api get-public-access-block --bucket "$(terraform output -raw bucket_name)"
terraform plan
terraform destroy
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN AWS_CREDENTIAL_EXPIRATION
```

The captured runner bridges AWS CLI login sessions by reading `export-credentials --format process` JSON into memory and passing temporary credentials to Terraform child processes. The shell equivalent above avoids depending on direct login-cache support in the AWS provider 5.x. Credentials, state and plans are excluded from published evidence.

Observed verification: HTTP returned `Hello from Terraform on AWS`; S3 blocked public access, enabled versioning and used AES256 encryption; EC2 required IMDSv2 and used an encrypted root volume. A second plan showed no changes. [Captured evidence](../evidence/aws/18-vpc-ec2-20261007T153930Z/README.md) includes init, validate, plan, apply, show, output and destroy. Cleanup left empty Terraform state; AWS reported the instance terminated, the bucket 404, and the VPC and root volume absent. The bucket was kept empty because force deletion is disabled.

![Live AWS Nginx application](../evidence/aws/18-vpc-ec2-20261007T153930Z/web-browser.png)

![Recorded AWS Terraform apply](../evidence/aws/18-vpc-ec2-20261007T153930Z/apply.png)

![Recorded AWS Terraform destroy](../evidence/aws/18-vpc-ec2-20261007T153930Z/destroy.png)

## Troubleshooting

| Symptom | Investigation | Resolution |
|---|---|---|
| Credentials error | `aws sts get-caller-identity` | Sign into the intended profile and export it in the Terraform shell. |
| HTTP timeout | Check current public IP, SG, subnet route, public IP and instance status. | Set the correct `/32`, apply changes, and allow bootstrap time. |
| HTTP connection refused | Inspect EC2 console/system log for cloud-init and `dnf` failure. | Fix bootstrap/network access, then `terraform apply -replace=aws_instance.web`. |
| AMI/type mismatch | Compare AMI architecture with instance type. | Use an x86_64 type with the supplied AMI filter. |
| BucketNotEmpty on destroy | Inspect versions/delete markers. | Deliberately remove lab objects/versions, then retry destroy. |

This lab uses HTTP and a single public instance to demonstrate dependencies; it has no TLS, load balancer, HA or cluster. A newly published matching AMI can produce a replacement plan because the lookup uses `most_recent`; review each plan or pin an AMI for repeatable longer-lived deployments.

References: [Terraform AWS getting started](https://developer.hashicorp.com/terraform/tutorials/aws-get-started), [AWS VPC](https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html).
