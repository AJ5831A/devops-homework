# Final troubleshooting challenge

Run in the dedicated `devops-final` lab namespace after a healthy deployment.
Temporarily disable Argo auto-sync/self-heal before fault injection, otherwise
it may repair changes before you observe them. Re-enable it after restoring Git.
All statuses below are expected symptoms, not captured execution evidence.

| Fault | Investigate | Root cause | Repair and verify |
| --- | --- | --- | --- |
| Invalid image | `kubectl -n devops-final set image deployment/devops-demo app=nginx:does-not-exist`; get Pods; describe the failing Pod | Registry cannot resolve the tag; Events show ErrImagePull then ImagePullBackOff | `kubectl -n devops-final rollout undo deployment/devops-demo`; rollout status |
| Service selector | `kubectl apply -f troubleshooting/broken-service.yaml`; get EndpointSlices with `-l kubernetes.io/service-name=devops-demo`; compare Pod labels | `wrong-label` selects no Pods | Restore Service from Git/native YAML or `helm upgrade`; curl `/readyz` through Service |
| Missing Secret | Delete the lab Secret then `kubectl -n devops-final rollout restart deployment/devops-demo`; describe new Pod | New container cannot resolve required Secret, CreateContainerConfigError; existing Pods may still serve | Recreate Secret from local token; rollout status; never print token to evidence |
| Wrong probe path | `kubectl -n devops-final patch deployment devops-demo --type=json -p='[{"op":"replace","path":"/spec/template/spec/containers/0/readinessProbe/httpGet/path","value":"/missing"}]'` | HTTP 404 fails readiness; Pods can be Running but unready | Restore chart/probe `/readyz`; endpoints become ready |

For each case record: timestamp, command, Pod state, relevant Events/logs,
root cause, repair command and a successful request. Obtain logs using
`kubectl -n devops-final logs deployment/devops-demo --tail=30` and cluster
Events using `kubectl -n devops-final get events --sort-by=.lastTimestamp`.

Verify the final healthy state:

```bash
kubectl -n devops-final rollout status deployment/devops-demo --timeout=180s
kubectl -n devops-final get pods,svc,ingress,hpa
kubectl -n devops-final port-forward svc/devops-demo 8080:80
# Another terminal:
curl -fsS http://localhost:8080/readyz
```
