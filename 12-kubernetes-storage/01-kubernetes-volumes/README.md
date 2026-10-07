# Kubernetes Volumes

| Type | Lifetime / purpose |
| --- | --- |
| emptyDir | Pod lifetime; shared scratch space survives container restart, not Pod deletion |
| hostPath | Mounts a path on the node; node-specific and can expose host files |
| PersistentVolume | Cluster-scoped storage resource, independent of an individual Pod |
| PersistentVolumeClaim | Namespaced request bound to a compatible PV |
| StorageClass | Provisioner and policy for dynamically creating volumes |
| Dynamic provisioning | A PVC triggers allocation through the selected/default StorageClass |

Run from this directory after creating `hw-storage` as in the parent README.

```bash
kubectl apply -n hw-storage -f emptydir.yaml
kubectl wait -n hw-storage --for=condition=Ready pod/emptydir --timeout=120s
kubectl exec -n hw-storage emptydir -- sh -c 'echo scratch > /data/note'
kubectl exec -n hw-storage emptydir -- cat /data/note
kubectl delete -n hw-storage -f emptydir.yaml
kubectl apply -n hw-storage -f emptydir.yaml
kubectl wait -n hw-storage --for=condition=Ready pod/emptydir --timeout=120s
kubectl exec -n hw-storage emptydir -- ls -la /data
kubectl apply -n hw-storage -f hostpath.yaml
kubectl apply -n hw-storage -f static.yaml
kubectl apply -n hw-storage -f static-reader.yaml
kubectl get pv
kubectl get -n hw-storage pvc
kubectl wait -n hw-storage --for=condition=Ready pod/static-reader --timeout=120s
kubectl exec -n hw-storage static-reader -- sh -c 'echo persistent > /data/note'
kubectl delete -n hw-storage -f static-reader.yaml
kubectl apply -n hw-storage -f static-reader.yaml
kubectl wait -n hw-storage --for=condition=Ready pod/static-reader --timeout=120s
kubectl exec -n hw-storage static-reader -- cat /data/note
kubectl get storageclass -o wide
kubectl apply -n hw-storage -f ../mini-project/pvc.yaml
kubectl describe -n hw-storage pvc web-data
```

Expected: emptyDir is empty after recreating its Pod; the static PVC file survives recreation. The static claim uses `storageClassName: ""` and a named PV; the dynamic claim omits the class to use the cluster default. With WaitForFirstConsumer, dynamic binding waits until a consuming Pod is scheduled. A missing default class leaves the claim pending. Minikube's default provisioner stores data inside its node, not directly on your laptop.

These hostPath examples are deliberately single-node labs, unsuitable for movable multi-node workloads. Delete reader Pods and claims first, then `kubectl delete pv homework-static`. The Retain policy leaves data on the node; destroy the disposable Minikube profile when finished or remove only the lab paths there. The [hosted transcript](../../evidence/kubernetes/20261007T150232Z/transcript.log) records emptyDir reset, hostPath write/read and static PVC persistence; the runner used distinct PV name `homework-runtime-static`.
