# Kubernetes Networking and Services

> Runtime evidence is pending: this authoring environment has no Kubernetes cluster, kubectl or Minikube. Commands and expected behavior below are a reproducible lab guide, not claimed execution output. Capture real output/screenshots on a cluster before submission. Use only the disposable namespace indicated; cleanup removes that lab’s resources.

## Task 1: Five Service patterns

Headless is a ClusterIP configuration (`clusterIP: None`), rather than a fifth value of `spec.type`.

```bash
kubectl create namespace hw-services
kubectl apply -n hw-services -f .
kubectl rollout status -n hw-services deployment/web
kubectl get -n hw-services services -o wide
kubectl get -n hw-services endpointslices
kubectl run client -n hw-services --image=busybox:1.37 --restart=Never -- sleep 3600
kubectl wait -n hw-services --for=condition=Ready pod/client --timeout=120s
kubectl exec -n hw-services client -- wget -qO- http://clusterip
kubectl exec -n hw-services client -- nslookup headless
kubectl exec -n hw-services client -- wget -qO- http://headless
kubectl exec -n hw-services client -- nslookup externalname
kubectl exec -n hw-services client -- wget -qO- http://externalname
minikube service nodeport -n hw-services --url
# Open the returned URL; keep the tunnel terminal running on macOS.
minikube tunnel
# Second terminal, after EXTERNAL-IP appears:
kubectl get -n hw-services service loadbalancer
# curl http://<actual-external-ip>
```

| Service | Expected result / scope |
| --- | --- |
| ClusterIP | Internal stable virtual IP routes to ready web Pods |
| NodePort | Node port 30080 forwards to web; macOS Docker driver may need `minikube service` tunnel |
| LoadBalancer | External IP depends on provider; Minikube requires its tunnel, otherwise Pending is normal |
| ExternalName | DNS CNAME to example.com; no proxy or Pod endpoints; HTTP/TLS host mismatch can make arbitrary external sites reject requests |
| Headless | DNS returns backing Pod IPs without a Service virtual IP |

Save each Service YAML, DNS answer, curl/wget response and screenshot. Cleanup: `kubectl delete namespace hw-services` and stop tunnels.

## Task 2: Object comparisons

| Dimension | Deployment | ReplicaSet |
| --- | --- | --- |
| Purpose / Pods | Declarative application lifecycle through owned ReplicaSets | Maintain matching Pod count |
| Scaling | Change replicas; controller adjusts current ReplicaSet | Change replicas directly |
| Rolling update | Creates new ReplicaSet, scales new up and old down | No managed rolling update |
| Relationship | Owns ReplicaSets; usually manage this level | Usually owned by a Deployment |

| Dimension | Deployment | DaemonSet | StatefulSet |
| --- | --- | --- | --- |
| Use / example | Interchangeable web/API replicas | Per-node log collector or network agent | Database members with stable identity |
| Creation | ReplicaSets create replaceable Pods | One Pod per eligible node | Stable ordinal names, ordered lifecycle by default |
| Scaling | Replica count / HPA | Eligible node count | Replica count, respecting identity |
| Networking | Usually common Service | Often node-local or host ports, can use Service | Governing headless Service and stable Pod DNS |
| Storage | Shared/external data or PVC as needed | Often node-local hostPath | Per-Pod PVCs through volumeClaimTemplates |

A ReplicaSet maintains Pods; a Service discovers ready matching Pods and provides network access. Pod IPs change when Pods are replaced. Service selectors match labels; EndpointSlices publish eligible endpoints and the network proxy routes traffic to them. A Service does not create or restart Pods.

## Tasks 3–4: DNS

See [FQDN](fqdn/README.md) and [CoreDNS](coredns/README.md).
