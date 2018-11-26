# Splunk Enterprise on MapR PACC
#
# VERSION 0.1 - not for production, use at own risk
#

#
# Using MapR PACC as the base image
# For specific versions check: https://hub.docker.com/r/maprtech/pacc/tags/
FROM centos:centos7

MAINTAINER mkieboom @mapr.com

# MapR Environment Variables
ENV MAPR_VERSION=6.1.0
ENV MAPR_MEP_VERSION=6.0.0
ENV container=docker

# Splunk Environment Variables
ENV SPLUNK_ADMIN_PASSWORD=adminadmin
ENV SPLUNK_HOME=/opt/splunk
ENV SPLUNK_OFFLOAD_DIR=/splunk_offload/
ENV SPLUNK_IMPORT_NFS_DIR=/splunk_import_nfs/
ENV SPLUNK_IMPORT_VIRTUALINDEX_DIR=/splunk_import_virtualindex/


# MapR PACC with Hadoop and POSIX Clients

RUN yum install -y curl net-tools sudo wget \
                   which initscripts syslinux openssl \
                   file java-1.8.0-openjdk-devel && \
    yum -q clean all

LABEL mapr.os=centos7 \
      mapr.version=${MAPR_VERSION} \
      mapr.mep_version=${MAPR_MEP_VERSION}

COPY scripts/mapr-setup.sh /opt/mapr/installer/docker/

RUN sudo chmod +x /opt/mapr/installer/docker/mapr-setup.sh && \
    /opt/mapr/installer/docker/mapr-setup.sh \
        -r http://package.mapr.com/releases \
        container client \
        ${MAPR_VERSION} ${MAPR_MEP_VERSION} \
        mapr-client mapr-posix-client-container

ENTRYPOINT ["/opt/mapr/installer/docker/mapr-setup.sh", "container"]


# Splunk Download URL
ENV SPLUNK_DOWNLOAD_URL='https://www.splunk.com/bin/splunk/DownloadActivityServlet?architecture=x86_64&platform=linux&version=7.2.1&product=splunk&filename=splunk-7.2.1-be11b2c46e23-linux-2.6-x86_64.rpm&wget=true'

# Download and Install Splunk
RUN wget -O /tmp/splunk.rpm ${SPLUNK_DOWNLOAD_URL} && \
    rpm -i --prefix=/opt/ /tmp/splunk.rpm && \
    rm -rf /tmp/splunk.rpm && \
    yum install -y unzip

# Add the Splunk Apps for Demo Data Generation (eventgen & Cisco) and Hadoop Connect
COPY splunk_apps/eventgen_632.tgz /tmp/eventgen_632.tgz
COPY splunk_apps/splunk-hadoop-connect_125.tgz /tmp/splunk-hadoop-connect_125.tgz
COPY splunk_apps/cisco-security-suite_312.tgz /tmp/cisco-security-suite_312.tgz

# Expose the Splunk port
EXPOSE 8000

# Add and Run the Install Script
ADD scripts/install.sh /install.sh
RUN sudo chmod +x /install.sh && \
    sudo -E /install.sh

# Add the launch script
ADD scripts/launch.sh /launch.sh
RUN sudo chmod +x /launch.sh
CMD sudo -E /launch.sh
