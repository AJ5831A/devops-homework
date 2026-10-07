# Security gates

`final-project.yml` tests the app, runs Bandit SAST, audits runtime dependencies
with pip-audit, scans the repository using Gitleaks, builds the image, and runs
Trivy with `--exit-code 1 --severity HIGH,CRITICAL`. Publish and deployment depend
on all gates. No `continue-on-error` suppresses a failed gate.

The app has no third-party runtime dependencies; SCA explicitly reports that
fact. Trivy scans Python and OS packages in the base image. A failing image scan
requires an updated base image or a reviewed remediation; do not disable the gate.

Bandit's sole exclusion is B104 because Kubernetes must reach the server on
`0.0.0.0`. Containers run as UID 10001, drop capabilities, have a read-only root,
and do not mount Kubernetes API credentials. The demo uses Python's basic HTTP
server; it is a lab application, not a production web server.

Create `API_TOKEN` locally using a random value. Git contains only a Secret
schema example. Readiness fails when the token is absent; `/api/info` requires
the bearer token and never returns it. Logs omit authorization headers.
GHCR uses the Actions `GITHUB_TOKEN`, scoped to the publishing job. Set the
published package public for anonymous cluster pulls, or configure an
`imagePullSecret` in the deployment for a private package.

## Container remediation

The first hosted image scan blocked the Debian slim base on HIGH severity OS findings. The runtime now uses `python:3.12-alpine` and runs `apk upgrade --no-cache` during its build. This removes unnecessary Debian packages and applies Alpine updates while retaining the same blocking HIGH/CRITICAL gate, including unfixed findings. See [actual failure logs and remediation](../../evidence/pipelines/image-remediation.md) for evidence. A later successful scan is required to confirm the fix.
