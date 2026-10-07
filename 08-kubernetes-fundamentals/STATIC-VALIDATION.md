# Local validation — Kubernetes assignments 08–13

Validated on 2026-10-07 using Ruby's YAML parser and local structural checks.

```text
PASS: 57 YAML files, 63 resources; required metadata, workload selector/label alignment, container images, and volume mount references.
```

The checks parsed every YAML document and verified:

- Every resource has apiVersion, kind and metadata.name.
- Deployment and ReplicaSet selectors match their Pod template labels.
- Every application container specifies an image.
- Every container volumeMount references a declared Pod volume.

Broken fixtures intentionally retain runtime failures (missing images, configuration, unmatched node selectors or Service selectors) without making the YAML malformed. These checks do not validate against Kubernetes OpenAPI or prove cluster behavior. kubectl, Minikube and a running cluster were unavailable here; image pulls, scheduling, network routing, autoscaling and screenshots remain unverified. Each lab README provides commands and labels expected behavior separately from actual evidence.
