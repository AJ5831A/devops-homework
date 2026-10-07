# Final project infrastructure

Provisions a VPC, public subnet, Internet Gateway/default route, security group, encrypted EC2 root disk, and private encrypted/versioned S3 bucket. Cloud-init installs a **single-node k3s** cluster using the stable installer channel. EC2 uses an Amazon Linux 2023 x86_64 AMI. The region and instance size are variables; default t3.small provides more memory than t3.micro for the lab. This is a learning cluster, not HA production infrastructure. AWS resources incur charges.

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit BOTH CIDRs to your public IPv4 /32 and select your existing EC2 key pair.
# Sign in if this profile is not already authenticated:
aws --region ap-south-1 login --profile devops-lab
# AWS provider 5.x did not consume this new CLI login profile directly.
# Export temporary credentials into this shell, without printing them:
set +x
eval "$(aws --profile devops-lab --region ap-south-1 configure export-credentials --format env)"
unset AWS_PROFILE AWS_DEFAULT_PROFILE
aws --region ap-south-1 sts get-caller-identity
terraform init
terraform fmt
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
terraform output
aws ec2 wait instance-status-ok --instance-ids "$(terraform output -raw instance_id)"
```

The key pair must already exist in the chosen region; Terraform never generates or commits a private key. `admin_cidr` requires `/32` and governs SSH (22) and Kubernetes API (6443). `http_cidr` governs application HTTP (80). k3s's bundled Traefik handles Ingress, and its bundled metrics-server and local-path provisioner support the HPA and optional storage exercises. The API's TLS certificate includes the EC2 public IP. Automatic public IP changes on stop/start require updating the certificate/configuration or recreating this disposable lab.

## Retrieve cluster credentials locally

Use the private key corresponding to the EC2 key pair, stored outside the repository. Verify the instance SSH host key through a trusted channel rather than disabling host-key verification.

```bash
# Replace KEY_PATH with your local private-key path.
PUBLIC_IP=$(terraform output -raw web_url | sed 's|http://||')
ssh -i KEY_PATH ec2-user@"$PUBLIC_IP" 'sudo cloud-init status --wait'
ssh -i KEY_PATH ec2-user@"$PUBLIC_IP" 'sudo k3s kubectl get nodes'
mkdir -p "$HOME/.kube"
umask 077
ssh -i KEY_PATH ec2-user@"$PUBLIC_IP" 'sudo cat /etc/rancher/k3s/k3s.yaml' > "$HOME/.kube/devops-final.yaml"
# Use your editor to replace only server: https://127.0.0.1:6443 with:
# server: https://<PUBLIC_IP>:6443 in this local kubeconfig.
export KUBECONFIG="$HOME/.kube/devops-final.yaml"
kubectl get nodes
kubectl get pods -A
```

The kubeconfig contains cluster-admin credentials: keep it local or in an explicitly configured CI secret, never in Git or screenshots. Proceed to the final project's Helm deployment instructions. For a host-based Ingress test, use `curl -H 'Host: <configured-host>' http://<PUBLIC_IP>` from the allowed network. If bootstrapping fails, inspect `/var/log/cloud-init-output.log` through SSH. A running EC2 status alone does not prove k3s is ready.

References and dependencies construct the Terraform graph; `depends_on` ensures public routing exists before packages are downloaded. State is local and sensitive. Keep state, saved plans and `.terraform/` out of Git; commit the generated provider lock file after successful init. For repeatable production work pin the AMI and k3s version, and use a secured remote state backend.

## Cleanup and evidence

The full AWS lifecycle ran on 7 October 2026 in `ap-south-1`: Terraform
planned/applied 11 resources, Amazon Linux 2023 bootstrapped a Ready k3s
`v1.36.5+k3s1` node, and Helm deployed the exact previously scanned image.
Traefik served the application and readiness endpoint with HTTP 200; two Pods
were ready and HPA reported CPU metrics. [Actual cloud evidence and browser
screenshot](../../evidence/aws-final/README.md) include plan/apply/show/output,
host-key verification, resources, and teardown checks.

The lab used `aws configure export-credentials --format process` in a local
Python wrapper to pass short-lived credentials only to the Terraform child
process. The shell example above provides the equivalent bridge for provider
5.x. Include the region explicitly: an initial cleanup invocation omitted it
and stopped before Terraform; adding `--region ap-south-1` resolved that issue.
Do not run credential export by itself into terminal output or save its result
to the repository.

The userdata uses the existing `curl` or installs `curl-minimal` when absent,
avoiding the conflicting full-curl package on Amazon Linux 2023.

Uninstall project workloads, then run `terraform destroy` from this folder. S3 must be empty including versions; `force_destroy=false` protects uploaded data. Deleting the single node destroys its local-path volumes. Remove the local kubeconfig after teardown.

After teardown, clear the exported temporary shell credentials:

```bash
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
```

Reference: [K3s quick-start and kubeconfig location](https://docs.k3s.io/quick-start).
