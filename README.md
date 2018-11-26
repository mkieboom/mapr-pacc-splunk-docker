# mapr-pacc-splunk-docker

## Disclaimer
Not for production use and not officially supported by MapR Technologies.

## Introduction
MapR Persistent Application Client Container (PACC) running Splunk Enterprise. This pre-build container running Splunk Enterprise allows you to offload and import data to/from a MapR cluster immediately.

## Pre-requisites
A MapR cluster (v6.1.0 or later) and Docker (v18.x or later).

### Clone the project
```
git clone https://github.com/mkieboom/mapr-pacc-splunk-docker
cd mapr-pacc-splunk-docker
```

## Running the container
Modify the 'run-image.sh' script to reflect your MapR cluster configuration.
```
vi run-image.sh
bash run-image.sh
```

## Open Splunk Enterprise UI
Open the Splunk Enterprise UI and login:
```
url: http://localhost:8000

Login details (unless changed in Dockerfile by changing SPLUNK_ADMIN_PASSWORD)
username: admin
Password: adminadmin
```

## Build the container
For customization, modify the Dockerfile and shell scripts to your needs and build the container:
```
vi build-image.sh
bash build-image.sh
```
