# Fully Qualified Domain Names

An FQDN identifies a DNS name through every hierarchy component; a trailing dot explicitly marks the DNS root. The default Kubernetes Service pattern is `<service>.<namespace>.svc.<cluster-domain>`.

For this lab: `clusterip.hw-services.svc.cluster.local.`. `cluster.local` is a common default and may differ in another cluster. From a Pod in `hw-services`, `clusterip` works through DNS search suffixes. From another namespace, use `clusterip.hw-services` or the complete FQDN. `localhost` points to the calling Pod, not another Pod or Service.

```bash
kubectl exec -n hw-services client -- cat /etc/resolv.conf
kubectl exec -n hw-services client -- nslookup clusterip.hw-services.svc.cluster.local
kubectl exec -n hw-services client -- wget -qO- http://clusterip.hw-services.svc.cluster.local
```

Expected: ClusterIP DNS resolves to the Service IP; headless DNS resolves to ready Pod IPs. A StatefulSet can publish `web-0.headless.hw-services.svc.cluster.local` when its governing Service/subdomain is configured. A Service name is not automatically resolvable from your laptop. Runtime output has not been captured here.
