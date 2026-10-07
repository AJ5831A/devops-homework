# Infrastructure validation evidence

[Successful GitHub Actions run](https://github.com/AJ5831A/devops-homework/actions/runs/37639824286) validated all five infrastructure matrix jobs on 7 October 2026:

- Terraform: `17-terraform/terraform-s3-demo`, `18-cloud-terraform/terraform-vpc`, and `final-devops-project/terraform` each passed `terraform fmt -check -diff`, `terraform init -backend=false`, and `terraform validate -no-color`.
- Helm: `14-helm/notes-chart` passed strict lint/render with defaults and production + NodePort overrides.
- Helm: `final-devops-project/helm/devops-demo` passed strict lint/render with defaults, Ingress/HPA enabled, and GitOps values.

These checks verify formatting, Terraform/provider configuration and Helm template rendering. They do not create AWS resources or install charts into Kubernetes. AWS plan/apply/destroy and Kubernetes runtime/screenshots remain pending. No AWS credentials were needed by this workflow.

All corresponding local checks also completed successfully on 2026-10-07 with Terraform 1.9.8 and Helm 3.16.4. The tool/version, initialization, validation, lint and rendered-manifest files in this folder are the actual local outputs. Rendered YAML is validation output, not proof of a deployed application.
