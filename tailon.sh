#! /bin/bash
# Install tailon and configure it as systemd service.
# This script must be run as root for proper installation.
# Engie Tawfik - 20180821.

LATEST_RELEASE=`curl -s https://api.github.com/repos/gvalkov/tailon/releases/latest | grep browser_download_url | grep linux_amd64 | cut -d'"' -f4`
SAVE_PATH='/tmp/tailon-latest.tar.gz'
TPATH='/opt/SP/tailon'
TSERVICE='/etc/systemd/system/tailon.service'

# Download the latest x86_64 release
echo -e "\n*** Downloading tailon latest release..."
wget -q --show-progress -O $SAVE_PATH $LATEST_RELEASE

# Create tailon user
echo -e "\n*** Creating tailon user..."
useradd tailon -s /bin/bash
echo -e "\n*** Please provide a password for tailon user:"
passwd tailon

# Extract the latest tarball
echo -e "\n*** Extracting the tarball to ${TPATH}"
mkdir -p ${TPATH}
tar xvf ${SAVE_PATH} -C ${TPATH}

# Create example log for tailon 
echo -e "\n*** Creating tailon log file."
touch /var/log/tailon.log
chown tailon:tailon /var/log/tailon.log

# Create the starting script
echo -e "\n*** Creating the starting script."
cat << EOF >> ${TPATH}/start.sh
#! /bin/bash
# Engie Tawfik - 20180726
# A script to start tailon - https://github.com/gvalkov/tailon
${TPATH}/tailon -b "0.0.0.0:5000" "alias=Tailon,group=Tailon,/var/log/tailon*" &> /var/log/tailon.log &
EOF
chmod 750 ${TPATH}/start.sh

# Create the service unit
echo -e "\n*** Creating tailon service."
cat << EOF > ${TSERVICE}
[Unit]
Description=Tailon Log Viewer

[Service]
User=tailon
Type=forking

#change this to your workspace
WorkingDirectory=/opt/SP/tailon/

#executable is a bash script which calls tailon binary.
ExecStart=/opt/SP/tailon/start.sh
SuccessExitStatus=143
TimeoutStopSec=10
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Change ownership of everything to tailon user
chown -R tailon:tailon ${TPATH}

# Enable and start tailon service
systemctl daemon-reload
systemctl enable tailon
systemctl start tailon
echo -e "\n*** Tailon service enabled and started."
netstat -antpue | grep 5000
echo -e "\n*** Now you can access http://localhost:5000"


