# CoreDNS

CoreDNS is the DNS server commonly deployed for Kubernetes service discovery. kubelet configures Pod resolver settings; queries go to the cluster DNS Service. The CoreDNS `kubernetes` plugin watches API resources and answers Service/Pod domain queries; its `forward` plugin sends other domains to upstream resolvers. Caching reduces repeated lookup work.

```bash
kubectl get -n kube-system deployment coredns
kubectl get -n kube-system service kube-dns
kubectl get -n kube-system configmap coredns -o yaml
kubectl logs -n kube-system -l k8s-app=kube-dns --tail=100
kubectl exec -n hw-services client -- cat /etc/resolv.conf
kubectl exec -n hw-services client -- nslookup kubernetes.default.svc.cluster.local
kubectl exec -n hw-services client -- nslookup example.com
kubectl get -n hw-services service clusterip
kubectl get -n hw-services endpointslices -l kubernetes.io/service-name=clusterip
```

The ConfigMap contains the Corefile, typically with `errors`, `health`, `ready`, `kubernetes`, `forward`, `cache`, `loop`, `reload` and `loadbalance` plugins. Inspect the actual configuration rather than replacing a working cluster's Corefile.

If only one name fails, check spelling, namespace and Service existence. If cluster and external names both fail, inspect Pod resolver settings, DNS Service endpoints, CoreDNS readiness/logs and NetworkPolicies allowing UDP **and** TCP 53. If only external domains fail, investigate upstream forwarding. Successful DNS does not prove application connectivity: separately test the Service port and EndpointSlices. Names/labels can differ on managed clusters. These are expected diagnostic steps; no cluster output was generated locally.
