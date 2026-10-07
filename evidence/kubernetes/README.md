# Kubernetes runtime evidence

Student: Aryan Jakhar, 24BCS10305. Executed 7 October 2026 with Minikube v1.39.0,
Kubernetes v1.34.0 and Calico. Hosted labs used the GitHub Actions Linux runner;
targeted repairs and browser capture used the local Docker/Colima cluster.

## Hosted execution and recovery

[Workflow run 37641399108](https://github.com/AJ5831A/devops-homework/actions/runs/37641399108)
completed with **six required checks failing** in the Kubernetes runner and
Helm passing. The original [summary](20261007T150232Z/summary.txt) and
[complete transcript](20261007T150232Z/transcript.log) are retained unchanged.
This is not presented as a green workflow run.

Two failures came from trying to remove the liveness fixture's health file
before its intentional ten-second startup delay had elapsed, then waiting for
a restart that never happened. Four failures came from BusyBox `nslookup`
returning nonzero for extra DNS search-suffix queries despite finding the
intended short service name. The corrected runner waits for the health file
and uses absolute service DNS names ending in a dot.

The first canary sample returned only canary responses likely because sampling started
before all endpoints had propagated; the hosted run did not record endpoint
timing to prove that cause. A separate local rerun waited for all ten
ready endpoints and recorded **90 stable / 10 canary** responses in 100 requests:
[transcript](canary-20261007T151826Z/transcript.log),
[raw responses](canary-20261007T151826Z/responses.txt),
[PASS result](canary-20261007T151826Z/result.txt),
[rendered sample counts](canary-20261007T151826Z/canary-counts.png). This is a measured sample,
not a guaranteed percentage. The corrected runner asserts both variants.

Targeted local recovery is recorded in
[repairs-20261007T151715Z/transcript.log](repairs-20261007T151715Z/transcript.log).
It reproduces the liveness restart, DNS break/repair, network-policy denial
with working DNS, and HPA scale-up/cooldown. Its [PASS result](repairs-20261007T151715Z/result.txt) records all recovery
checks passing at 15:29:02 UTC. HPA reached five ready replicas and then
returned to one, with `All metrics below target` in the downscale event.
See [scale-up](repairs-20261007T151715Z/hpa-scale-up.png) and
[cooldown](repairs-20261007T151715Z/hpa-cooldown.png) screenshots. These successful
targeted checks complement the retained failed hosted run; they do not rewrite
its conclusion.

## Requirement evidence

| Assignment | Actual evidence |
| --- | --- |
| 08: Fundamentals | [Cluster setup](local-setup/), [live Hello page](local-setup/hello-browser.png), [HTTP response](local-setup/hello-http.txt), [scale/image-update transcript rendering](20261007T150232Z/fundamentals.png) |
| 09: Workloads | [Rolling and blue/green](20261007T150232Z/strategies.png), [rolling watch](20261007T150232Z/rolling-watch.log), [Recreate watch](20261007T150232Z/recreate-watch.log), [termination trap log](20261007T150232Z/termination.log), canary rerun and lifecycle states in transcripts |
| 10: Services | [LoadBalancer host HTTP success](20261007T150232Z/loadbalancer.png), [tunnel output](20261007T150232Z/loadbalancer-tunnel.log), [NodePort host URL](20261007T150232Z/nodeport-url.log), ClusterIP/headless/DNS in transcripts |
| 11: Configuration and Ingress | [Environment injection, valid/unknown host routing](20261007T150232Z/config-ingress.png); missing Secret reference and repair in transcript |
| 12: Storage, probes and HPA | [PVC persistence](20261007T150232Z/storage-persistence.png), emptyDir reset, static PV, readiness failure/repair and HPA samples in transcripts |
| 13: Troubleshooting | Crash/image/scheduling/configuration faults and fixes in transcript; [Calico denial then HTTP recovery](20261007T150232Z/networkpolicy.png); repaired DNS and policy checks in local rerun |

LoadBalancer access was genuinely tested from the hosted runner through
`minikube tunnel`: address `10.107.131.130` returned the expected HTTP body.
The optional label in the original runner does not conceal a skipped check:
that command exited zero. ExternalName's DNS alias resolved correctly, but
`example.com` rejected HTTP with 403; the transcript preserves that outcome.

The hosted HPA first showed unknown metrics, then reached five **ready** CPU
replicas. Its final snapshot still had five replicas, so it does not prove
completed downscaling. The targeted local run explicitly waits for increased
current/ready replicas and a return to one after stabilization. The separate
nginx storage application remained at its minimum two replicas under its load.

Screenshots of terminal output are explicitly labeled renderings of recorded
transcripts, with source and line ranges. `hello-browser.png` is a screenshot
of the live application, not a transcript rendering. Screenshots supplement
the original text and do not replace it.

## Reproduction

- [Full Kubernetes runner](../../scripts/run-kubernetes-evidence.sh)
- [Targeted recovery runner](../../scripts/verify-kubernetes-repairs.sh)
- [Canary endpoint/readiness check](../../scripts/verify-canary-runtime.sh)

The repair scripts create dedicated namespaces and refuse a conflicting
existing namespace through `kubectl create`; they do not reset arbitrary
existing workloads. Cleanup removes only the dedicated lab namespaces after
evidence capture. Hosted clusters disappear with their disposable runner.
