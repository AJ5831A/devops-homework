# Kubernetes Storage, HPA and Probes

> Runtime evidence is pending: this authoring environment has no Kubernetes cluster, kubectl or Minikube. Commands and expected behavior below are a reproducible lab guide, not claimed execution output. Capture real output/screenshots on a cluster before submission. Use only the disposable namespace indicated; cleanup removes that lab’s resources.

## Task 1: Volumes

See [01-kubernetes-volumes](01-kubernetes-volumes/README.md) for emptyDir, hostPath, static PV/PVC and dynamic provisioning examples.

## Task 2: HPA and load generation

Use a disposable **single-node Minikube** cluster, with a default StorageClass and metrics-server. Run these commands from this folder:

```bash
kubectl create namespace hw-storage
minikube addons enable metrics-server
kubectl get storageclass
kubectl apply -n hw-storage -f hpa/application.yaml
kubectl apply -n hw-storage -f hpa/hpa.yml
kubectl rollout status -n hw-storage deployment/cpu-demo
kubectl get -n hw-storage hpa
kubectl top pods -n hw-storage
kubectl apply -n hw-storage -f hpa/load-generator.yaml
kubectl get -n hw-storage hpa -w
# Separate terminal:
kubectl get -n hw-storage pods
kubectl top pods -n hw-storage
kubectl describe -n hw-storage hpa cpu-demo
# Stop load and watch the stabilization period:
kubectl delete -n hw-storage -f hpa/load-generator.yaml
```

Expected: utilization rises above the 50% CPU-request target and desired replicas increase (up to five). This CPU-intensive sample makes load more visible than nginx static pages. Exact CPU percentages/counts depend on available capacity and traffic; they are not guaranteed. Unknown metrics require checking metrics-server and CPU requests. Scaling down commonly waits several minutes. Record actual idle, loaded and cooldown HPA/Pod/metrics output and screenshots.

## Task 3: Mini project

[Mini project](mini-project/README.md) combines persistent storage, HTTP Service, HPA and all three probes. Cleanup after both exercises: `kubectl delete namespace hw-storage`. PVC deletion may destroy dynamically provisioned data; run only in this disposable lab. Static retained PV cleanup is documented separately.
