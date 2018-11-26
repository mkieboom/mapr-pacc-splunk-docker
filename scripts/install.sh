#!/bin/bash

# Configure Splunk
echo -e "\nOPTIMISTIC_ABOUT_FILE_LOCKING = 1" >> $SPLUNK_HOME/etc/splunk-launch.conf

# Launch Splunk prior to installing Splunk Apps
$SPLUNK_HOME/bin/splunk start \
  --accept-license --answer-yes \
  --seed-passwd $SPLUNK_ADMIN_PASSWORD

# Install Hadoop Connect
$SPLUNK_HOME/bin/splunk install app /tmp/splunk-hadoop-connect_125.tgz -auth admin:$SPLUNK_ADMIN_PASSWORD

# Install Cisco Security Suite (for sample data generation together with Eventgen)
$SPLUNK_HOME/bin/splunk install app /tmp/cisco-security-suite_312.tgz -auth admin:$SPLUNK_ADMIN_PASSWORD

# Install Eventgen (for sample data generation together with Cisco Security Suite)
$SPLUNK_HOME/bin/splunk install app /tmp/eventgen_632.tgz -auth admin:$SPLUNK_ADMIN_PASSWORD
