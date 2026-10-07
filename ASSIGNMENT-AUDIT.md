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
| 01 Linux | Link demonstration and notes present; Ubuntu adduser/journalctl evidence added in this update |
| 02 Shell | System info script and recorded sample output present |
| 03 Networking | Command explanations and recorded macOS outputs present |
| 04 Git | Commit/cherry-pick demonstrations and output present |
| 05 Docker | Six application folders and Dockerfiles present; builds/browser evidence added in this update |
| 06 Multi-stage | Go application and two-stage Dockerfile present; execution evidence added; name/enrollment filled |
| 07 Docker networks | Commands, explanations and bind-mount file present; runtime screenshots added in this update |

Existing recorded outputs were retained. New execution records for Linux user
management and Docker labs are linked separately from the original outputs. The networking explanation was corrected: a container
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

## Execution progress after tools/network became available

- Ubuntu adduser/user verification/cleanup and journalctl completed; actual transcript and rendered screenshot are linked from01.
- Docker05–07 completed: six built/running apps with browser screenshots, multi-stage app on8080, network isolation/connectivity, host networking and live bind-mount update.
- Local Minikube/Kubernetes node reached Ready; setup output is in evidence/kubernetes/local-setup.
- Helm14 completed locally: install→upgrade→bad image→rollback, actual HTTP/config/replica checks, revision history and uninstall. Chart creation, repository/search commands also executed.
- CI/CD15, DevSecOps16 and final gated pipeline passed on GitHub, with screenshots and retained logs/artifacts. The first image gate failure was remediated without bypassing checks.
- All Terraform projects passed actual init/fmt/validate locally and in CI; provider lock files are committed.
- Monitoring20 completed with real CPU/memory/health/logs, Grafana screenshots, high-CPU/down alerts and recovery.

Kubernetes08–13 evidence includes the original hosted failures and successful
targeted liveness, DNS, network-policy, canary and HPA scale-up/down repairs.
Final deployment, four fault repairs and GitOps promotion/self-heal/rollback
passed in the hosted runtime step. Its subsequent UI capture failed on a login
selector; the corrected capture then passed locally with both Argo applications
Synced/Healthy and final readiness HTTP200. Original failures are retained.
AWS plan/apply/output/destroy remain pending authenticated AWS CLI access.
The submission remains incomplete until these remaining execution requirements
are proven. See VALIDATION.md and each linked evidence folder for exact scope.
