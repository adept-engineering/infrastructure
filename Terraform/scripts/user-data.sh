#!/bin/bash

# User data script for Ubuntu EC2 instance
# This script will be executed when the instance starts

# Update system packages
apt-get update
apt-get upgrade -y

# Install required packages
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    software-properties-common \
    unzip \
    wget \
    git

# Install Python 3.10+
add-apt-repository ppa:deadsnakes/ppa -y
apt-get update
apt-get install -y python3.10 python3.10-venv python3.10-dev python3-pip

# Set Python 3.10 as default
update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 1
update-alternatives --install /usr/bin/python python /usr/bin/python3.10 1

# Install Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io

# Start and enable Docker
systemctl start docker
systemctl enable docker

# Add ubuntu user to docker group
usermod -aG docker ubuntu

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Install Liquibase
wget https://github.com/liquibase/liquibase/releases/latest/download/liquibase-4.20.0.tar.gz
tar -xzf liquibase-4.20.0.tar.gz -C /opt/
ln -s /opt/liquibase-4.20.0/liquibase /usr/local/bin/liquibase

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
    <p>Python Version: $(python3 --version)</p>
    <p>Docker Version: $(docker --version)</p>
    <p>Docker Compose Version: $(docker-compose --version)</p>
    <p>Liquibase Version: $(liquibase --version | head -1)</p>
</body>
</html>
EOF

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
    # Check if the volume is already formatted
    if ! blkid /dev/xvdb; then
        # Format the volume with ext4 filesystem
        mkfs -t ext4 /dev/xvdb
    fi
    
    # Create mount point
    mkdir -p /data
    
    # Mount the volume
    mount /dev/xvdb /data
    
    # Add to fstab for persistence
    echo "/dev/xvdb /data ext4 defaults,nofail 0 2" >> /etc/fstab
    
    # Set proper permissions
    chown ubuntu:ubuntu /data
    chmod 755 /data
    
    echo "EBS volume mounted successfully at /data"
else
    echo "No additional EBS volume found at /dev/xvdb"
fi

echo "User data script completed successfully!" 