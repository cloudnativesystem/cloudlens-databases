#!/bin/bash
# User data script for EC2 bastion host
# This script runs on first boot to configure the instance

set -e

# Update system packages
echo "Updating system packages..."
dnf update -y

# Install essential packages
echo "Installing essential packages..."
dnf install -y \
  postgresql15 \
  mysql \
  telnet \
  nc \
  vim \
  htop \
  jq \
  git \
  wget \
  curl \
  unzip

# Set hostname
%{ if hostname != "" }
echo "Setting hostname to ${hostname}..."
hostnamectl set-hostname ${hostname}
echo "127.0.0.1 ${hostname}" >> /etc/hosts
%{ endif }

# Install and configure CloudWatch Agent if enabled
%{ if cloudwatch_agent_enabled }
echo "Installing CloudWatch Agent..."
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm
rm -f ./amazon-cloudwatch-agent.rpm

# Create CloudWatch Agent configuration
cat > /opt/aws/amazon-cloudwatch-agent/etc/config.json <<'EOF'
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "cwagent"
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/messages",
            "log_group_name": "/aws/ec2/${hostname}",
            "log_stream_name": "{instance_id}/messages",
            "retention_in_days": 7
          },
          {
            "file_path": "/var/log/secure",
            "log_group_name": "/aws/ec2/${hostname}",
            "log_stream_name": "{instance_id}/secure",
            "retention_in_days": 7
          }
        ]
      }
    }
  },
  "metrics": {
    "namespace": "CWAgent",
    "metrics_collected": {
      "cpu": {
        "measurement": [
          {
            "name": "cpu_usage_idle",
            "rename": "CPU_IDLE",
            "unit": "Percent"
          },
          {
            "name": "cpu_usage_iowait",
            "rename": "CPU_IOWAIT",
            "unit": "Percent"
          }
        ],
        "metrics_collection_interval": 60,
        "totalcpu": false
      },
      "disk": {
        "measurement": [
          {
            "name": "used_percent",
            "rename": "DISK_USED",
            "unit": "Percent"
          }
        ],
        "metrics_collection_interval": 60,
        "resources": [
          "*"
        ]
      },
      "diskio": {
        "measurement": [
          {
            "name": "io_time"
          }
        ],
        "metrics_collection_interval": 60,
        "resources": [
          "*"
        ]
      },
      "mem": {
        "measurement": [
          {
            "name": "mem_used_percent",
            "rename": "MEM_USED",
            "unit": "Percent"
          }
        ],
        "metrics_collection_interval": 60
      },
      "netstat": {
        "measurement": [
          {
            "name": "tcp_established",
            "rename": "TCP_ESTABLISHED",
            "unit": "Count"
          }
        ],
        "metrics_collection_interval": 60
      }
    }
  }
}
EOF

# Start CloudWatch Agent
echo "Starting CloudWatch Agent..."
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -s \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/config.json
%{ endif }

# Configure SSH
echo "Configuring SSH..."
sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart sshd

# Create a welcome message
cat > /etc/motd <<'EOF'
================================================================================
  CloudLens Bastion Host
================================================================================
  
  This is a bastion host for accessing CloudLens database infrastructure.
  
  Available tools:
  - PostgreSQL client (psql)
  - MySQL client (mysql)
  - Network tools (telnet, nc)
  - AWS CLI
  - SSM Session Manager
  
  To connect to RDS:
  1. Retrieve database credentials from Secrets Manager
  2. Use psql or mysql client to connect
  
  For support, contact the CloudLens platform team.
  
================================================================================
EOF

# Install AWS CLI v2 if not already installed
if ! command -v aws &> /dev/null; then
  echo "Installing AWS CLI v2..."
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip awscliv2.zip
  ./aws/install
  rm -rf aws awscliv2.zip
fi

# Configure automatic security updates
echo "Configuring automatic security updates..."
dnf install -y dnf-automatic
sed -i 's/apply_updates = no/apply_updates = yes/' /etc/dnf/automatic.conf
systemctl enable --now dnf-automatic.timer

# Set timezone to UTC
timedatectl set-timezone UTC

# Enable and start SSM agent (should already be running on AL2023)
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

echo "Bastion host initialization complete!"

