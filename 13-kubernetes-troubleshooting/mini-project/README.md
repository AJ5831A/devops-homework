# Mini Project: Repair an nginx Application

Prerequisite: parent README baseline deployed in `hw-troubleshooting`. Run from this folder.

```bash
kubectl apply -n hw-troubleshooting -f broken-pod.yaml
kubectl get -n hw-troubleshooting pod project-broken-pod
kubectl describe -n hw-troubleshooting pod project-broken-pod
kubectl get -n hw-troubleshooting events --sort-by=.metadata.creationTimestamp
# Only after capturing the pull failure:
kubectl apply -n hw-troubleshooting -f fixed-pod.yaml
kubectl wait -n hw-troubleshooting --for=condition=Ready pod/project-broken-pod --timeout=180s
kubectl get -n hw-troubleshooting pod project-broken-pod -o wide
# Now break the selector:
kubectl apply -n hw-troubleshooting -f broken-service.yaml
kubectl get -n hw-troubleshooting pods --show-labels
kubectl describe -n hw-troubleshooting service troubleshooting-service
kubectl get -n hw-troubleshooting endpointslices -l kubernetes.io/service-name=troubleshooting-service
kubectl exec -n hw-troubleshooting client -- wget -qO- -T 5 http://troubleshooting-service
kubectl apply -n hw-troubleshooting -f service.yaml
kubectl get -n hw-troubleshooting endpointslices -l kubernetes.io/service-name=troubleshooting-service
kubectl exec -n hw-troubleshooting client -- wget -qO- -T 5 http://troubleshooting-service
```

| Problem | Expected before | Diagnostic evidence to capture | Root cause | Fix / expected after |
| --- | --- | --- | --- | --- |
| Broken Pod / image | ErrImagePull followed by ImagePullBackOff | describe/events registry error; actual message depends on registry | nginx:homework-bad-tag does not exist | Valid tag nginx:1.28-alpine; Pod ready |
| Service | DNS resolves, HTTP fails; no usable endpoints | Pod labels versus Service selector and EndpointSlices | wrong-app selector matches no Pods | troubleshooting-app selector; ready endpoint addresses and HTTP text `Troubleshooting repaired` |

These outcomes are expected, not execution evidence. Capture the actual registry error rather than inventing its exact wording. The useful command for the image error is `describe pod`, because no container started to emit application logs.

## Review answers

1. `get` shows current resource summaries and status.
2. `describe` adds conditions, configuration and recent events.
3. `logs` exposes application output and crash messages.
4. `exec` helps inspect a running container's files, environment or connectivity.
5. CrashLoopBackOff is a delay between repeated failed container restarts.
6. ImagePullBackOff is delayed retry after failing to fetch an image.
7. Pending can mean no suitable node, insufficient resources or unbound storage.
8. A Service may have no ready endpoints because its selector mismatches labels, Pods are not ready, or there are no Pods.
9. Service selectors choose Pods by labels; Pod names do not control selection.
10. Kubernetes DNS resolves Service and configured Pod names so clients avoid hardcoded IPs.

Final path: client → Service → ready EndpointSlice addresses → either of the two nginx Pods. A healthy Pod alone does not prove the Service selector or network path works.
