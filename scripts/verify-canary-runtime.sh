#!/usr/bin/env bash
# Rerun canary sampling after all ten endpoints have propagated.
set -euo pipefail
cd "$(dirname "$0")/.."
OUT=evidence/kubernetes/canary-$(date -u +%Y%m%dT%H%M%SZ)
mkdir -p "$OUT"
exec > >(tee "$OUT/transcript.log") 2>&1
k() { kubectl --context=devops-homework -n hw-runtime-canary "$@"; }
date -u
kubectl --context=devops-homework create namespace hw-runtime-canary
kubectl --context=devops-homework label namespace hw-runtime-canary homework-runner=kubernetes-repairs
k apply -f 09-kubernetes-workloads/canary/
k rollout status deployment/stable --timeout=240s
k rollout status deployment/canary --timeout=240s
k run client --image=busybox:1.37 --restart=Never -- sleep 3600
k wait --for=condition=Ready pod/client --timeout=180s
for attempt in $(seq 1 30); do
 count=$(k get endpoints canary-route -o jsonpath='{.subsets[0].addresses[*].ip}' | wc -w | tr -d ' ')
 echo "Ready endpoints: $count"
 [ "$count" = 10 ] && break
 sleep 3
done
[ "$count" = 10 ]
sleep 3
k get pods -o wide
k get endpointslices
k exec client -- sh -c 'for i in $(seq 1 100); do wget -qO- -T 5 http://canary-route; done' | tee "$OUT/responses.txt"
grep -qx stable "$OUT/responses.txt"
grep -qx canary "$OUT/responses.txt"
sort "$OUT/responses.txt" | uniq -c
printf 'PASS: both stable and canary served from ten ready endpoints at %s\n' "$(date -u +%FT%TZ)" | tee "$OUT/result.txt"
