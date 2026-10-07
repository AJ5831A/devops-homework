# GitOps and final runtime evidence — 7 October 2026

`runtime.txt`, `applications-final.yaml`, `native-deployment.yaml`,
`events-final.txt` and `pods-final.txt` are unmodified artifacts from the
successful **Run final project and GitOps experiments** step in
[Actions run 37642643309](https://github.com/AJ5831A/devops-homework/actions/runs/37642643309).
`hosted-run.json` records the overall workflow's failure: only the subsequent
browser capture failed because Argo's login inputs have no `name` attribute.
The runtime step itself succeeded, including all assertions.

Observed results:

- Native Deployment, ConfigMap, externally supplied Secret, Service, probes,
  Ingress and HPA ran in a disposable Minikube v1.34.0 cluster.
- Ingress routed `Host: devops.local` to successful readiness responses.
- Invalid image tag, wrong Service selector, missing Secret and wrong readiness
  path produced their documented symptoms, were investigated, and were repaired.
- Helm install, message upgrade and rollback completed; history is retained.
- Load drove HPA from 2 to 4 to 5 replicas; CPU metrics and scaling events are retained.
- Argo CD v3.1.8 deployed both Applications with `Synced / Healthy` status.
- On real remote branch `lab/gitops-runtime-37642643309`, promotion commit
  `6457eb8444f5b060ac8d492506e6dae32db0a06f` changed GitOps replicas 2→3.
  Manual cluster drift to 1 was repaired to 3. Revert commit
  `16475370a38b08c63fffbd77f9cb4ed71805a9e6` restored 2 through Git.

The immutable image `ghcr.io/aj5831a/devops-final:be9442981c475a39475f4f14501e0fc95244b681`
was loaded from the exact saved artifact of the successful security/publish
pipeline 37640204903. This avoids private GHCR authentication during this lab;
it does not claim a second registry pull.

## Genuine local screenshot recovery

The corrected `scripts/capture-argocd.cjs` was run successfully against a fresh
Argo CD v3.1.8 installation on local Minikube profile `devops-homework`.
The real Applications from `main` both reached `Synced / Healthy`.
`argocd-applications.png` and `argocd-final.png` are browser screenshots from
that separate local execution, not images of the hosted runner.

`local-applications.txt`, `local-final-resources.txt`, `local-gitops-resources.txt`,
`local-image.txt`, `local-readiness.json`, and `local-capture-time.txt` record
the local verification. The local node is arm64; installed binfmt emulation
ran the same amd64 image successfully with two ready Pods. The readiness JSON
was fetched through a real Service port-forward. The hosted transcript is the
proof of actual Ingress routing and HPA load scaling.

No credentials or real Secret values are included. The hosted cluster was
removed with its ephemeral runner. The real demonstration branch is retained
so its promotion and rollback commits remain reviewable.
