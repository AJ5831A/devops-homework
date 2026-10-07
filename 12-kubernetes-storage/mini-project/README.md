# Mini Project: Persistent Web Application with Autoscaling and Probes

Run from this folder in the parent README's single-node Minikube cluster. All replicas share one ReadWriteOnce PVC **on the same node**; RWO permits multiple Pods on one node. This is an educational topology, not a multi-node production architecture. Use shared RWX storage or per-replica StatefulSet claims when designing a different topology.

```bash
kubectl apply -n hw-storage -f pvc.yaml
kubectl apply -n hw-storage -f deployment.yaml
kubectl apply -n hw-storage -f service.yaml
kubectl apply -n hw-storage -f hpa.yaml
kubectl rollout status -n hw-storage deployment/web-app
kubectl get -n hw-storage pvc,pods,svc,hpa
kubectl exec -n hw-storage deployment/web-app -- sh -c 'echo "Aryan Jakhar" > /data/student.txt'
# Restart every replica so the check cannot accidentally select a surviving Pod:
kubectl rollout restart -n hw-storage deployment/web-app
kubectl rollout status -n hw-storage deployment/web-app
kubectl exec -n hw-storage deployment/web-app -- cat /data/student.txt
kubectl port-forward -n hw-storage service/web-app 8082:80
# Second terminal:
curl http://127.0.0.1:8082
kubectl run web-load -n hw-storage --image=busybox:1.37 --restart=Never -- sh -c 'while true; do wget -q -O /dev/null http://web-app; done'
kubectl top pods -n hw-storage
kubectl describe -n hw-storage hpa web-app
kubectl get -n hw-storage hpa -w
# After capture:
kubectl delete -n hw-storage pod web-load
```

Expected: PVC binds, two or more replicas become ready, nginx returns a page, and student.txt survives replacement. Static-page traffic may not consume enough CPU to scale; capture the actual result rather than asserting five replicas. The separate CPU demo in the parent folder demonstrates scaling more reliably.

Startup probes gate readiness/liveness until initialization succeeds; repeated failure restarts the container. Readiness failure removes a Pod from ready Service endpoints without restarting it. Liveness failure restarts the container. All probes here query `/` on port 80. To demonstrate readiness failure:

```bash
kubectl patch -n hw-storage deployment web-app --type=json -p '[{"op":"replace","path":"/spec/template/spec/containers/0/readinessProbe/httpGet/path","value":"/missing"}]'
kubectl get -n hw-storage pods
kubectl describe -n hw-storage pods -l app=web-app
# New Pods fail readiness; old healthy Pods can remain during rolling update.
kubectl apply -n hw-storage -f deployment.yaml
kubectl rollout status -n hw-storage deployment/web-app
```

The [hosted transcript](../../evidence/kubernetes/20261007T150232Z/transcript.log) records readiness warnings and restored rollout, persistence readback, HTTP response and HPA samples. The nginx web HPA remained at two replicas; the separate CPU demonstration scaled to five. See the [evidence index](../../evidence/kubernetes/README.md) for targeted scaling/cooldown validation.
