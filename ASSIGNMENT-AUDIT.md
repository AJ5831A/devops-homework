# Assignment coverage audit — 2026-10-07

Student: **Aryan Jakhar — 24BCS10305**.
Sources reviewed: supplied `DevOps Homework (1).pdf` (54 pages), the existing
repository at commit `f020e4d`, and the supplied `Learn_DEVOPS-main.zip`,
`Class_Assignments/`. PDF requirements take precedence where the reference is
incomplete. The reference's CI/CD and DevSecOps project folders are empty
submodule directories in the ZIP; fresh runnable projects fill those gaps.

## What was already present

| Existing section | Audit finding |
| --- | --- |
| 01 Linux | Link demonstration and notes present; Ubuntu adduser/journalctl evidence remains pending |
| 02 Shell | System info script and recorded sample output present |
| 03 Networking | Command explanations and recorded macOS outputs present |
| 04 Git | Commit/cherry-pick demonstrations and output present |
| 05 Docker | Six application folders and Dockerfiles present; builds/browser evidence pending |
| 06 Multi-stage | Go application and two-stage Dockerfile present; execution evidence pending; name/enrollment now filled |
| 07 Docker networks | Commands, explanations and bind-mount file present; runtime screenshots pending |

Existing recorded outputs were retained, not re-executed or independently
verified in this update. The networking explanation was corrected: a container
attached to two networks does not automatically route between them.

## Remaining PDF assignments now implemented

| PDF pages | Folder | Coverage |
| --- | --- | --- |
| 11–12 | 08-kubernetes-fundamentals | Minikube setup/status, architecture, tutorial deployment/expose/scale/update |
| 13–15 | 09-kubernetes-workloads | ReplicaSet, rolling/blue-green/canary/recreate, 12 lifecycle/probe fixtures |
| 16–19 | 10-kubernetes-services | ClusterIP/NodePort/LoadBalancer/ExternalName/headless, object comparisons, fqdn and coredns docs |
| 20–22 | 11-kubernetes-ingress-config | ConfigMap, demo Secret, Ingress/controller, before/after troubleshooting |
| 23–25 | 12-kubernetes-storage | Required volume README, volume manifests, HPA/load generator, storage/probe mini-project |
| 26–28 | 13-kubernetes-troubleshooting | Required commands and failure categories, troubleshooting mini-project and repairs |
| 29–32 | 14-helm | Chart/values/templates, Helm commands, upgrades and rollback, Notes mini-project |
| 33–34 | 15-cicd-github-actions | Source/tests/Dockerfile, root workflow, build artifact, GHCR + kind CD |
| 35–37 | 16-devsecops | SAST/SCA/secret/container scans, blocking gates, registry + Kubernetes deployment |
| 38–43 | 17-terraform | S3 project and complete separate IAM/EC2/S3/VPC/DynamoDB-RDS notes |
| 44–46 | 18-cloud-terraform | VPC/subnet/SG/EC2/S3, diagram, dependencies, outputs/state and lifecycle commands |
| 47–48 | 19-monitoring-gitops | Compose app/Prometheus/Grafana, metrics/logs/alerts, observability notes, Argo reconciliation demo |
| 49–54 | final-devops-project | Required directory tree, app through gated image/Helm/Kubernetes/GitOps, Terraform k3s, monitoring and four faults |

## Evidence still required for final submission

The PDF asks for live execution and screenshots, not just files. Those items
are **not complete** in this environment:

1. Run Docker labs 05–07; capture actual web pages, container/network output.
2. Run Kubernetes labs 08–13 and Helm lab 14; capture each task's output and before/after failures.
3. Run the GitHub workflows after pushing; preserve successful Actions logs/artifacts.
4. Configure an AWS lab account and run Terraform init/validate/plan/apply/output/destroy; retain redacted evidence.
5. Run monitoring/GitOps/final deployment and capture dashboards, alerts, Argo sync and troubleshooting.
6. Run Ubuntu-specific adduser/journalctl exercises from the original Linux assignment.

No Docker, kubectl, Minikube, Helm, Terraform or AWS CLI was available during
local authoring. Socket binding was denied, so even local HTTP integration
could not run. Shell network access could not resolve GitHub; push and hosted
execution are separately blocked. See VALIDATION.md for actual checks.
