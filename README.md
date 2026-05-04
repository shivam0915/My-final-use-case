# 🚀 Docker + EC2 Monitoring with AWS CloudWatch

This project provides a **custom monitoring bridge** between Docker containers running on an EC2 instance and **AWS CloudWatch**.  
It enables collection of **host-level metrics** (CPU, memory, disk) via the CloudWatch Agent and **container-level metrics** (CPU, memory) via a custom Bash script.

---

## 📌 Features
- Collect **EC2 host metrics** (CPU, memory, disk usage) using CloudWatch Agent.
- Collect **Docker container metrics** (CPU, memory utilization) using `docker stats`.
- Push container metrics to CloudWatch under a **custom namespace** (`Final-USE-CASE`).
- Automate metric collection with **cron jobs**.
- Visualize metrics in CloudWatch dashboards and configure alarms.

---

## ⚙️ Prerequisites
- AWS EC2 instance (Amazon Linux/Ubuntu recommended)
- IAM Role/Instance Profile with **CloudWatchAgentServerPolicy**
- Installed tools:
  - Docker
  - AWS CLI (configured with proper permissions)
  - CloudWatch Agent

---

## 🧩 Architecture Overview

![EC2 & Docker Monitoring with AWS CloudWatch](https://copilot.microsoft.com/th/id/BCO.441029a0-5c2e-471d-b532-30fd03885e31.png)

**Flow Summary:**
1. EC2 instance runs Docker containers.
2. CloudWatch Agent collects host-level metrics.
3. Custom Bash script (`docker_metrics.sh`) fetches container stats.
4. Metrics are pushed to AWS CloudWatch under a custom namespace.
5. CloudWatch dashboards and alarms visualize and alert on performance.

---

## 🚀 Setup Instructions

### 1. Launch EC2 Instance
- Create an EC2 instance in your AWS account.
- Attach IAM role with `CloudWatchAgentServerPolicy`.

### 2. Install Docker
```bash
sudo yum install -y docker
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker ec2-user
newgrp docker

Run a test container:
docker run -d nginx
docker ps



3. Install CloudWatch Agent
sudo yum install -y amazon-cloudwatch-agent



4. Configure CloudWatch Agent
Create /opt/aws/amazon-cloudwatch-agent/bin/config.json:
{
  "metrics": {
    "namespace": "Final-USE-CASE",
    "metrics_collected": {
      "cpu": {
        "measurement": ["cpu_usage_idle", "cpu_usage_user"],
        "metrics_collection_interval": 60
      },
      "mem": {
        "measurement": ["mem_used_percent"],
        "metrics_collection_interval": 60
      },
      "disk": {
        "measurement": ["used_percent"],
        "resources": ["*"],
        "metrics_collection_interval": 60
      }
    }
  }
}

Start the agent:
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json -s


Verify status:
sudo systemctl status amazon-cloudwatch-agent




Docker Container Metrics Script
Create docker_metrics.sh:
#!/bin/bash

CONTAINER_IDS=$(docker ps -q)

for id in $CONTAINER_IDS
do
  CPU=$(docker stats --no-stream --format "{{.CPUPerc}}" $id | tr -d "%")
  MEM=$(docker stats --no-stream --format "{{.MemPerc}}" $id | tr -d "%")

 if [[ ! -z "$CPU" ]] && [[ ! -z "$MEM" ]];  then
    aws cloudwatch put-metric-data --namespace "Final-USE-CASE" \
      --metric-name "DockerCPUUtilization" --value $CPU --dimensions CONTAINER_ID=$id

    aws cloudwatch put-metric-data --namespace "Final-USE-CASE" \
      --metric-name "DockerMEMUtilization" --value $MEM --dimensions CONTAINER_ID=$id

    echo "Metrics pushed for $id: CPU=$CPU, MEM=$MEM"
  else
    echo "Error: Could not retrieve stats for $id"
  fi
done


Make executable:
chmod +x docker_metrics.sh


Run manually:
./docker_metrics.sh

Automate with Cron
Install cron:
sudo yum install -y cronie

Edit crontab:
crontab -e

Add entry to run every minute:
* * * * * /home/ec2-user/docker_metrics.sh

Some validatios steps:
1. Check crond is start and enable
if not:
systemctl start crond
systemctl enable crond
systemctl status crond

sudo journalctl -u crond -f

## 📊 Metrics in CloudWatch

CloudWatch will display both **host-level** and **container-level** metrics once the agent and script are running correctly.

### 1. Host Metrics (namespace: `CWAgent`)
- **CPU**:  
  - `cpu_usage_idle`  
  - `cpu_usage_user`
- **Memory**:  
  - `mem_used_percent`
- **Disk**:  
  - `disk_used_percent` (reported per partition with dimensions like `device`, `fstype`, `path`, `host`)

### 2. Docker Container Metrics (namespace: `Final-USE-CASE`)
- **CPU Utilization**:  
  - `DockerCPUUtilization` (dimension: `CONTAINER_ID`)
- **Memory Utilization**:  
  - `DockerMEMUtilization` (dimension: `CONTAINER_ID`)




🔔 Alarms & Dashboards
- Create CloudWatch alarms for thresholds (e.g., CPU > 80%, Memory > 75%).
- Build dashboards to visualize EC2 + Docker metrics together.
- Example widgets:
- EC2 CPU & Memory utilization
- Docker container CPU & Memory utilization
- Disk usage per partition

## 🧪 Validation Checklist

Use this checklist to confirm that your monitoring pipeline is working end-to-end:

1. **Run the metrics script**
   - Command: `./docker_metrics.sh`
   - Expected: Output shows metrics pushed for each container (CPU and MEM values).

2. **Verify metrics in CloudWatch**
   - Navigate: **CloudWatch → Metrics → Final-USE-CASE**
   - Expected: Container IDs appear as dimensions with CPU and MEM metrics.


Stress test examples:
docker exec -d <container_id> sh -c "yes > /dev/null"
Here for memroy:
first check linux dirstro.
then: apt-get update
apt-get install -y stress-ng

docker exec -it <container_id> 
docker exec -d <container_id> stress-ng --vm 1 --vm-bytes 500M --timeout 600s




Notes
- This script bridges the gap between Docker and CloudWatch, since the agent does not natively monitor containers.
- Ensure AWS CLI is configured with correct region (aws configure).
- Namespace and dimension names must match when creating alarms.

✅ Conclusion
This project delivers a complete monitoring pipeline for EC2 + Docker workloads using AWS CloudWatch.
It combines CloudWatch Agent for host metrics and a custom script for container metrics, ensuring full visibility into infrastructure and application performance.


