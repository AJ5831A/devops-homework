#!/bin/bash
set -euo pipefail
dnf install -y curl
TOKEN=$(curl --fail --retry 5 -X PUT -H 'X-aws-ec2-metadata-token-ttl-seconds: 21600' http://169.254.169.254/latest/api/token)
PUBLIC_IP=$(curl --fail -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/public-ipv4)
curl --fail --location --retry 5 -o /tmp/install-k3s.sh https://get.k3s.io
INSTALL_K3S_CHANNEL=stable sh /tmp/install-k3s.sh server --tls-san "$PUBLIC_IP" --write-kubeconfig-mode 600
