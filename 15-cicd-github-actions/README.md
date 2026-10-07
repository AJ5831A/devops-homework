# Session 16: CI/CD & GitHub Actions

## Demo project

A Python calculator HTTP API follows the reference assignment's calculator idea, with automated testing, a build artifact, a Docker image and an actual Kubernetes deployment stage. It uses Python's standard library so the application can be tested without installing packages.

```text
15-cicd-github-actions/
├── app/calculator.py       # HTTP routes and arithmetic
├── tests/test_calculator.py
├── Dockerfile
├── requirements.txt       # Documents zero third-party runtime dependencies
└── k8s/deployment.yaml     # Deployment and ClusterIP Service
../.github/workflows/cicd-demo.yml
```

## Pipeline

```text
Push to main / pull request / manual workflow dispatch
  → Compile Python → Unit tests → Downloadable application artifact
  → Docker build
  → [main only] GHCR push → kind Kubernetes cluster
  → Deploy 2 replicas → Wait for rollout → Check health and calculation over HTTP
```

The workflow is at the repository root because GitHub only discovers workflows in root `.github/workflows/`. Changes to this assignment or its workflow trigger runs. PRs exercise tests and Docker build; publication and deployment run on `main` only. Manual runs from other branches still build and test, but do not publish.

| Concept | Implementation |
|---|---|
| CI | Compile, run unit tests and build the image on proposed changes |
| CD | Publish the tested image and deploy it on successful main runs |
| Workflow | `cicd-demo.yml`, an event-triggered YAML definition |
| Jobs | `test`, then `delivery` with `needs: test` |
| Steps | Checkout, Python setup, commands and reusable actions within each job |
| Runner | Fresh `ubuntu-latest` GitHub-hosted VM per job |
| Secrets | GitHub supplies the short-lived `GITHUB_TOKEN`; no personal token is stored |
| Artifacts | Application tarball, test output and deployment verification files |
| Registry | `ghcr.io/aj5831a/devops-homework/cicd-calculator:<commit-sha>` |
| Kubernetes | Two non-root replicas, health probes, resource limits and a ClusterIP service |

The image name is derived from the repository at runtime and lowercased. `contents: read` is the default; only delivery receives `packages: write`. The pipeline pulls the published image and loads it into kind, so private GHCR package access does not require an imagePullSecret in this temporary cluster. The SHA tag identifies the source commit. The cluster exists only during the runner job; this demonstrates continuous deployment, not permanent hosting.

## Run locally

Prerequisites: Python 3.10+ for the app; Docker, kind and kubectl for the optional container/Kubernetes exercises. Actions uses Python 3.12.

```bash
cd 15-cicd-github-actions
python3 -m unittest discover -s tests -v
python3 -m app.calculator
# In a second terminal:
curl http://localhost:8080/health
curl 'http://localhost:8080/calculate?op=add&a=2&b=3'
```

Expected responses are `{"status": "ok"}` and `{"result": 5.0}`. Other operations are subtract, multiply and divide. Missing/invalid operands, division by zero, nonfinite numbers and overflow return HTTP 400; unknown routes return 404.

```bash
# From this assignment directory, with Docker running:
docker build -t calculator:local .
docker run --rm -p 8080:8080 calculator:local
# Stop the container before forwarding port 8080 below.
kind create cluster --name calculator-demo
kind load docker-image calculator:local --name calculator-demo
kubectl apply -f k8s/deployment.yaml
kubectl rollout status deployment/cicd-calculator --timeout=180s
kubectl port-forward service/cicd-calculator 8080:80
# After verifying with curl, stop port-forward and clean up:
kind delete cluster --name calculator-demo
```

## GitHub execution and evidence

Open the repository's **Actions → CI/CD calculator → Run workflow**, choose `main`, then start the run. Alternatively, push a change under this folder. GitHub Actions and package publishing must be enabled for the repository; if reusing an existing GHCR package, grant this repository Actions access to that package.

**Execution status: successful hosted run.** [CI/CD calculator run 37639824089](https://github.com/AJ5831A/devops-homework/actions/runs/37639824089) passed on 7 October 2026 for commit `8fdc4e970d759eac156516101c33e64b5cf6f065`. It ran the tests, built and published the image, deployed to kind and verified the HTTP endpoints. The six unit tests also passed locally.

![Successful CI/CD calculator workflow](../evidence/pipelines/screenshots/cicd-success.png)

The downloaded [deployment output](../evidence/pipelines/cicd-success/deployment-evidence.txt) shows two ready application pods. Actual HTTP artifacts contain [health status](../evidence/pipelines/cicd-success/health.json) and [calculation result](../evidence/pipelines/cicd-success/calculator.json). The screenshot is from this repository's run. Build artifacts remain available from the linked Actions run according to GitHub's artifact retention policy. See the [pipeline evidence index](../evidence/pipelines/README.md) for all runs.

This is a teaching service based on `http.server`; deploy a production HTTP server, authentication and ingress/TLS before using the design for a public service.

## References

- [GitHub Actions workflow syntax](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax)
- [kind action inputs](https://github.com/helm/kind-action)
