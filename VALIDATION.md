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

## Live validation after network access became available

All four hosted workflows have successful runs:

- [CI/CD calculator](https://github.com/AJ5831A/devops-homework/actions/runs/37639824089): build, registry push, kind deployment and HTTP checks.
- [Infrastructure](https://github.com/AJ5831A/devops-homework/actions/runs/37639824286): all three Terraform init/validate/fmt jobs and both Helm lint/render jobs.
- [DevSecOps](https://github.com/AJ5831A/devops-homework/actions/runs/37640204904): tests, SAST, SCA, secrets and image gates, registry push and Kubernetes HTTP checks.
- [Final project](https://github.com/AJ5831A/devops-homework/actions/runs/37640204903): tests, scans, publication and Helm deployment into kind with readiness verification.

Actual logs/artifacts/screenshots are in [evidence/pipelines](evidence/pipelines/README.md).
The first image scans failed on Debian CVEs. Replacing the runtime with updated
Alpine images resolved those findings without weakening the security gates.

Local HTTP readiness/metrics and the application screenshot are in
[evidence/final-project](evidence/final-project/). The Ubuntu user creation,
verification, cleanup and journalctl transcript is in
[evidence/linux/ubuntu-users-journal.log](evidence/linux/ubuntu-users-journal.log).

## Remaining execution work

The local Docker/Minikube lab is now installed and its exercise runs are in
progress. Monitoring, GitOps, complete per-exercise Kubernetes output and AWS
apply/destroy remain pending until their actual evidence is recorded. The user
is configuring an AWS lab profile. No cloud credentials or fabricated output
are committed. Later workflow additions must get a new run before claiming
validation for those revisions.
