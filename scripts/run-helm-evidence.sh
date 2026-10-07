#!/usr/bin/env bash
# Record a real Notes release lifecycle in the homework cluster.
set -euo pipefail
REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
HELM_BIN=${HELM_BIN:-helm}
if ! command -v "$HELM_BIN" >/dev/null 2>&1 && [[ -x /private/tmp/devops-bin/helm ]]; then
  HELM_BIN=/private/tmp/devops-bin/helm
fi
KUBE_CONTEXT=${KUBE_CONTEXT:-devops-homework}
NAMESPACE=hw-runtime-helm
RELEASE=notes-evidence
CHART="$REPO_ROOT/14-helm/notes-chart"
STAMP=$(date -u +%Y%m%dT%H%M%SZ)
EVIDENCE_DIR="$REPO_ROOT/evidence/helm/$STAMP"
mkdir -p "$EVIDENCE_DIR"
exec > >(tee "$EVIDENCE_DIR/transcript.txt") 2>&1
printf 'Started: %s\nContext: %s\nNamespace: %s\n' "$STAMP" "$KUBE_CONTEXT" "$NAMESPACE"
"$HELM_BIN" version --short
kubectl --context "$KUBE_CONTEXT" cluster-info
h() { "$HELM_BIN" "$@" --kube-context "$KUBE_CONTEXT" --namespace "$NAMESPACE"; }
k() { kubectl --context "$KUBE_CONTEXT" --namespace "$NAMESPACE" "$@"; }
# A fresh release keeps revision assertions deterministic; never remove an existing one.
if h status "$RELEASE" >/dev/null 2>&1; then
  echo 'Release already exists. Inspect it and remove it deliberately before re-running this fresh-install exercise.'
  exit 1
fi
PF_PID=''
cleanup_port_forward() {
  if [[ -n "$PF_PID" ]]; then
    kill "$PF_PID" 2>/dev/null || true
    wait "$PF_PID" 2>/dev/null || true
    PF_PID=''
  fi
}
trap cleanup_port_forward EXIT
verify_release() {
  local stage=$1 expected_environment=$2 expected_replicas=$3
  k rollout status deployment/"$RELEASE"-deploy --timeout=180s
  k get pods,deployments,services,configmaps -o wide
  actual_replicas=$(k get deployment "$RELEASE"-deploy -o jsonpath='{.status.readyReplicas}')
  [[ "$actual_replicas" == "$expected_replicas" ]]
  actual_environment=$(k get configmap "$RELEASE"-config -o jsonpath='{.data.ENVIRONMENT}')
  [[ "$actual_environment" == "$expected_environment" ]]
  h get values "$RELEASE" --all > "$EVIDENCE_DIR/$stage-values.yaml"
  k get deployment "$RELEASE"-deploy -o yaml > "$EVIDENCE_DIR/$stage-deployment.yaml"
  k get pods -o wide > "$EVIDENCE_DIR/$stage-pods.txt"
  # Let kubectl select a free local port, then discover it from its actual output.
  k port-forward svc/"$RELEASE"-svc :80 > "$EVIDENCE_DIR/$stage-port-forward.txt" 2>&1 &
  PF_PID=$!
  local port=''
  for attempt in $(seq 1 30); do
    port=$(sed -n 's/.*127\.0\.0\.1:\([0-9]*\) -> 80.*/\1/p' "$EVIDENCE_DIR/$stage-port-forward.txt" | head -n 1)
    [[ -n "$port" ]] && break
    kill -0 "$PF_PID" 2>/dev/null || { cat "$EVIDENCE_DIR/$stage-port-forward.txt"; return 1; }
    sleep 1
  done
  [[ -n "$port" ]]
  curl --fail --silent --show-error "http://127.0.0.1:$port" > "$EVIDENCE_DIR/$stage-http.html"
  grep -F "Environment: $expected_environment" "$EVIDENCE_DIR/$stage-http.html"
  cleanup_port_forward
  echo "Verified $stage: $expected_replicas ready replicas, $expected_environment ConfigMap and HTTP page."
}

h install "$RELEASE" "$CHART" --create-namespace --wait --timeout 180s
verify_release install development 1
h list
h status "$RELEASE"
h get manifest "$RELEASE" > "$EVIDENCE_DIR/install-manifest.yaml"

h upgrade "$RELEASE" "$CHART" -f "$CHART/values-prod.yaml" --wait --timeout 180s
verify_release upgrade production 3
h history "$RELEASE" -o json > "$EVIDENCE_DIR/history-before.json"

# Revision 3 intentionally uses an invalid image; do not use --wait or automatic rollback.
h upgrade "$RELEASE" "$CHART" -f "$CHART/values-prod.yaml" --set image.tag=broken-tag-does-not-exist
found_image_failure=false
for attempt in $(seq 1 60); do
  reasons=$(k get pods -l "app.kubernetes.io/instance=$RELEASE" -o jsonpath='{range .items[*]}{range .status.containerStatuses[*]}{.state.waiting.reason}{"\n"}{end}{end}')
  if printf '%s\n' "$reasons" | grep -Eq 'ImagePullBackOff|ErrImagePull'; then
    found_image_failure=true
    break
  fi
  sleep 2
 done
k get pods -o wide > "$EVIDENCE_DIR/broken-pods.txt"
k describe pods -l "app.kubernetes.io/instance=$RELEASE" > "$EVIDENCE_DIR/broken-describe.txt"
h history "$RELEASE" -o json > "$EVIDENCE_DIR/history-broken.json"
[[ "$found_image_failure" == true ]] || { echo 'Timed out without observing an image-pull failure.'; exit 1; }
cat "$EVIDENCE_DIR/broken-pods.txt"

h rollback "$RELEASE" 2 --wait --timeout 180s
verify_release rollback production 3
h history "$RELEASE" -o json > "$EVIDENCE_DIR/history-after.json"
python3 - "$EVIDENCE_DIR" <<'PY'
import json, pathlib, sys
p = pathlib.Path(sys.argv[1])
before = json.loads((p/'history-before.json').read_text())
broken = json.loads((p/'history-broken.json').read_text())
after = json.loads((p/'history-after.json').read_text())
assert [x['revision'] for x in before] == [1, 2], before
assert [x['revision'] for x in broken] == [1, 2, 3], broken
assert [x['revision'] for x in after] == [1, 2, 3, 4], after
assert after[-1]['status'] == 'deployed', after
assert 'Rollback to 2' in after[-1]['description'], after
print('Verified revisions 1→2→3→4; revision 4 restores revision 2.')
PY
h history "$RELEASE"
if [[ "${CLEANUP:-0}" == 1 ]]; then
  h uninstall "$RELEASE" --wait --timeout 120s
  k get deployment,service,configmap -o wide > "$EVIDENCE_DIR/cleanup.txt"
  # Leave the namespace itself intact: only resources owned by this release are removed.
fi
printf 'PASS: Helm install, production upgrade, broken revision and rollback verified at %s\n' "$(date -u +%FT%TZ)" | tee "$EVIDENCE_DIR/result.txt"
printf 'Evidence: %s\n' "$EVIDENCE_DIR"
