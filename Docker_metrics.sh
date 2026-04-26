#!/bin/bash
CONTAINER_IDS=$(docker ps -q)
for id in $CONTAINER_IDS
do
  CPU=$(docker stats --no-stream --format "{{.CPUPerc}}" $id | tr -d '%')
  MEM=$(docker stats --no-stream --format "{{.MemPerc}}" $id | tr -d '%')
  if [ ! -z "$CPU" ]; then
    # Changed dimension name to 'host' to match your alarm configuration
    aws cloudwatch put-metric-data --namespace "Docker-Container" --metric-name "DockerCPUUtilization" --value $CPU --dimensions CONTAINER_ID=$id
    aws cloudwatch put-metric-data --namespace "Docker-Container" --metric-name "DockerMEMUtilization" --value $MEM --dimensions CONTAINER_ID=$id
    echo "Pushed to CloudWatch -> host=$id CPU=$CPU% MEM=$MEM"
  fi
done
