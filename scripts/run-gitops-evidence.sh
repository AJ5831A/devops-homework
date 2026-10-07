#!/usr/bin/env bash
set -euo pipefail
mkdir -p evidence/gitops
exec > >(tee evidence/gitops/runtime.txt) 2>&1
set -x
date -u
git rev-parse HEAD
kubectl version
kubectl -n ingress-nginx rollout status deployment/ingress-nginx-controller --timeout=240s
kubectl -n kube-system rollout status deployment/metrics-server --timeout=240s
kubectl apply -f final-devops-project/kubernetes/namespace.yaml
set +x
LAB_TOKEN=$(openssl rand -hex 24)
echo "::add-mask::$LAB_TOKEN"
kubectl -n devops-final create secret generic devops-demo-secret --from-literal=API_TOKEN="$LAB_TOKEN"
set -x
kubectl apply -f final-devops-project/kubernetes/
kubectl -n devops-final rollout status deployment/devops-demo --timeout=240s
CLUSTER_IP=$(minikube -p gitops-runtime ip)
curl --fail --retry 15 --retry-all-errors --retry-delay 3 -H 'Host: devops.local' "http://$CLUSTER_IP/readyz"
kubectl -n devops-final get pods,svc,ingress,hpa
kubectl -n devops-final get deployment devops-demo -o yaml > evidence/gitops/native-deployment.yaml
# Intentional faults are isolated to this disposable namespace.
kubectl -n devops-final set image deployment/devops-demo app=nginx:does-not-exist
sleep 30
kubectl -n devops-final get pods
kubectl -n devops-final get events --sort-by=.lastTimestamp | tail -20
kubectl -n devops-final rollout undo deployment/devops-demo
kubectl -n devops-final rollout status deployment/devops-demo --timeout=180s
kubectl apply -f final-devops-project/troubleshooting/broken-service.yaml
kubectl -n devops-final get endpointslice -l kubernetes.io/service-name=devops-demo -o yaml
kubectl apply -f final-devops-project/kubernetes/service.yaml
curl --fail --retry 10 --retry-all-errors --retry-delay 2 -H 'Host: devops.local' "http://$CLUSTER_IP/readyz"
kubectl -n devops-final delete secret devops-demo-secret
kubectl -n devops-final rollout restart deployment/devops-demo
sleep 20
kubectl -n devops-final get pods
kubectl -n devops-final get events --sort-by=.lastTimestamp | tail -20
set +x
kubectl -n devops-final create secret generic devops-demo-secret --from-literal=API_TOKEN="$LAB_TOKEN"
set -x
kubectl -n devops-final rollout status deployment/devops-demo --timeout=180s
kubectl -n devops-final patch deployment devops-demo --type=json -p='[{"op":"replace","path":"/spec/template/spec/containers/0/readinessProbe/httpGet/path","value":"/missing"}]'
sleep 25
kubectl -n devops-final get pods
kubectl -n devops-final get events --sort-by=.lastTimestamp | tail -20
kubectl -n devops-final rollout undo deployment/devops-demo
kubectl -n devops-final rollout status deployment/devops-demo --timeout=180s
curl -f -H 'Host: devops.local' "http://$CLUSTER_IP/readyz"
kubectl -n devops-final delete deployment,service,configmap,ingress,hpa devops-demo
helm upgrade --install devops-demo final-devops-project/helm/devops-demo -n devops-final --set ingress.enabled=true --set hpa.enabled=true --wait --timeout 180s
helm upgrade devops-demo final-devops-project/helm/devops-demo -n devops-final --reuse-values --set message='Updated through Helm' --wait --timeout 180s
curl -f -H 'Host: devops.local' "http://$CLUSTER_IP/"
helm rollback devops-demo 1 -n devops-final --wait --timeout 180s
helm history devops-demo -n devops-final
# Load long enough for metrics-server and HPA sampling.
for worker in 1 2 3 4 5 6; do
  (end=$((SECONDS+150)); while ((SECONDS<end)); do curl -fsS -H 'Host: devops.local' "http://$CLUSTER_IP/work?rounds=100000" >/dev/null; done) &
done
for sample in $(seq 1 10); do sleep 15; kubectl -n devops-final get hpa; kubectl -n devops-final top pods || true; done
kubectl -n devops-final describe hpa devops-demo
kubectl -n devops-final logs deployment/devops-demo --tail=20
helm uninstall devops-demo -n devops-final
kubectl create namespace argocd
kubectl apply --server-side -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v3.1.8/manifests/install.yaml
kubectl -n argocd rollout status deployment/argocd-server --timeout=300s
kubectl -n argocd rollout status deployment/argocd-repo-server --timeout=300s
kubectl -n argocd rollout status statefulset/argocd-application-controller --timeout=300s
kubectl -n argocd patch configmap argocd-cmd-params-cm --type merge -p '{"data":{"server.insecure":"true"}}'
kubectl -n argocd rollout restart deployment/argocd-server
kubectl -n argocd rollout status deployment/argocd-server --timeout=180s
kubectl apply -f 19-monitoring-gitops/application.yaml
kubectl apply -f final-devops-project/gitops/application.yaml
wait_app() {
  for attempt in $(seq 1 90); do
    kubectl -n argocd get application "$1"
    state=$(kubectl -n argocd get application "$1" -o jsonpath='{.status.sync.status}/{.status.health.status}')
    if [[ "$state" == Synced/Healthy ]]; then return 0; fi
    sleep 5
  done
  return 1
}
wait_app monitoring-gitops-lab
wait_app devops-final
kubectl -n gitops-lab get pods,svc
kubectl -n devops-final get pods,svc,ingress,hpa
curl -f -H 'Host: devops.local' "http://$CLUSTER_IP/readyz"
# Use a real remote temporary branch for change and rollback, without changing main.
BRANCH="lab/gitops-runtime-$GITHUB_RUN_ID"
git checkout -b "$BRANCH"
git config user.name 'Aryan Jakhar'
git config user.email 'AJ5831A@users.noreply.github.com'
git push origin "$BRANCH"
kubectl -n argocd patch application monitoring-gitops-lab --type merge -p "{\"spec\":{\"source\":{\"targetRevision\":\"$BRANCH\"}}}"
python3 - <<'PY'
from pathlib import Path
p=Path('19-monitoring-gitops/gitops/deployment.yaml')
s=p.read_text(); assert 'replicas: 2' in s; p.write_text(s.replace('replicas: 2','replicas: 3'))
PY
git add 19-monitoring-gitops/gitops/deployment.yaml
git commit -m 'Demonstrate GitOps three-replica promotion'
git push origin "$BRANCH"
kubectl -n argocd annotate application monitoring-gitops-lab argocd.argoproj.io/refresh=hard --overwrite
sleep 15
wait_app monitoring-gitops-lab
kubectl -n gitops-lab rollout status deployment/gitops-web --timeout=180s
test "$(kubectl -n gitops-lab get deployment gitops-web -o jsonpath='{.spec.replicas}')" = 3
kubectl -n gitops-lab scale deployment gitops-web --replicas=1
sleep 25
wait_app monitoring-gitops-lab
test "$(kubectl -n gitops-lab get deployment gitops-web -o jsonpath='{.spec.replicas}')" = 3
kubectl -n gitops-lab get pods
git revert --no-edit HEAD
git push origin "$BRANCH"
kubectl -n argocd annotate application monitoring-gitops-lab argocd.argoproj.io/refresh=hard --overwrite
sleep 15
wait_app monitoring-gitops-lab
test "$(kubectl -n gitops-lab get deployment gitops-web -o jsonpath='{.spec.replicas}')" = 2
kubectl -n gitops-lab get pods
kubectl -n argocd get applications -o wide
kubectl -n argocd port-forward svc/argocd-server 8088:80 >/tmp/argocd-forward.log 2>&1 &
sleep 3
set +x
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d > /tmp/argocd-password
chmod 600 /tmp/argocd-password
