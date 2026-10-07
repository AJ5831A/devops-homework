# Assignment 18: real AWS VPC, EC2 and S3 lifecycle

Aryan Jakhar · 24BCS10305. Region `ap-south-1`; authenticated profile `devops-lab`.
Executed 7 October 2026, 15:41–15:47 UTC. Terraform ran from a private temporary
workspace outside Git. Account IDs and the learner's public IP were redacted
from published output. Binary plans, state and credential values were not
committed. The EC2 public address in evidence was released during cleanup.

| Step | Actual evidence |
| --- | --- |
| Initialize and validate | [Init](init.txt), [validate](validate.txt) |
| Review create-only plan | [Plan](plan.txt): eleven managed resources to create |
| Apply | [Output](apply.txt), [screenshot](apply.png): eleven resources created |
| Inspect resources | [Terraform show](show.txt), [outputs](outputs.json) |
| Verify S3 controls | [Public-access blocking](s3-public-access.json), [versioning](s3-versioning.json), [AES256 encryption](s3-encryption.json) |
| Verify EC2 and disk | [Instance attributes](ec2-instance.json): IMDSv2 required; [root volume](ec2-volumes.json): encrypted |
| Verify application | [Actual HTTP response](http-response.html), [live browser screenshot](web-browser.png): Hello from Terraform on AWS |
| Verify no drift | [Second plan](no-changes.txt): no changes |
| Destroy | [Destroy plan](destroy-plan.txt), [result](destroy.txt), [screenshot](destroy.png): eleven resources destroyed |
| Check cleanup independently | [Empty state](state-after-destroy.txt), [bucket 404](bucket-after-destroy.txt), [terminated instance](instance-after-destroy.json), [absent VPC](vpc-after-destroy.txt), [absent root volume](volume-after-destroy.txt), [cleanup PASS](cleanup-result.txt) |

[Complete chronological transcript](transcript.log) · [Verification PASS](verification-result.txt).

The application used a `t3.micro` EC2 instance with an encrypted 8 GiB gp3
root disk. HTTP ingress was restricted to the learner's current public IPv4
`/32`; SSH was not opened. EC2 status checks passed before the HTTP test.
The bucket stayed empty, so cleanup did not delete user-uploaded objects.

The runner called `aws configure export-credentials --profile devops-lab --format process`, parsed temporary credential JSON only in memory, and passed
credentials to Terraform/AWS child-process environments. It did not assume
AWS provider 5.x reads the newer CLI login-session cache directly. The Session
19 runbook includes an equivalent shell export and credential-unset sequence.

`web-browser.png` captures the actual running web page. `apply.png` and
`destroy.png` are explicitly labeled renderings of authentic command output.
The final AWS NotFound responses prove deletion; they are expected cleanup
checks rather than failed provisioning steps.
