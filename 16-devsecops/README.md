# Session 17: Complete CI/CD & DevSecOps

## Demo project

This standalone calculator API extends the previous assignment with source, dependency, secret and container scanning. The reference project's stage layout is retained, with a real secret-scanning gate and GHCR authentication using GitHub's built-in token.

```text
16-devsecops/
├── app/calculator.py
├── tests/test_calculator.py
├── Dockerfile
├── .bandit.yaml
├── requirements.txt
└── k8s/deployment.yaml
../.github/workflows/devsecops.yml
```

## Pipeline flow

```text
Code → Compile/build → Unit tests → SAST → SCA → Secret scan
     → Docker build → Container scan/security gate
     → [main only] Push GHCR image → Deploy Kubernetes → HTTP smoke tests
```

| Job/stage | Tool and success condition |
|---|---|
| `test`: build and unit test | Python compileall and unittest, six tests including error cases |
| `security`: SAST | Bandit scans all application checks; a reported finding fails the job |
| `security`: SCA | pip-audit scans installed Python packages; known dependency vulnerabilities fail |
| `security`: secret scanning | Trivy scans the checked-out repository for recognized secrets; findings fail |
| `delivery`: build | Docker builds the non-root Python image only after source gates pass |
| `delivery`: image scan | Trivy blocks HIGH and CRITICAL CVEs, including currently unfixed ones |
| `delivery`: registry | GHCR receives the image tagged with its source commit SHA only after gates pass |
| `delivery`: Kubernetes | kind receives the published image, rollout must complete, health and arithmetic responses must pass |

`test → security → delivery` is enforced with job dependencies. Security commands and scanner actions return nonzero on failure; no `continue-on-error` bypass exists. Reports are uploaded with `if: always()` for review even when the associated scan fails. Uploading a failure report does not turn the job green or unblock publication.

## Security configuration and scope

- **SAST:** `.bandit.yaml` excludes test code. The sole `# nosec B104` annotation documents the necessary `0.0.0.0` container listen address. It does not disable other checks.
- **SCA:** application runtime uses only Python's standard library, so `requirements.txt` has no third-party runtime packages. `pip-audit` audits the installed third-party security toolchain (Bandit, pip-audit and their dependencies). Trivy covers the Python/base OS components inside the runtime container. If application dependencies are added, install them in the security job before auditing and in the Dockerfile.
- **Secret scanning:** Trivy scans the current checked-out tree, including the other homework files, for recognized secret formats. This is not a Git history audit. Revoke any real exposed credential even after removing the file.
- **Image scan:** workflow inputs set `scanners: vuln`, `severity: HIGH,CRITICAL`, `exit-code: 1` and `ignore-unfixed: false`. Base image CVEs may block a correct application; rebuild with an updated supported base image and review findings instead of disabling the gate.
- **Credentials:** only the delivery job has `packages: write`. `GITHUB_TOKEN` is passed to `docker/login-action`; PR runs skip login, push and deployment. No long-lived registry secret is required.
- **Container/Kubernetes:** UID/GID 10001, no privilege escalation, read-only root filesystem, dropped Linux capabilities, RuntimeDefault seccomp, no mounted service-account token, resource limits, readiness and liveness probes.

The workflow installs current Bandit/pip-audit versions and records their resolved versions as an artifact. The Python base image tag is refreshed by `docker build --pull`; the CVE databases also change over time. These choices surface current findings but do not guarantee reproducible scanner results. For a production pipeline, pin reviewed image digests, action commits and a maintained tool lockfile.

## Run and verify

```bash
cd 16-devsecops
python3 -m unittest discover -s tests -v
python3 -m app.calculator
# In another terminal:
curl http://localhost:8080/health
curl 'http://localhost:8080/calculate?op=multiply&a=6&b=7'
```

For local source security checks (network required to install tools and fetch advisories):

```bash
python3 -m venv .venv
. .venv/bin/activate
python -m pip install bandit pip-audit
bandit -r app -c .bandit.yaml
pip-audit
# Install Trivy separately, then from repository root:
trivy fs --scanners secret --exit-code 1 .
# Back inside 16-devsecops:
docker build --pull -t calculator:local .
trivy image --scanners vuln --severity HIGH,CRITICAL --exit-code 1 calculator:local
kind create cluster --name secure-demo
kind load docker-image calculator:local --name secure-demo
kubectl apply -f k8s/deployment.yaml
kubectl rollout status deployment/secure-calculator --timeout=180s
kubectl port-forward service/secure-calculator 8080:80
# Stop forwarding after verifying; remove the demo cluster:
kind delete cluster --name secure-demo
```

## Hosted execution and submission evidence

The runnable workflow lives in root `.github/workflows/devsecops.yml`. Push changes under this folder to `main`, or open **Actions → DevSecOps calculator → Run workflow** on `main`. PRs run every build and security gate but cannot publish/deploy. Enable Actions/package writes and grant repository access if the target GHCR package already exists.

Successful main runs publish `ghcr.io/aj5831a/devops-homework/secure-calculator:<commit-sha>`, pull that published tag, load it into an ephemeral kind cluster and verify both `/health` and `/calculate`. No persistent cluster or cloud subscription is required; the deployment disappears when the GitHub runner finishes.

Download `secure-calculator-build`, `source-security-reports`, `container-security-report` and `secure-calculator-deployment` from the run. Capture your own screenshots of the green job graph, security steps and deployment output; record the real run URL/commit. If a gate fails, preserve its report and resolve the finding before claiming successful completion.

**Execution status:** six unit tests passed locally during preparation. External security scanners, Docker, GHCR and Kubernetes stages have not been executed in this restricted preparation environment. Hosted success output and screenshots are pending an actual Actions run; reference screenshots are not submitted as this project's evidence.

## References

- [GitHub Actions workflow syntax](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax)
- [kind action inputs](https://github.com/helm/kind-action)
- [Trivy action configuration](https://github.com/aquasecurity/trivy-action)
- [Bandit](https://bandit.readthedocs.io/en/latest/)
- [pip-audit](https://github.com/pypa/pip-audit)
