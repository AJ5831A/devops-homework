# Terraform & Infrastructure as Code — Session 18

- [Task 1: Terraform S3 demo](terraform-s3-demo/README.md): complete configuration and init → destroy workflow.
- [IAM](aws-services/01-iam/README.md)
- [EC2](aws-services/02-ec2/README.md)
- [S3](aws-services/03-s3/README.md)
- [VPC](aws-services/04-vpc/README.md)
- [DynamoDB and RDS](aws-services/05-dynamodb-rds/README.md)

Terraform formatting, provider initialization and validation passed. The real AWS S3 lifecycle also completed on 7 October 2026 in `ap-south-1`: four resources created, security settings verified, a no-change plan confirmed, and all four resources destroyed. The empty Terraform state and AWS bucket 404 independently verified cleanup. See [runtime evidence](../evidence/aws/17-s3-20261007T153930Z/README.md).
