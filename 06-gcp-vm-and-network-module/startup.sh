#!/bin/bash
set -euo pipefail

apt-get update -y
apt-get install -y nginx

cat > /var/www/html/index.html <<EOF
<!doctype html>
<html>
  <head>
    <title>Terraform Module Output VM</title>
  </head>
  <body>
    <h1>Hello from Terraform</h1>
    <p>This VM was created using a subnet output from the network module.</p>
  </body>
</html>
EOF

systemctl enable nginx
systemctl restart nginx