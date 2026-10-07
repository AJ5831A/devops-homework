# IAM — Governance

AWS Identity and Access Management controls who can perform which actions on which resources. A **user** is an identity that can have long-lived credentials; a **group** collects users to attach common permissions. A **role** is assumed by trusted identities or services and supplies temporary credentials. Roles cannot be members of groups. A **policy** is a JSON permission document with effect, action, resource and optional conditions; permissions combine applicable policies and explicit denies take precedence.

Use **least privilege**: permit only required actions on named resources, refine using access analysis and remove unused permissions. Prefer federated human access through IAM Identity Center and roles for workloads. Protect the root user with MFA and avoid using root for daily tasks. Avoid committed access keys, rotate/revoke exposed credentials, and inspect CloudTrail for activity. Separate a role's trust policy (who may assume it) from its permission policy (what it may do).

Examples: an EC2 instance role reads a specific S3 prefix; a GitHub Actions OIDC role deploys from an approved repository/branch without stored AWS keys; a developer group holds limited sandbox permissions. `aws sts get-caller-identity` checks the active identity without printing credentials.

Reference: [AWS IAM introduction](https://docs.aws.amazon.com/IAM/latest/UserGuide/introduction.html).
