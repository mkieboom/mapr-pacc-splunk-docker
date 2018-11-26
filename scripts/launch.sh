#!/bin/bash

# Check if the /mapr/clustername mountpoint is available
if [ "$(sudo ls $MAPR_MOUNT_PATH |wc -l)" -eq 0 ]; then
  echo "MapR mountpoint not available. Check cluster config. Exiting now."
  exit 1
fi

# MapR mountpoint is available. Configuring Splunk

# Configure Eventgen to generate test data
mkdir -p $SPLUNK_HOME/etc/apps/SA-Eventgen/local/
cat <<EOF > $SPLUNK_HOME/etc/apps/SA-Eventgen/local/inputs.conf
[modinput_eventgen://default]
disabled = 0
EOF

# Configure Hadoop Connect with locally mounted MapR Cluster
mkdir -p $SPLUNK_HOME/etc/apps/HadoopConnect/local/
cat <<EOF > $SPLUNK_HOME/etc/apps/HadoopConnect/local/clusters.conf
[MapR]
namenode_http_port = None
uri = file://$MAPR_MOUNT_PATH/$MAPR_CLUSTER/
EOF

# Create an offload folder on the MapR Cluster
mkdir /$MAPR_MOUNT_PATH/$MAPR_CLUSTER/$SPLUNK_OFFLOAD_DIR/

# Configure offloading to MapR using Splunk Hadoop Connect
cat <<EOF > $SPLUNK_HOME/etc/apps/HadoopConnect/local/export.conf
[offload_to_mapr]
base_path = $SPLUNK_OFFLOAD_DIR
partition_fields = host,date,hour
search = search *
starttime = 1543100400
uri = file://$MAPR_MOUNT_PATH/$MAPR_CLUSTER/
compress_level = 0
EOF

cat <<EOF > $SPLUNK_HOME/etc/apps/HadoopConnect/local/savedsearches.conf
[ExportSearch:offload_to_mapr]
alert.track = 0
cron_schedule = */5 * * * *
enableSched = 1
is_visible = 0
search = | runexport name="offload_to_mapr"
EOF

cat <<EOF > $SPLUNK_HOME/etc/apps/HadoopConnect/local/app.conf
[ui]

[launcher]

[install]
is_configured = 1
EOF


## Create Input Folders on the MapR Cluster and Deploy Test Dataset

# Create an import folder on the MapR Cluster to deploy a Data Input via NFS mountpoint
mkdir /$MAPR_MOUNT_PATH/$MAPR_CLUSTER$SPLUNK_IMPORT_NFS_DIR/
# Create an import folder on the MapR Cluster to deploy a Virtual Index using YARN
mkdir /$MAPR_MOUNT_PATH/$MAPR_CLUSTER$SPLUNK_IMPORT_VIRTUALINDEX_DIR/

# Deploy Test Dataset on MapR Cluster
wget http://docs.splunk.com/images/Tutorial/tutorialdata.zip -O /tmp/tutorialdata.zip
unzip -o /tmp/tutorialdata.zip -d /tmp/
/bin/cp -fR /tmp/www* /$MAPR_MOUNT_PATH/$MAPR_CLUSTER$SPLUNK_IMPORT_VIRTUALINDEX_DIR/
/bin/cp -fR /tmp/vendor_sales /$MAPR_MOUNT_PATH/$MAPR_CLUSTER$SPLUNK_IMPORT_NFS_DIR/


## Splunk Data Input (NFS)

# Create a Data Input via NFS mountpoint
cat <<EOF > $SPLUNK_HOME/etc/apps/HadoopConnect/local/inputs.conf
[monitor://$MAPR_MOUNT_PATH/$MAPR_CLUSTER$SPLUNK_IMPORT_NFS_DIR]
disabled = false
EOF


## Splunk Virtual Index

# Create a Virtual Index Provider pointing towards YARN on MapR
mkdir -p $SPLUNK_HOME/etc/apps/search/local/
cat <<EOF > $SPLUNK_HOME/etc/apps/search/local/indexes.conf
[provider:mapr_virtual_index_provider]
vix.description = mapr_virtual_index_provider
vix.env.HADOOP_HOME = /opt/mapr/hadoop/hadoop-2.7.0/
vix.env.JAVA_HOME = $JAVA_HOME/jre/
vix.family = hadoop
vix.mapreduce.framework.name = yarn
vix.splunk.home.hdfs = /splunk_import_virtualindex
vix.fs.default.name = maprfs://$MAPR_CLDB_HOST
vix.yarn.resourcemanager.address = $MAPR_YARN_RM_NODE:8025
vix.yarn.resourcemanager.scheduler.address = $MAPR_YARN_RM_NODE:8030
vix.output.buckets.max.network.bandwidth = 0
vix.command.arg.3 = $SPLUNK_HOME/bin/jars/SplunkMR-hy2.jar
vix.env.HUNK_THIRDPARTY_JARS = $SPLUNK_HOME/bin/jars/thirdparty/common/avro-1.7.7.jar,$SPLUNK_HOME/bin/jars/thirdparty/common/avro-mapred-1.7.7.jar,$SPLUNK_HOME/bin/jars/thirdparty/common/commons-compress-1.10.jar,$SPLUNK_HOME/bin/jars/thirdparty/common/commons-io-2.4.jar,$SPLUNK_HOME/bin/jars/thirdparty/common/libfb303-0.9.2.jar,$SPLUNK_HOME/bin/jars/thirdparty/common/parquet-hive-bundle-1.6.0.jar,$SPLUNK_HOME/bin/jars/thirdparty/common/snappy-java-1.1.1.7.jar,$SPLUNK_HOME/bin/jars/thirdparty/hive_1_2/hive-exec-1.2.1.jar,$SPLUNK_HOME/bin/jars/thirdparty/hive_1_2/hive-metastore-1.2.1.jar,$SPLUNK_HOME/bin/jars/thirdparty/hive_1_2/hive-serde-1.2.1.jar


[mapr_virtual_index]
vix.description = mapr_virtual_index
vix.input.1.path = $SPLUNK_IMPORT_VIRTUALINDEX_DIR/...
vix.provider = mapr_virtual_index_provider
EOF

cat <<EOF > $SPLUNK_HOME/etc/apps/search/metadata/local.meta
[indexes/mapr_virtual_index]
version = 7.2.1
modtime = 1543234916.296834000

[indexes/provider%3Amapr_virtual_index_provider]
version = 7.2.1
modtime = 1543235000.319442000
EOF

# Launch Splunk
$SPLUNK_HOME/bin/splunk start \
  --accept-license --answer-yes \
  --seed-passwd $SPLUNK_ADMIN_PASSWORD


# Keep container running
/bin/bash