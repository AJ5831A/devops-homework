#!/usr/bin/env bash
# Targeted real rerun of the failures and incomplete cooldown in hosted run37641399108.
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
OUT="$ROOT/evidence/kubernetes/repairs-$(date -u +%Y%m%dT%H%M%SZ)"
mkdir -p "$OUT"
exec > >(tee "$OUT/transcript.log") 2>&1
NS=hw-runtime-repairs
k() { kubectl --context=devops-homework --request-timeout=30s "$@"; }
kn() { k -n "$NS" "$@"; }
check() { printf '\n[%s] RUN: %s\n' "$(date -u +%FT%TZ)" "$*"; "$@"; echo 'PASS'; }
wait_value() {
 local resource=$1 path=$2 pattern=$3 tries=$4 value=''
 for ((i=0;i<tries;i++)); do
  value=$(kn get "$resource" -o "jsonpath=$path")
  printf '%s %s %s = %s\n' "$(date -u +%FT%TZ)" "$resource" "$path" "$value"
  if printf '%s' "$value" | grep -Eq "$pattern"; then return 0; fi
  sleep 5
 done
 echo "FAIL: timed out waiting for $resource $pattern"; return 1
}
check k create namespace "$NS"
check k label namespace "$NS" homework-runner=kubernetes-repairs
check kn apply -f "$ROOT/09-kubernetes-workloads/lifecycle/liveness.yaml"
check kn wait --for=condition=Ready pod/liveness --timeout=180s
# Ready without a readiness probe does not prove the delayed health file exists.
check kn exec liveness -- sh -c 'for n in $(seq 1 30); do test -f /tmp/healthy && exit 0; sleep 1; done; exit 1'
check kn exec liveness -- rm /tmp/healthy
check wait_value pod/liveness '{.status.containerStatuses[0].restartCount}' '^[1-9]' 30
check kn describe pod liveness
check kn delete pod liveness --wait=true
check kn apply -f "$ROOT/10-kubernetes-services/"
check kn rollout status deployment/web --timeout=180s
check kn run client --image=busybox:1.37 --restart=Never -- sleep 7200
check kn wait --for=condition=Ready pod/client --timeout=180s
check kn exec client -- nslookup "headless.$NS.svc.cluster.local."
check kn exec client -- nslookup "externalname.$NS.svc.cluster.local."
check kn apply -f "$ROOT/13-kubernetes-troubleshooting/mini-project/deployment.yaml"
check kn apply -f "$ROOT/13-kubernetes-troubleshooting/mini-project/service.yaml"
check kn rollout status deployment/troubleshooting-app --timeout=180s
check kn apply -f "$ROOT/13-kubernetes-troubleshooting/issues/dns.yaml"
check kn wait --for=condition=Ready pod/bad-dns --timeout=180s
if kn exec bad-dns -- nslookup -timeout=2 -retry=1 "troubleshooting-service.$NS.svc.cluster.local."; then echo 'FAIL: broken DNS succeeded'; exit 1; else echo 'PASS: broken DNS failed as expected'; fi
check kn delete pod bad-dns --wait=true
check kn run bad-dns --image=busybox:1.37 --restart=Never -- sleep 7200
check kn wait --for=condition=Ready pod/bad-dns --timeout=180s
check kn exec bad-dns -- nslookup "troubleshooting-service.$NS.svc.cluster.local."
check kn exec client -- wget -qO- -T 10 http://troubleshooting-service
check kn apply -f "$ROOT/13-kubernetes-troubleshooting/issues/networkpolicy.yaml"
sleep 5
check kn exec client -- nslookup "troubleshooting-service.$NS.svc.cluster.local."
if kn exec client -- wget -qO- -T 5 http://troubleshooting-service; then echo 'FAIL: deny policy did not block'; exit 1; else echo 'PASS: policy blocked HTTP while DNS succeeded'; fi
check kn delete -f "$ROOT/13-kubernetes-troubleshooting/issues/networkpolicy.yaml"
sleep 3
check kn exec client -- wget -qO- -T 10 http://troubleshooting-service
check k -n kube-system rollout status deployment/metrics-server --timeout=240s
check kn apply -f "$ROOT/12-kubernetes-storage/hpa/application.yaml"
check kn rollout status deployment/cpu-demo --timeout=240s
check kn apply -f "$ROOT/12-kubernetes-storage/hpa/hpa.yml"
check kn apply -f "$ROOT/12-kubernetes-storage/hpa/load-generator.yaml"
check wait_value hpa/cpu-demo '{.status.currentReplicas}' '^[2-5]$' 100
check wait_value deployment/cpu-demo '{.status.readyReplicas}' '^[2-5]$' 60
check kn get hpa,pods
check kn top pods
check kn describe hpa cpu-demo
check kn delete pod load-generator --wait=true
check wait_value hpa/cpu-demo '{.status.currentReplicas}' '^1$' 100
check wait_value deployment/cpu-demo '{.status.readyReplicas}' '^1$' 30
check kn get hpa,pods
check kn describe hpa cpu-demo
printf 'PASS: delayed liveness restart, four FQDN DNS checks, policy denial/recovery, HPA scale-up and full cooldown at %s\n' "$(date -u +%FT%TZ)" | tee "$OUT/result.txt"
