# Monitoring execution evidence

Run: 7 October 2026, 15:05–15:09 UTC (20:35–20:39 IST). Owner: Aryan Jakhar, 24BCS10305.

The actual stack ran in Docker on the dedicated Colima `devops-homework` VM.
The application bound to `127.0.0.1:18089`, Prometheus to port 9090 and Grafana
to port 3000. Credentials came from a private temporary environment file and
are excluded from this repository. Screenshots were captured from the live
browser with Playwright and Chrome; they are not mockups.

| Evidence | Observed result |
| --- | --- |
| [Health response](health.json) | Application returned healthy |
| [Prometheus targets API](prometheus-targets.json), [screenshot](targets.png) | `devops-demo` target UP |
| [Application metrics](metrics.txt) | Request counter 16,609; CPU counter and peak memory exposed |
| [Docker statistics](docker-stats.txt) | App 357.42% CPU, 12.11 MiB current container memory during load |
| [Grafana dashboard](grafana-dashboard.png) | Health, CPU, peak resident memory and request-rate graphs populated |
| [Structured request logs](application-logs.txt) | Request ID, path, status and duration recorded |
| [High CPU alert history](high-cpu-alert-history.json) | `DemoHighCPU` reached firing during the load interval |
| [Down alert JSON](alert-firing.json), [screenshot](alert-firing.png) | `DemoApplicationDown` reached firing after app stopped |
| [Recovery JSON](alert-recovered.json), [screenshot](alert-recovered.png) | Active alerts empty after app restarted |
| [Final stack status](run-summary.txt) | Application, Prometheus and Grafana running after recovery |

## Procedure used

From the repository root:

```bash
# The private env file supplied API_TOKEN, GRAFANA_PASSWORD and APP_PORT=18089.
docker compose --env-file /private/tmp/devops-monitoring.env \
  -f 19-monitoring-gitops/compose.yaml up -d --build
curl -fsS http://localhost:18089/healthz
curl -fsS http://localhost:18089/metrics
curl -fsS http://localhost:9090/api/v1/targets
```

Four concurrent request loops called `/work?rounds=100000` for approximately
95 seconds. During load, `docker stats --no-stream` and `/metrics` were saved,
and the authenticated provisioned Grafana dashboard was captured. Peak
resident memory is a process high-water mark; Docker's container memory is a
different measurement and need not match it.

```bash
docker compose --env-file /private/tmp/devops-monitoring.env \
  -f 19-monitoring-gitops/compose.yaml logs --tail=30 app
docker compose --env-file /private/tmp/devops-monitoring.env \
  -f 19-monitoring-gitops/compose.yaml stop app
# Poll /api/v1/alerts until DemoApplicationDown has state=firing.
curl -fsS http://localhost:9090/api/v1/alerts
docker compose --env-file /private/tmp/devops-monitoring.env \
  -f 19-monitoring-gitops/compose.yaml start app
# Poll until DemoApplicationDown is absent; capture recovered UI and API.
```

The high-CPU history used `/api/v1/query_range` with
`ALERTS{alertname="DemoHighCPU",alertstate="firing"}`, start
`2026-10-07T15:05:00Z`, end `2026-10-07T15:08:00Z`, step `5s`.
Recorded samples with value 1 prove this alert also fired. No external alert
receiver or distributed tracing backend was claimed or installed.
