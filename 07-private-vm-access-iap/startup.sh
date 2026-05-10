#!/bin/bash
set -euo pipefail

apt-get update -y
apt-get install -y nginx

cat > /var/www/html/index.html <<EOF
<!doctype html>
<html>
  <head>
    <title>Terraform IAP Private VM Lab</title>
  </head>
  <body>
    <h1>Hello from Terraform IAP Lab</h1>
    <p>This private VM was created by Terraform.</p>
    <p>It has no external IP and should be accessed through IAP.</p>
  </body>
</html>
EOF

systemctl enable nginx
systemctl restart nginx