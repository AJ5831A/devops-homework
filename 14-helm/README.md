# Helm — Session 15

Commands and a complete Notes chart implement the supplied session and mini project. Helm lint/render checks passed in hosted CI; see [infrastructure validation evidence](../evidence/infrastructure/README.md). Cluster installation output and screenshots remain **pending execution**; none below are claimed as observed cluster output.

## Task 1: Charts and commands

Helm packages Kubernetes templates and default values into a chart. A release is one named installation of a chart in a namespace. `Chart.yaml` describes the chart (chart version and application version are separate); `values.yaml` supplies defaults; `templates/` renders resources. `-f` overrides defaults and `--set` overrides file values. Our chart contains a Deployment, Service and ConfigMap, plus health probes and resource requests. Config changes update the pod-template checksum to trigger a rollout. The application is the Nginx Notes demonstration from the reference's mini-project scope.

Run from `14-helm`, with Helm 3+ and a running cluster:

```bash
mkdir -p evidence
helm version
kubectl cluster-info
helm create /tmp/aj-helm-practice  # scaffold a separate practice chart
helm lint notes-chart
helm template notes-dev notes-chart > evidence/rendered.yaml
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm repo list
helm search repo ingress-nginx
helm search hub nginx
```

`helm create` scaffolds; `repo add/update/list` manages chart repositories; `search repo` searches their cached indexes; `search hub` searches Artifact Hub. The remote searches require internet. The commands below cover `install`, `list`, `status`, `get`, `upgrade`, `history`, `rollback` and `uninstall`.

## Tasks 2–3: Install, upgrade twice, rollback and mini project

```bash
helm install notes-dev notes-chart -n helm-demo --create-namespace --wait --timeout 3m
helm list -n helm-demo
helm status notes-dev -n helm-demo
helm get values notes-dev -n helm-demo --all
helm get manifest notes-dev -n helm-demo > evidence/installed.yaml
kubectl get pods,svc,configmap -n helm-demo
kubectl port-forward -n helm-demo svc/notes-dev-svc 8080:80
# In another terminal: curl http://localhost:8080
```

Expected, not captured: release revision 1 has one ready Pod and the webpage says `development`. Save the real status and browser screenshot in `evidence/`.

```bash
helm upgrade notes-dev notes-chart -n helm-demo -f notes-chart/values-prod.yaml --wait --timeout 3m
kubectl rollout status deployment/notes-dev-deploy -n helm-demo
kubectl get pods -n helm-demo
helm get values notes-dev -n helm-demo
# Restart port-forward if its selected Pod terminated; curl localhost:8080 again.
helm history notes-dev -n helm-demo | tee evidence/history-before.txt

# Intentional second upgrade: invalid image. Omit --wait to inspect the failure.
helm upgrade notes-dev notes-chart -n helm-demo -f notes-chart/values-prod.yaml --set image.tag=broken-tag-does-not-exist
kubectl get pods -n helm-demo
kubectl describe pods -n helm-demo > evidence/broken-pods.txt
helm status notes-dev -n helm-demo

# On a fresh release revision 2 is the healthy production version.
# If repeating the exercise, inspect history and choose its actual revision.
helm rollback notes-dev 2 -n helm-demo --wait --timeout 3m
kubectl rollout status deployment/notes-dev-deploy -n helm-demo
kubectl get pods -n helm-demo | tee evidence/pods-after.txt
helm history notes-dev -n helm-demo | tee evidence/history-after.txt
helm get values notes-dev -n helm-demo
# Restart port-forward and verify the production page with curl/browser.
```

Expected: first upgrade produces three replicas and a production page; the second produces ErrImagePull/ImagePullBackOff for the invalid image while rolling-update availability preserves healthy old Pods. Without `--wait`, Helm can report `deployed` even when Pods fail. Rollback restores revision 2's chart/values as a **new** revision (normally 4), not by deleting history. Confirm image, replicas and HTTP content, not just the Helm status.

For NodePort access, install another release in a different namespace with `--set service.type=NodePort`; only one release can own cluster-wide node port 30090 at once. ClusterIP with port forwarding works with local Minikube drivers without exposing a node port.

```bash
helm uninstall notes-dev -n helm-demo
kubectl get deployment,svc,configmap -n helm-demo
kubectl delete namespace helm-demo
helm repo remove ingress-nginx
```

Capture command output and browser screenshots for install, both upgrades, broken Pods, rollback and cleanup. See [Helm command reference](https://helm.sh/docs/helm/) for command semantics.

## Automated runtime evidence

With the `devops-homework` Kubernetes context ready, run from the repository root:

```bash
bash scripts/run-helm-evidence.sh
# Optional: CLEANUP=1 bash scripts/run-helm-evidence.sh
```

The script uses only namespace `hw-runtime-helm`, refuses to overwrite an existing `notes-evidence` release, and records a timestamped transcript plus actual manifests, HTTP responses, broken-Pod diagnostics and Helm history under `evidence/helm/`. It asserts ready replica counts, ConfigMap/HTTP environment values, the image-pull failure and revisions 1 → 2 → 3 → 4 (rollback to revision 2). A successful run writes `result.txt`; absence of that file means the entire workflow has not passed. `CLEANUP=1` uninstalls only the release after verification. Run `helm uninstall notes-evidence -n hw-runtime-helm --kube-context devops-homework` deliberately before repeating the fresh-install exercise.
