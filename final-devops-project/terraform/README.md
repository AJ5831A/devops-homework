# Final project infrastructure

Provisions a VPC, public subnet, Internet Gateway/default route, security group, encrypted EC2 root disk, and private encrypted/versioned S3 bucket. Cloud-init installs a **single-node k3s** cluster using the stable installer channel. EC2 uses an Amazon Linux 2023 x86_64 AMI. The region and instance size are variables; default t3.small provides more memory than t3.micro for the lab. This is a learning cluster, not HA production infrastructure. AWS resources incur charges.

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit BOTH CIDRs to your public IPv4 /32 and select your existing EC2 key pair.
export AWS_PROFILE=your-lab-profile
aws sts get-caller-identity
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

Terraform formatting, provider initialization and validation passed in hosted CI; see [infrastructure validation evidence](../../evidence/infrastructure/README.md). AWS execution and cluster evidence are pending. Capture real Terraform validation/plan/apply/output, node readiness and browser results after running. Uninstall project workloads, then run `terraform destroy` from this folder. S3 must be empty including versions; `force_destroy=false` protects uploaded data. Deleting the single node destroys its local-path volumes. Remove the local kubeconfig after teardown.

Reference: [K3s quick-start and kubeconfig location](https://docs.k3s.io/quick-start).
