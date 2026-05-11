#!/bin/bash
set -euo pipefail

apt-get update -y
apt-get install -y nginx

HOSTNAME="$(hostname)"
LOCAL_IP="$(hostname -I | awk '{print $1}')"

cat > /var/www/html/index.html <<EOF
<!doctype html>
<html>
  <head>
    <title>Terraform MIG Load Balancer Lab</title>
  </head>
  <body>
    <h1>Hello from Terraform Lab 008</h1>
    <p>This page is served from a private VM inside a Managed Instance Group.</p>
    <p>Hostname: ${HOSTNAME}</p>
    <p>Internal IP: ${LOCAL_IP}</p>
  </body>
</html>
EOF

systemctl enable nginx
systemctl restart nginx