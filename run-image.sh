#!/bin/bash

# Specify the container version tag. Versions available:
CONTAINER_VERSION=latest

# Launch the Splunk container based on MapR PACC
docker run -it \
--cap-add SYS_ADMIN \
--cap-add SYS_RESOURCE \
--device /dev/fuse \
-e MAPR_CLUSTER=demo.mapr.com \
-e MAPR_CLDB_HOSTS=192.168.1.11 \
-e MAPR_CONTAINER_USER=mapr \
-e MAPR_CONTAINER_GROUP=mapr \
-e MAPR_CONTAINER_UID=5000 \
-e MAPR_CONTAINER_GID=5000 \
-e MAPR_MOUNT_PATH=/mapr \
-e MAPR_YARN_RM_NODE=192.168.1.11 \
-e MAPR_CLDB_HOST=192.168.1.11 \
-p 8000:8000 \
mkieboom/mapr-pacc-splunk-docker:$CONTAINER_VERSION

# For secure clusters, genarate a ticket and provide the ticket to docker run:
# -v /tmp/mapr-ticket:/tmp/longlived_ticket:ro \
# -e MAPR_TICKETFILE_LOCATION=/tmp/longlived_ticket \
