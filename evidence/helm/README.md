# Helm runtime evidence

Executed 7 October 2026 on local Minikube `devops-homework`, Kubernetes v1.34.0.
Student: Aryan Jakhar, 24BCS10305.

The reproducible runner is [run-helm-evidence.sh](../../scripts/run-helm-evidence.sh).
It verifies ready replica counts, ConfigMap values and actual HTTP responses at
each healthy stage, then asserts release revisions and rollback history.

| Stage | Observed result | Evidence |
| --- | --- | --- |
| Install (revision 1) | One ready replica, development environment | [Pods](20261007T150849Z/install-pods.txt), [HTTP](20261007T150849Z/install-http.html) |
| Upgrade (revision 2) | Three ready replicas, production environment | [Pods](20261007T150849Z/upgrade-pods.txt), [HTTP](20261007T150849Z/upgrade-http.html) |
| Broken upgrade (revision 3) | Invalid image causes ErrImagePull; old replicas remain healthy | [Pods](20261007T150849Z/broken-pods.txt), [events](20261007T150849Z/broken-describe.txt) |
| Rollback (revision 4) | Restores revision 2, three ready replicas and production HTTP page | [History](20261007T150849Z/history-after.json), [Pods](20261007T150849Z/rollback-pods.txt), [HTTP](20261007T150849Z/rollback-http.html) |

[Complete execution transcript](20261007T150849Z/transcript.txt) ·
[Runner PASS result](20261007T150849Z/result.txt) ·
[Rendered actual rollback output](20261007T150849Z/rollback-output.png) ·
[Live production page screenshot](20261007T150849Z/notes-browser.png) ·
[Successful release uninstall](20261007T150849Z/uninstall.txt).

[Chart scaffold and repository commands](commands/create-repo-search.txt)
record `helm create`, linting the generated chart, adding/updating/listing a
chart repository and searching its nginx charts. The temporary repository was
removed afterward. Deployment, manifest and effective-values YAML files in
the run directory preserve the exact chart resources at each stage.
