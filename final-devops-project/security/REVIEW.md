# Implementation review

Reviewed application, Docker, raw Kubernetes manifests, Helm chart and security configuration during assignment preparation.

## Corrections

1. **Non-ASCII authorization headers could terminate a request.** Python's constant-time string comparison supports ASCII strings only. Authorization now compares UTF-8 bytes; a regression test verifies non-ASCII credentials return HTTP 401 without throwing an exception.
2. **Malformed URL authorities could raise an uncaught parser error.** The routing function now returns HTTP 400 for an invalid path. Structured request logging does not re-parse that invalid path. A regression test covers this case.
3. **Helm ConfigMap edits would not update existing process environments.** The pod template now includes the rendered ConfigMap checksum. Changing the configured message changes the pod template and triggers a rolling restart.

## Verification

- All 10 application unit tests passed locally, including both new input-validation regressions.
- Docker Compose, raw Kubernetes resources, Helm values/chart metadata and Bandit configuration parse as YAML.
- Service selectors, named container ports, probes, ConfigMap and existing Secret names are consistent.
- Docker and Kubernetes both run the application as UID 10001; the app writes no persistent files and works with a read-only root filesystem.
- The Helm templates were inspected, but Helm rendering and cluster validation still require the corresponding tools.

A loopback socket bind was attempted and denied by the preparation sandbox (`Operation not permitted`). Real HTTP integration, image builds, security-tool execution, Helm rendering and Kubernetes execution are therefore not claimed by this review; the hosted pipeline supplies those execution checks.
