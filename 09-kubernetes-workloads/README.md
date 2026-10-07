# Pods, ReplicaSets and Deployment Strategies

> Runtime evidence is pending: this authoring environment has no Kubernetes cluster, kubectl or Minikube. Commands and expected behavior below are a reproducible lab guide, not claimed execution output. Capture real output/screenshots on a cluster before submission. Use only the disposable namespace indicated; cleanup removes that lab’s resources.

Run from this folder; first `kubectl create namespace hw-workloads`. All versions return their name/version as HTTP text, so traffic checks distinguish versions.

## Task 1: Four deployment strategies

```bash
# Rolling: run get pods -w in another terminal to watch overlap.
kubectl apply -n hw-workloads -f rolling/v1.yaml
kubectl rollout status -n hw-workloads deployment/rolling
kubectl apply -n hw-workloads -f rolling/v2.yaml
kubectl rollout status -n hw-workloads deployment/rolling
kubectl get -n hw-workloads rs,pods
kubectl rollout undo -n hw-workloads deployment/rolling
# Blue-green: both Deployments exist, one Service selector chooses traffic.
kubectl apply -n hw-workloads -f blue-green/
kubectl rollout status -n hw-workloads deployment/blue
kubectl rollout status -n hw-workloads deployment/green
kubectl run before -n hw-workloads --image=busybox:1.37 --restart=Never --attach --rm -- wget -qO- http://active
kubectl patch -n hw-workloads service active -p '{"spec":{"selector":{"track":"green"}}}'
kubectl run after -n hw-workloads --image=busybox:1.37 --restart=Never --attach --rm -- wget -qO- http://active
# Canary: nine stable Pods and one canary Pod share a Service.
kubectl apply -n hw-workloads -f canary/
kubectl rollout status -n hw-workloads deployment/stable
kubectl rollout status -n hw-workloads deployment/canary
kubectl run sample -n hw-workloads --image=busybox:1.37 --restart=Never --attach --rm -- sh -c 'for i in $(seq 1 100); do wget -qO- http://canary-route; done' | sort | uniq -c
# Recreate: wait for v1, then observe deletion before v2 creation.
kubectl apply -n hw-workloads -f recreate/v1.yaml
kubectl rollout status -n hw-workloads deployment/recreate
kubectl get -n hw-workloads pods -w
# Stop watch after baseline or use a second terminal:
kubectl apply -n hw-workloads -f recreate/v2.yaml
kubectl rollout status -n hw-workloads deployment/recreate
```

RollingUpdate retains available replicas during replacement (one extra allowed). Blue-green expected responses change from `blue` to `green`; rollback patches `track` to `blue`. Canary replica ratios approximate 10% new connections, **not** a guaranteed per-request traffic weight; connection reuse and small samples skew results. Recreate intentionally introduces downtime. Apply and scale `replicaset.yaml` to see direct replica management; a standalone ReplicaSet has no rollout history.

## Task 2: Pod lifecycle

For **each** file in `lifecycle/`, apply it, capture `get`, `describe`, logs and events, then delete it before moving on:

```bash
kubectl apply -n hw-workloads -f lifecycle/running.yaml
kubectl get -n hw-workloads pod running -o wide
kubectl describe -n hw-workloads pod running
kubectl logs -n hw-workloads running
kubectl get -n hw-workloads events --sort-by=.metadata.creationTimestamp
kubectl delete -n hw-workloads -f lifecycle/running.yaml
```

| File | Expected observation and explanation |
| --- | --- |
| running | Running while `sleep` keeps the container alive |
| pending | Pending; selector matches no node, reported in scheduling events |
| succeeded | Succeeded/Completed because exit code is zero with restartPolicy Never |
| failed | Failed/Error because exit code is one with restartPolicy Never |
| crashloop | Repeated exit code one with restartPolicy Always; restart count grows |
| imagepull | ErrImagePull then ImagePullBackOff because the tag does not exist |
| init | Init container completes its ten-second delay before main starts |
| multi-container | Two containers in one Pod; use `logs -c sidecar` |
| startup | Startup probe allows initialization before other probes can run |
| readiness | Initially not ready; becomes ready once `/tmp/healthy` exists |
| liveness | Starts healthy; removing `/tmp/healthy` triggers container restart |
| termination | Deletion sends TERM; process traps it and exits before grace expires |

For liveness run `kubectl exec -n hw-workloads liveness -- rm /tmp/healthy`, then watch restarts. For readiness remove the same file and watch READY become 0/1 without a restart. `CrashLoopBackOff`, `ImagePullBackOff`, and `ContainerCreating` are container/display statuses, not Pod phases. The Pod phases are Pending, Running, Succeeded, Failed and Unknown. Unknown reflects inability to obtain state and is not reliably produced by a portable Pod manifest.

Record actual before/after output, timestamps and screenshots for each file. Cleanup: `kubectl delete namespace hw-workloads`.
