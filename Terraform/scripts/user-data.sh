#!/bin/bash

# User data script for EC2 instance
# This script will be executed when the instance starts

# Update system packages
yum update -y

# Install web server and other utilities
yum install -y httpd php php-pgsql git

# Start and enable Apache
systemctl start httpd
systemctl enable httpd

# Create a simple health check page
cat > /var/www/html/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Acqua Infrastructure</title>
</head>
<body>
    <h1>Welcome to Acqua Infrastructure!</h1>
    <p>This is a production-ready Terraform infrastructure.</p>
    <p>Environment: ${environment}</p>
    <p>Instance ID: $(curl -s http://169.254.169.254/latest/meta-data/instance-id)</p>
</body>
</html>
EOF

# Set proper permissions
chown apache:apache /var/www/html/index.html

# Create a health check endpoint
cat > /var/www/html/health.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Health Check</title>
</head>
<body>
    <h1>Healthy</h1>
</body>
</html>
EOF

# Mount the additional EBS volume if it exists
if [ -b /dev/xvdb ]; then
    mkfs -t xfs /dev/xvdb
    mkdir -p /data
    mount /dev/xvdb /data
    echo "/dev/xvdb /data xfs defaults,nofail 0 2" >> /etc/fstab
fi

echo "User data script completed successfully!" 