# Kubernetes Troubleshooting

> Runtime evidence is pending: this authoring environment has no Kubernetes cluster, kubectl or Minikube. Commands and expected behavior below are a reproducible lab guide, not claimed execution output. Capture real output/screenshots on a cluster before submission. Use only the disposable namespace indicated; cleanup removes that lab’s resources.

## Task 1: Important commands

Run from this folder. Create the namespace and healthy baseline first:

```bash
kubectl create namespace hw-troubleshooting
kubectl apply -n hw-troubleshooting -f mini-project/deployment.yaml
kubectl apply -n hw-troubleshooting -f mini-project/service.yaml
kubectl rollout status -n hw-troubleshooting deployment/troubleshooting-app
kubectl get -n hw-troubleshooting pods -o wide
kubectl describe -n hw-troubleshooting deployment troubleshooting-app
kubectl logs -n hw-troubleshooting deployment/troubleshooting-app --tail=50
kubectl exec -n hw-troubleshooting deployment/troubleshooting-app -- wget -qO- http://localhost
kubectl events -n hw-troubleshooting
kubectl get -n hw-troubleshooting events --sort-by=.metadata.creationTimestamp
kubectl explain pod.spec.containers
kubectl top pods -n hw-troubleshooting
kubectl run client -n hw-troubleshooting --image=busybox:1.37 --restart=Never -- sleep 3600
kubectl wait -n hw-troubleshooting --for=condition=Ready pod/client --timeout=120s
kubectl exec -n hw-troubleshooting client -- wget -qO- -T 5 http://troubleshooting-service
```

`get` summarizes state; `-o wide` adds node/IP details. `describe` includes scheduling/configuration details and events. `logs` shows application stdout/stderr; `--previous` reads the last terminated container. `exec` runs diagnostics inside a running container. `events` highlights recent cluster actions; `explain` describes the API schema. `top` needs metrics-server. Events expire, so capture them promptly.

## Task 2: Reproduce, diagnose, repair, verify

Apply one fixture at a time and capture `get pod`, `describe pod` and timestamped events **before** making a fix. Expected outcomes below are hypotheses to verify, not observed local output.

| Fixture / issue | Root cause and investigation | Repair and expected verification |
| --- | --- | --- |
| `issues/crash.yaml`: CrashLoopBackOff | Exit code one; `kubectl logs -n hw-troubleshooting crash --previous` and describe show repeated failures | Delete Pod; recreate with working `sleep` command, see below; Running and no increasing restart count |
| `mini-project/broken-pod.yaml`: ErrImagePull / ImagePullBackOff | Nonexistent nginx tag; describe/events show registry pull error then backoff | Apply fixed-pod.yaml; wait Ready and inspect image |
| `issues/pending.yaml`: Pending | Selector requires nonexistent node label; describe reports FailedScheduling | Delete and recreate without selector; wait Ready |
| `issues/containercreating.yaml`: ContainerCreating | Missing mounted ConfigMap; describe reports FailedMount | Create missing-config; wait mount-error Ready |
| `issues/config.yaml`: configuration error | Missing environment ConfigMap; describe reports CreateContainerConfigError | Create missing-env with APP_ENV; wait Ready and printenv |
| `mini-project/broken-service.yaml`: connection failure | Selector differs from Pod labels; EndpointSlice has no ready targets | Apply service.yaml; curl/wget returns app response |
| `issues/dns.yaml`: DNS timeout | Resolver forced to unreachable documentation IP; inspect /etc/resolv.conf, use nslookup | Recreate with ClusterFirst default; nslookup resolves service |
| `issues/networkpolicy.yaml`: Pod networking failure | Ingress deny selects application; DNS can still resolve, but app requests time out | Remove only this policy; wget succeeds (requires policy-enforcing CNI) |

```bash
# Crash recovery; capture before deleting.
kubectl apply -n hw-troubleshooting -f issues/crash.yaml
kubectl describe -n hw-troubleshooting pod crash
kubectl logs -n hw-troubleshooting crash --previous
kubectl delete -n hw-troubleshooting pod crash
kubectl run crash -n hw-troubleshooting --image=busybox:1.37 --restart=Never -- sleep 3600
# Pending recovery (nodeSelector is immutable on an existing Pod):
kubectl apply -n hw-troubleshooting -f issues/pending.yaml
kubectl describe -n hw-troubleshooting pod pending
kubectl delete -n hw-troubleshooting pod pending
kubectl run pending -n hw-troubleshooting --image=busybox:1.37 --restart=Never -- sleep 3600
# Volume/config errors:
kubectl apply -n hw-troubleshooting -f issues/containercreating.yaml
kubectl describe -n hw-troubleshooting pod mount-error
kubectl create -n hw-troubleshooting configmap missing-config --from-literal=message=repaired
kubectl wait -n hw-troubleshooting --for=condition=Ready pod/mount-error --timeout=180s
kubectl apply -n hw-troubleshooting -f issues/config.yaml
kubectl describe -n hw-troubleshooting pod config-error
kubectl create -n hw-troubleshooting configmap missing-env --from-literal=APP_ENV=homework
kubectl wait -n hw-troubleshooting --for=condition=Ready pod/config-error --timeout=180s
kubectl exec -n hw-troubleshooting config-error -- printenv APP_ENV
# DNS:
kubectl apply -n hw-troubleshooting -f issues/dns.yaml
kubectl wait -n hw-troubleshooting --for=condition=Ready pod/bad-dns --timeout=120s
kubectl exec -n hw-troubleshooting bad-dns -- cat /etc/resolv.conf
kubectl exec -n hw-troubleshooting bad-dns -- nslookup troubleshooting-service
kubectl delete -n hw-troubleshooting pod bad-dns
kubectl run bad-dns -n hw-troubleshooting --image=busybox:1.37 --restart=Never -- sleep 3600
kubectl wait -n hw-troubleshooting --for=condition=Ready pod/bad-dns --timeout=120s
kubectl exec -n hw-troubleshooting bad-dns -- nslookup troubleshooting-service
# NetworkPolicy: use a lab cluster with a supporting CNI, e.g. Calico.
kubectl apply -n hw-troubleshooting -f issues/networkpolicy.yaml
kubectl exec -n hw-troubleshooting client -- nslookup troubleshooting-service
kubectl exec -n hw-troubleshooting client -- wget -qO- -T 5 http://troubleshooting-service
kubectl delete -n hw-troubleshooting -f issues/networkpolicy.yaml
kubectl exec -n hw-troubleshooting client -- wget -qO- -T 5 http://troubleshooting-service
```

A policy-ignorant CNI will not reproduce the networking failure. For a separate disposable Minikube profile, start with `minikube start -p hw-policy --cni=calico`, repeat baseline setup there, and delete that profile afterward. ContainerCreating can also indicate CNI, image unpacking or volume attachment problems; events identify the actual cause, rather than the status alone.

## Task 3: Mini project

See [mini-project/README.md](mini-project/README.md). Save before/after logs and screenshots from the real cluster for every issue. Cleanup: `kubectl delete namespace hw-troubleshooting`.
