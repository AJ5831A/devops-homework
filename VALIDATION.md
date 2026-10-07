# Validation — 2026-10-07

## Observed locally

- CI/CD calculator: 6 unit tests passed.
- DevSecOps calculator: 6 unit tests passed.
- Final project: 10 unit tests passed, including authentication, non-ASCII headers, malformed URLs, readiness, metrics and bounds.
- Kubernetes sections 08–13: 57 YAML files / 63 resources passed structural checks (see [record](08-kubernetes-fundamentals/STATIC-VALIDATION.md)).
- Both Terraform bootstrap scripts passed `bash -n`.
- 27 Kubernetes/final-project Bash documentation blocks passed syntax checks.
- Final application review fixes are documented in [security/REVIEW.md](final-devops-project/security/REVIEW.md).

Repository-wide structural check output:

```text
Offline structural checks: 90 yaml, 1 json, 10 python, 3 shell, 46 links
PASS. Helm rendering, Terraform validation and runtime behavior require separate tooling.
```

`git diff --check` also passed.

## Reproduce offline checks

With Python 3 and PyYAML installed:

```bash
python3 scripts/validate-homework.py
(cd 15-cicd-github-actions && python3 -m unittest discover -s tests -v)
(cd 16-devsecops && python3 -m unittest discover -s tests -v)
python3 -m unittest discover -s final-devops-project/application -v
git diff --check
```

The structural checker parses non-templated YAML/JSON/Python, checks shell
syntax, local Markdown links, workflow job dependencies, resource identities,
Deployment/ReplicaSet selectors and mounted volumes. It skips Helm template
syntax and is not Kubernetes schema validation. Intentional broken fixtures
are designed to be syntactically valid so their runtime failures can be studied.

## Not executed here

Docker image builds, container security scans, HTTP integration, Minikube/kind,
Helm rendering, Terraform provider initialization/validation, AWS provisioning,
Argo reconciliation and hosted GitHub Actions have **not** run here. Required
CLIs are absent; outbound shell DNS fails; local socket binding is denied.
No successful runtime screenshots or output have been invented or copied.

The root workflows contain the next executable checks: application CI/CD,
DevSecOps, final-project deployment and infrastructure validation. These need
GitHub connectivity and an actual push before they produce evidence. Cloud
apply/destroy is deliberately a documented lab operation, not an automatic CI job.
