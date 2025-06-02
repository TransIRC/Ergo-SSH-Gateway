#!/bin/bash

# Stop and remove existing container if any
sudo docker rm -f ergo-ssh-gateway || true

# Remove existing image if any
sudo docker rmi ergo-ssh-gateway || true

echo "Old containers and images removed."

# Build container
sudo docker build -t ergo-ssh-gateway .

# Run container
sudo docker run -d \
  -p 127.0.0.1:2225:2222 \
  --add-host=host.docker.internal:host-gateway \
  --name ergo-ssh-gateway \
  --tmpfs /mnt/sessions:rw,size=1m,uid=1000,gid=1000,mode=755 \
  ergo-ssh-gateway
