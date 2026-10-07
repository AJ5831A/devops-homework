#!/bin/bash
set -euxo pipefail
dnf install -y nginx
cat > /usr/share/nginx/html/index.html <<'HTML'
<!doctype html><html><head><title>DevOps Cloud Lab</title></head>
<body><h1>Hello from Terraform on AWS</h1><p>AJ5831A DevOps homework</p></body></html>
HTML
systemctl enable --now nginx
