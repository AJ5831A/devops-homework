#!/usr/bin/env bash
# Uses only containers/networks prefixed hw-. Docker daemon must already be running.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p evidence/docker
exec > >(tee evidence/docker/runtime.log) 2>&1
set -x
date -u
docker version
for spec in nodejs-app:3000:18030 python-app:5000:18050 java-app:8000:18080 Apache-app:80:18081 React-app:80:18082 nginx-app:80:18083; do
  IFS=: read -r folder internal external <<< "$spec"
  name="hw-$(echo "$folder" | tr '[:upper:]' '[:lower:]')"
  docker build -t "$name:lab" "05-docker-fundamentals/$folder"
  docker rm -f "$name" 2>/dev/null || true
  docker run -d --name "$name" -p "127.0.0.1:$external:$internal" "$name:lab"
  curl --fail --retry 20 --retry-all-errors --retry-delay 2 "http://127.0.0.1:$external/" > "evidence/docker/$folder-response.html"
  cat "evidence/docker/$folder-response.html"
done
docker build -t hw-multistage:lab 06-docker-multistage
docker rm -f hw-multistage 2>/dev/null || true
docker run -d --name hw-multistage -p 127.0.0.1:8080:8080 hw-multistage:lab
curl --fail --retry 20 --retry-all-errors --retry-delay 2 http://127.0.0.1:8080 | tee evidence/docker/multistage-response.txt
docker ps --filter name=hw-
for n in hw-net1 hw-net2 hw-net3; do docker network inspect "$n" >/dev/null 2>&1 || docker network create "$n"; done
for c in hw-frontend hw-backend hw-database hw-bindmount hw-apache-host; do docker rm -f "$c" 2>/dev/null || true; done
docker run -d --name hw-frontend --network hw-net1 alpine:3.22 sleep 3600
docker run -d --name hw-backend --network hw-net1 alpine:3.22 sleep 3600
docker run -d --name hw-database --network hw-net3 -e MYSQL_ALLOW_EMPTY_PASSWORD=yes mysql:8
# Empty password is strictly confined to an unpublished disposable lab database.
docker network connect hw-net2 hw-backend
docker inspect hw-backend --format '{{json .NetworkSettings.Networks}}'
docker exec hw-frontend ping -c 2 hw-backend
if docker exec hw-frontend ping -c 2 -W 2 hw-database; then echo 'ERROR: expected isolated DNS failure'; exit 1; else echo 'Observed expected isolation'; fi
docker network connect hw-net3 hw-frontend
docker exec hw-frontend ping -c 2 hw-database
docker run -d --name hw-apache-host --network host httpd:2.4
# Host here is the Linux Colima VM, not macOS.
docker run --rm --network host curlimages/curl:8.12.1 --fail --retry 10 --retry-all-errors http://127.0.0.1:80
mkdir -p /private/tmp/devops-bindmount
printf '<h1>Hello students</h1>\n' > /private/tmp/devops-bindmount/index.html
docker run -d --name hw-bindmount -p 127.0.0.1:18090:80 -v /private/tmp/devops-bindmount:/usr/share/nginx/html:ro nginx:alpine
curl --fail --retry 10 --retry-all-errors http://127.0.0.1:18090
printf '<h1>Hello students - updated!</h1>\n' > /private/tmp/devops-bindmount/index.html
curl --fail http://127.0.0.1:18090
docker inspect hw-bindmount --format 'StartedAt={{.State.StartedAt}}'
docker ps --filter name=hw-
