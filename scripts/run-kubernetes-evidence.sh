#!/usr/bin/env bash
# Executes real disposable Kubernetes labs; Bash 3.2+ (macOS/Linux).
# Prerequisite: minikube start -p devops-homework, ingress + metrics-server addons.
# CLEANUP=1 removes only this script's labeled namespaces on exit; default retains evidence workloads.
set -uo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
PROFILE=devops-homework
STAMP=$(date -u +%Y%m%dT%H%M%SZ)
OUT="$ROOT/evidence/kubernetes/$STAMP"
mkdir -p "$OUT"
exec > >(tee "$OUT/transcript.log") 2>&1
FAIL=0
NS=''
PIDS=''
NAMESPACES=''
k() { kubectl --context="$PROFILE" --request-timeout=30s "$@"; }
log() { printf '\n[%s] %s\n' "$(date -u +%FT%TZ)" "$*"; }
run() {
  log "RUN: $*"
  "$@"; rc=$?
  log "EXIT: $rc"
  if [ "$rc" -ne 0 ]; then FAIL=$((FAIL+1)); fi
  return 0
}
expected_failure() {
  log "EXPECTED FAILURE: $*"
  "$@"; rc=$?
  log "OBSERVED EXIT: $rc"
  if [ "$rc" -eq 0 ]; then log 'Unexpected success'; FAIL=$((FAIL+1)); fi
}
optional() { log "OPTIONAL / ENVIRONMENT-DEPENDENT: $*"; "$@"; log "OBSERVED EXIT: $?"; }
apply() { run k -n "$NS" apply -f "$ROOT/$1"; }
ready() { run k -n "$NS" wait --for=condition=Ready "pod/$1" --timeout=180s; }
rollout() { run k -n "$NS" rollout status "deployment/$1" --timeout=240s; }
observe() {
  run k -n "$NS" get pods -o wide
  run k -n "$NS" get events --sort-by=.metadata.creationTimestamp
}
client() {
  run k -n "$NS" run client --image=busybox:1.37 --restart=Never -- sleep 14400
  ready client
}
http() { run k -n "$NS" exec client -- wget -qO- -T 10 "$1"; }
http_expect() {
  run k -n "$NS" exec client -- sh -c 'for attempt in 1 2 3 4 5; do response=$(wget -qO- -T 5 "$1") || response=""; printf "%s\n" "$response"; [ "$response" = "$2" ] && exit 0; sleep 2; done; exit 1' sh "$1" "$2"
}
wait_text() {
  # Wait for a real state transition without inventing output; bounded to 90 s.
  resource=$1; path=$2; pattern=$3; max_attempts=${4:-30}; attempt=0
  log "WAIT: $resource $path matches $pattern"
  while [ "$attempt" -lt "$max_attempts" ]; do
    value=$(k -n "$NS" get "$resource" -o "jsonpath=$path" 2>/dev/null || true)
    if printf '%s' "$value" | grep -Eq "$pattern"; then log "OBSERVED: $value"; return 0; fi
    attempt=$((attempt+1)); sleep 3
  done
  log "TIMEOUT: last observed '$value'"; FAIL=$((FAIL+1))
}
namespace() {
  NS="hw-runtime-$1"
  log "START LAB: $NS"
  if k get namespace "$NS" >/dev/null 2>&1; then
    owner=$(k get namespace "$NS" -o 'jsonpath={.metadata.labels.homework-runner}')
    if [ "$owner" != 'kubernetes-evidence' ]; then log "Refusing to reset unowned namespace $NS"; exit 2; fi
    k delete namespace "$NS" --wait=true --timeout=180s || exit 2
  fi
  k create namespace "$NS" || exit 2
  k label namespace "$NS" homework-runner=kubernetes-evidence || exit 2
  NAMESPACES="$NAMESPACES $NS"
}
cleanup() {
  for pid in $PIDS; do kill "$pid" 2>/dev/null || true; done
  if [ "${CLEANUP:-0}" = 1 ]; then
    for ns in $NAMESPACES; do
      owner=$(k get namespace "$ns" -o 'jsonpath={.metadata.labels.homework-runner}' 2>/dev/null || true)
      [ "$owner" != kubernetes-evidence ] || k delete namespace "$ns" --wait=false
    done
  fi
}
trap cleanup EXIT
trap 'exit 130' INT TERM
log "Evidence directory: $OUT"
k cluster-info || exit 2
run k version
run minikube -p "$PROFILE" status
run k get nodes -o wide
run k get pods -n kube-system

# 08 — basics tutorial.
namespace fundamentals
apply 08-kubernetes-fundamentals/deployment.yaml
rollout hello
run k -n "$NS" get deploy,rs,pods,svc
run k -n "$NS" describe deployment hello
run k -n "$NS" logs deployment/hello
run k -n "$NS" exec deployment/hello -- cat /usr/share/nginx/html/index.html
client; http_expect http://hello "Hello from Kubernetes"
run k -n "$NS" scale deployment/hello --replicas=3
rollout hello
run k -n "$NS" set image deployment/hello web=nginx:1.28
rollout hello
run k -n "$NS" rollout history deployment/hello
observe

# 09 — strategies: actual response content and replica history.
namespace workloads
client
apply 09-kubernetes-workloads/rolling/v1.yaml; rollout rolling; http_expect http://rolling "rolling v1"
k -n "$NS" get pods -w > "$OUT/rolling-watch.log" 2>&1 & PIDS="$PIDS $!"; watcher=$!
apply 09-kubernetes-workloads/rolling/v2.yaml; rollout rolling; http_expect http://rolling "rolling v2"
kill "$watcher" 2>/dev/null || true
run k -n "$NS" get rs,pods
apply 09-kubernetes-workloads/blue-green/; rollout blue; rollout green; http_expect http://active blue
run k -n "$NS" patch service active -p '{"spec":{"selector":{"track":"green"}}}'
http_expect http://active green
apply 09-kubernetes-workloads/canary/; rollout stable; rollout canary
wait_text endpoints/canary-route '{.subsets[0].addresses[*].ip}' '^([^ ]+ ){9}[^ ]+$'
sleep 3
run k -n "$NS" exec client -- sh -c 'samples=$(for i in $(seq 1 100); do wget -qO- -T 5 http://canary-route; done); printf "%s\n" "$samples"; printf "%s\n" "$samples" | grep -qx stable && printf "%s\n" "$samples" | grep -qx canary'
apply 09-kubernetes-workloads/recreate/v1.yaml; rollout recreate; http_expect http://recreate "recreate v1"
k -n "$NS" get pods -w > "$OUT/recreate-watch.log" 2>&1 & PIDS="$PIDS $!"; watcher=$!
apply 09-kubernetes-workloads/recreate/v2.yaml; rollout recreate; http_expect http://recreate "recreate v2"
kill "$watcher" 2>/dev/null || true
apply 09-kubernetes-workloads/replicaset.yaml
run k -n "$NS" scale rs/standalone --replicas=3
# Free strategy resources before twelve lifecycle examples.
run k -n "$NS" delete deployments --all --wait=true --timeout=120s
run k -n "$NS" delete rs standalone --wait=true --timeout=120s
for file in "$ROOT"/09-kubernetes-workloads/lifecycle/*.yaml; do
  name=$(k create --dry-run=client -f "$file" -o 'jsonpath={.metadata.name}')
  run k -n "$NS" apply -f "$file"
  case "$name" in
    succeeded) wait_text "pod/$name" '{.status.phase}' '^Succeeded$' ;;
    failed) wait_text "pod/$name" '{.status.phase}' '^Failed$' ;;
    pending) wait_text "pod/$name" '{.status.conditions[?(@.type=="PodScheduled")].reason}' 'Unschedulable' ;;
    imagepull) wait_text "pod/$name" '{.status.containerStatuses[0].state.waiting.reason}' 'ErrImagePull|ImagePullBackOff' ;;
    crashloop) wait_text "pod/$name" '{.status.containerStatuses[0].state.waiting.reason}' 'CrashLoopBackOff' ;;
    *) ready "$name" ;;
  esac
  run k -n "$NS" get pod "$name" -o wide
  run k -n "$NS" describe pod "$name"
  case "$name" in
    pending|imagepull) : ;;
    multi-container) run k -n "$NS" logs "$name" -c main; run k -n "$NS" logs "$name" -c sidecar ;;
    *) optional k -n "$NS" logs "$name" ;;
  esac
  case "$name" in
    readiness) run k -n "$NS" exec "$name" -- rm /tmp/healthy; wait_text "pod/$name" '{.status.containerStatuses[0].ready}' '^false$' ;;
    liveness) run k -n "$NS" exec "$name" -- sh -c 'for n in $(seq 1 30); do test -f /tmp/healthy && exit 0; sleep 1; done; exit 1'; run k -n "$NS" exec "$name" -- rm /tmp/healthy; wait_text "pod/$name" '{.status.containerStatuses[0].restartCount}' '^[1-9]' ;;
    termination) k -n "$NS" logs -f "$name" > "$OUT/termination.log" 2>&1 & PIDS="$PIDS $!" ;;
  esac
  run k -n "$NS" delete -f "$file" --wait=true --timeout=60s
 done
observe

# 10 — all Service patterns; prove internal paths and attempt host paths.
namespace services
apply 10-kubernetes-services/; rollout web; client
run k -n "$NS" get svc -o wide
run k -n "$NS" get endpointslices
http http://clusterip; http http://headless
run k -n "$NS" exec client -- nslookup "headless.$NS.svc.cluster.local."
run k -n "$NS" exec client -- nslookup "externalname.$NS.svc.cluster.local."
optional k -n "$NS" exec client -- wget -qO- -T 10 http://externalname
nodeip=$(k get nodes -o 'jsonpath={.items[0].status.addresses[?(@.type=="InternalIP")].address}')
http "http://$nodeip:30080"
run k -n "$NS" exec client -- cat /etc/resolv.conf
run k -n "$NS" exec client -- nslookup "clusterip.$NS.svc.cluster.local"
run k -n kube-system get configmap coredns -o yaml
run k -n kube-system logs -l k8s-app=kube-dns --tail=30
minikube -p "$PROFILE" service nodeport -n "$NS" --url > "$OUT/nodeport-url.log" 2>&1 </dev/null & PIDS="$PIDS $!"; servicepid=$!
sleep 8
url=$(grep -E '^http://' "$OUT/nodeport-url.log" | head -1 || true)
if [ -n "$url" ]; then optional curl --max-time 15 -fsS "$url"; else log 'NodePort host URL unavailable; node-port path tested from the cluster.'; fi
kill "$servicepid" 2>/dev/null || true
minikube -p "$PROFILE" tunnel > "$OUT/loadbalancer-tunnel.log" 2>&1 </dev/null & PIDS="$PIDS $!"; tunnelpid=$!
sleep 12
run k -n "$NS" get service loadbalancer -o yaml
lb=$(k -n "$NS" get svc loadbalancer -o 'jsonpath={.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)
if [ -z "$lb" ]; then
  wait_text service/loadbalancer '{.status.loadBalancer.ingress[0].ip}' '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+'
  lb=$(k -n "$NS" get svc loadbalancer -o 'jsonpath={.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)
fi
if [ -n "$lb" ]; then run curl --max-time 15 --retry 3 --retry-connrefused -fsS "http://$lb"; else log 'FAIL: LoadBalancer external address unavailable; see tunnel log.'; FAIL=$((FAIL+1)); fi
http http://loadbalancer
kill "$tunnelpid" 2>/dev/null || true

# 11 — env injection, Ingress routing, and malformed Secret reference repair.
namespace config
apply 11-kubernetes-ingress-config/configmap.yaml
apply 11-kubernetes-ingress-config/secret.example.yaml
apply 11-kubernetes-ingress-config/deployment.yaml; rollout config-web
run k -n "$NS" exec deployment/config-web -- printenv APP_ENV GREETING
run k -n "$NS" exec deployment/config-web -- sh -c 'test "$DB_PASSWORD" = DEMO_ONLY_REPLACE_LOCALLY && echo demo-secret-matches'
run minikube -p "$PROFILE" addons enable ingress
run k -n ingress-nginx rollout status deployment/ingress-nginx-controller --timeout=240s
apply 11-kubernetes-ingress-config/ingress.yaml
run k -n "$NS" describe ingress web
k -n ingress-nginx port-forward service/ingress-nginx-controller 18081:80 > "$OUT/ingress-port-forward.log" 2>&1 & PIDS="$PIDS $!"; ingresspid=$!
sleep 4
run curl --max-time 20 --retry 5 --retry-connrefused --retry-delay 2 -fsS -H 'Host: homework.local' http://127.0.0.1:18081/
expected_failure curl --max-time 10 -fsS -H 'Host: unknown.local' http://127.0.0.1:18081/
kill "$ingresspid" 2>/dev/null || true
apply 11-kubernetes-ingress-config/troubleshooting/broken-deployment.yaml
wait_text pods '{.items[*].status.containerStatuses[*].state.waiting.reason}' CreateContainerConfigError
run k -n "$NS" describe pods -l app=config-web
apply 11-kubernetes-ingress-config/deployment.yaml; rollout config-web
run k -n "$NS" exec deployment/config-web -- sh -c 'test -n "$DB_PASSWORD" && echo configured'

# 12 — actual emptyDir loss, PVC persistence, probes, and autoscaling samples.
namespace storage
run minikube -p "$PROFILE" addons enable metrics-server
run k -n kube-system rollout status deployment/metrics-server --timeout=240s
run k get storageclass
apply 12-kubernetes-storage/01-kubernetes-volumes/emptydir.yaml; ready emptydir
run k -n "$NS" exec emptydir -- sh -c 'echo scratch > /data/note; cat /data/note'
run k -n "$NS" delete pod emptydir --wait=true
apply 12-kubernetes-storage/01-kubernetes-volumes/emptydir.yaml; ready emptydir
run k -n "$NS" exec emptydir -- sh -c 'test ! -e /data/note && echo emptyDir-reset-confirmed'
apply 12-kubernetes-storage/01-kubernetes-volumes/hostpath.yaml; ready hostpath
run k -n "$NS" exec hostpath -- sh -c 'echo hostpath > /data/homework-runner-note; cat /data/homework-runner-note'
# Static PV is cluster-scoped: use a distinct runner-owned name, never overwrite homework-static.
sed 's/homework-static/homework-runtime-static/g' "$ROOT/12-kubernetes-storage/01-kubernetes-volumes/static.yaml" > "$OUT/static-runtime.yaml"
if k get pv homework-runtime-static >/dev/null 2>&1; then
  owner=$(k get pv homework-runtime-static -o 'jsonpath={.metadata.labels.homework-runner}')
  if [ "$owner" = kubernetes-evidence ]; then run k delete pv homework-runtime-static --wait=true --timeout=30s; else log 'Refusing to replace unowned static PV'; exit 2; fi
fi
run k -n "$NS" apply -f "$OUT/static-runtime.yaml"
run k label pv homework-runtime-static homework-runner=kubernetes-evidence
apply 12-kubernetes-storage/01-kubernetes-volumes/static-reader.yaml; ready static-reader
run k -n "$NS" exec static-reader -- sh -c 'echo persistent > /data/note'
run k -n "$NS" delete pod static-reader --wait=true
apply 12-kubernetes-storage/01-kubernetes-volumes/static-reader.yaml; ready static-reader
run k -n "$NS" exec static-reader -- cat /data/note
apply 12-kubernetes-storage/mini-project/pvc.yaml
apply 12-kubernetes-storage/mini-project/deployment.yaml
apply 12-kubernetes-storage/mini-project/service.yaml
apply 12-kubernetes-storage/mini-project/hpa.yaml
rollout web-app
run k -n "$NS" exec deployment/web-app -- sh -c 'echo Aryan-Jakhar > /data/student.txt'
run k -n "$NS" rollout restart deployment/web-app; rollout web-app
run k -n "$NS" exec deployment/web-app -- cat /data/student.txt
client; http http://web-app
apply 12-kubernetes-storage/hpa/application.yaml; rollout cpu-demo
apply 12-kubernetes-storage/hpa/hpa.yml
run k -n "$NS" get hpa,pods
optional k -n "$NS" top pods
apply 12-kubernetes-storage/hpa/load-generator.yaml
run k -n "$NS" run web-load --image=busybox:1.37 --restart=Never -- sh -c 'while true; do wget -q -O /dev/null -T 5 http://web-app; done'
for sample in 1 2 3 4 5 6; do
  log "HPA LOAD SAMPLE $sample"
  run k -n "$NS" get hpa,pods
  optional k -n "$NS" top pods
  sleep 15
 done
wait_text hpa/cpu-demo '{.status.currentReplicas}' '^[2-5]$' 60
wait_text deployment/cpu-demo '{.status.readyReplicas}' '^[2-5]$' 60
run k -n "$NS" describe hpa cpu-demo
run k -n "$NS" delete pod load-generator web-load
run k -n "$NS" patch deployment web-app --type=json -p '[{"op":"replace","path":"/spec/template/spec/containers/0/readinessProbe/httpGet/path","value":"/missing"}]'
sleep 10
run k -n "$NS" describe pods -l app=web-app
apply 12-kubernetes-storage/mini-project/deployment.yaml; rollout web-app
run k -n "$NS" get pvc,hpa,pods
# Keep a final cooldown snapshot; full HPA downscale stabilization can take five minutes.
optional k -n "$NS" top pods
observe

# 13 — faults, their actual events/logs, repairs and connectivity assertions.
namespace troubleshooting
apply 13-kubernetes-troubleshooting/mini-project/deployment.yaml
apply 13-kubernetes-troubleshooting/mini-project/service.yaml
rollout troubleshooting-app; client; http http://troubleshooting-service
run k explain pod.spec.containers
optional k -n "$NS" events
optional k -n "$NS" top pods
apply 13-kubernetes-troubleshooting/issues/crash.yaml
wait_text pod/crash '{.status.containerStatuses[0].state.waiting.reason}' CrashLoopBackOff
run k -n "$NS" describe pod crash
optional k -n "$NS" logs crash --previous
run k -n "$NS" delete pod crash
run k -n "$NS" run crash --image=busybox:1.37 --restart=Never -- sleep 3600; ready crash
apply 13-kubernetes-troubleshooting/mini-project/broken-pod.yaml
wait_text pod/project-broken-pod '{.status.containerStatuses[0].state.waiting.reason}' 'ErrImagePull|ImagePullBackOff'
run k -n "$NS" describe pod project-broken-pod
apply 13-kubernetes-troubleshooting/mini-project/fixed-pod.yaml; ready project-broken-pod
apply 13-kubernetes-troubleshooting/issues/pending.yaml
wait_text pod/pending '{.status.conditions[?(@.type=="PodScheduled")].reason}' Unschedulable
run k -n "$NS" describe pod pending
run k -n "$NS" delete pod pending
run k -n "$NS" run pending --image=busybox:1.37 --restart=Never -- sleep 3600; ready pending
apply 13-kubernetes-troubleshooting/issues/containercreating.yaml
sleep 5
run k -n "$NS" describe pod mount-error
run k -n "$NS" create configmap missing-config --from-literal=message=repaired; ready mount-error
apply 13-kubernetes-troubleshooting/issues/config.yaml
wait_text pod/config-error '{.status.containerStatuses[0].state.waiting.reason}' CreateContainerConfigError
run k -n "$NS" describe pod config-error
run k -n "$NS" create configmap missing-env --from-literal=APP_ENV=homework; ready config-error
run k -n "$NS" exec config-error -- printenv APP_ENV
apply 13-kubernetes-troubleshooting/mini-project/broken-service.yaml
sleep 3
run k -n "$NS" get pods --show-labels
run k -n "$NS" describe service troubleshooting-service
run k -n "$NS" get endpointslices -l kubernetes.io/service-name=troubleshooting-service
expected_failure k -n "$NS" exec client -- wget -qO- -T 5 http://troubleshooting-service
apply 13-kubernetes-troubleshooting/mini-project/service.yaml
sleep 3
http http://troubleshooting-service
apply 13-kubernetes-troubleshooting/issues/dns.yaml; ready bad-dns
run k -n "$NS" exec bad-dns -- cat /etc/resolv.conf
expected_failure k -n "$NS" exec bad-dns -- nslookup -timeout=2 -retry=1 troubleshooting-service
run k -n "$NS" delete pod bad-dns
run k -n "$NS" run bad-dns --image=busybox:1.37 --restart=Never -- sleep 3600; ready bad-dns
run k -n "$NS" exec bad-dns -- nslookup "troubleshooting-service.$NS.svc.cluster.local."
cni=$(k -n kube-system get daemonsets -o name)
if printf '%s' "$cni" | grep -Eq 'calico|cilium|antrea'; then
  apply 13-kubernetes-troubleshooting/issues/networkpolicy.yaml
  sleep 5
  run k -n "$NS" exec client -- nslookup "troubleshooting-service.$NS.svc.cluster.local."
  expected_failure k -n "$NS" exec client -- wget -qO- -T 5 http://troubleshooting-service
  run k -n "$NS" delete -f "$ROOT/13-kubernetes-troubleshooting/issues/networkpolicy.yaml"
  sleep 3
  http http://troubleshooting-service
else
  log 'SKIPPED enforced NetworkPolicy failure: no known policy-enforcing CNI detected. Plain Pod-to-Service networking was verified above.'
fi
observe
log "Final HPA cooldown observation: assert return to one replica after stabilization"
NS=hw-runtime-storage
wait_text hpa/cpu-demo '{.status.currentReplicas}' '^1$' 150
wait_text deployment/cpu-demo '{.status.readyReplicas}' '^1$'
run k -n hw-runtime-storage get hpa,pods
optional k -n hw-runtime-storage top pods
for ns in $NAMESPACES; do k -n "$ns" get all -o wide > "$OUT/$ns-final.txt" 2>&1; done
log "COMPLETED: $FAIL required command/state checks failed. Optional/environment-dependent outputs must be reviewed separately."
printf 'Run: %s\nRequired failures: %s\nContext: %s\nNamespaces: %s\n' "$STAMP" "$FAIL" "$PROFILE" "$NAMESPACES" > "$OUT/summary.txt"
[ "$FAIL" -eq 0 ]
