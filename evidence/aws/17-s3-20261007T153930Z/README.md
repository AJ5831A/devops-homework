# Assignment 17: real AWS S3 lifecycle

Aryan Jakhar · 24BCS10305. Region `ap-south-1`; authenticated profile `devops-lab`.
Executed 7 October 2026, 15:39–15:41 UTC. The isolated Terraform workspace,
state and binary plans were kept in a private temporary directory outside Git.
Account IDs were redacted from published command output. Screenshots render
actual captured command output and are labeled as such.

| Step | Actual evidence |
| --- | --- |
| Initialize and validate | [Init](init.txt), [validate](validate.txt) |
| Review create-only plan | [Plan](plan.txt): four resources to create |
| Apply | [Output](apply.txt), [screenshot](apply.png): four resources created |
| Inspect resources | [Terraform show](show.txt), [outputs](outputs.json) |
| Verify security | [Public-access blocking](s3-public-access.json), [versioning](s3-versioning.json), [AES256 encryption](s3-encryption.json) |
| Verify no drift | [Second plan](no-changes.txt): no changes |
| Destroy | [Destroy plan](destroy-plan.txt), [destroy result](destroy.txt), [screenshot](destroy.png): four resources destroyed |
| Verify cleanup independently | [Empty state list](state-after-destroy.txt), [bucket HTTP 404](bucket-after-destroy.txt), [cleanup PASS](cleanup-result.txt) |

[Complete chronological transcript](transcript.log) · [Verification PASS](verification-result.txt).

The bucket was kept empty; no user objects were uploaded or deleted. The 404
in the final check is the expected proof of deletion, not a failed create/run.

The runner used `aws configure export-credentials --profile devops-lab --format process`, parsed its credential JSON only in memory, and passed credentials through Terraform/AWS child-process environments. It did not assume AWS provider 5.x supports AWS CLI login-session cache files directly. Credential values were never included in the command transcript.
