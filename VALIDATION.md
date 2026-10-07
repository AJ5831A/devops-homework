# Validation — 2026-10-07

## Observed locally

- CI/CD calculator: 6 unit tests passed.
- DevSecOps calculator: 6 unit tests passed.
- Final project: 10 unit tests passed, including authentication, non-ASCII headers, malformed URLs, readiness, metrics and bounds.
- Kubernetes sections 08–13: 57 YAML files / 63 resources passed structural checks (see [record](08-kubernetes-fundamentals/STATIC-VALIDATION.md)).
- Both Terraform bootstrap scripts passed `bash -n`.
- 27 Kubernetes/final-project Bash documentation blocks passed syntax checks.
- Final application review fixes are documented in [security/REVIEW.md](final-devops-project/security/REVIEW.md).

The repository-wide structural checker and application unit tests passed.
Counts increase as new runtime evidence is added; use the commands below to
check the current checkout. Raw CLI evidence preserves original whitespace.

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

## Additional observed runtime evidence

- [Docker labs](evidence/docker/README.md): all six applications, the multi-stage build, network isolation/connectivity, host networking and bind-mount changes.
- [Helm lifecycle](evidence/helm/20261007T150849Z/): install, configuration/replica upgrade, failed image, rollback, browser response and uninstall.
- [Local infrastructure validation](evidence/infrastructure/README.md): all three Terraform init/fmt/validate runs and both chart lint/render checks.
- [Monitoring](19-monitoring-gitops/evidence/README.md): CPU/memory, logs, health, Grafana, firing alerts and recovery.

## Remaining execution work

The first hosted Kubernetes exercise run exposed verification-script timing
and DNS return-code problems. Its original evidence is retained alongside
ongoing targeted repairs. The final GitOps retry is running after a transient
GitHub push failure. Neither run is claimed as fully passed here.

AWS plan/apply/output/destroy await the user's lab profile. No cloud credentials
or fabricated output are committed. Later workflow additions need a new run
before claiming validation for those revisions.
