#!/bin/bash

#########################################
##        ENVIRONMENTAL CONFIG         ##
#########################################

# Configure user nobody to match unRAID's settings
export DEBIAN_FRONTEND="noninteractive"
usermod -u 99 nobody
usermod -g 100 nobody
usermod -d /home nobody
chown -R nobody:users /home


#########################################
##  FILES, SERVICES AND CONFIGURATION  ##
#########################################
#config
cat <<'EOT' > /etc/my_init.d/config.sh
#!/bin/bash
if [[ $(cat /etc/timezone) != $TZ ]] ; then
  echo "$TZ" > /etc/timezone
  DEBIAN_FRONTEND="noninteractive" dpkg-reconfigure -f noninteractive tzdata
fi
EOT

# resilio
mkdir -p /etc/service/resilio
cat <<'EOT' > /etc/service/resilio/run
#!/bin/bash
umask 000
[[ ! -f /config/btsync.conf ]] && cp /tmp/btsync.conf /config/
[[ ! -d /config/.sync ]] && mkdir -p /config/.sync
[[ ! -f /config/.sync/debug.txt ]] && echo '0000' > /config/.sync/debug.txt
[[ "$(stat -c %Y /config/.sync/debug.txt 2>/dev/null || echo 0)" -lt "1454620500" ]] && echo '0000' > /config/.sync/debug.txt
chown -R nobody:users /opt/resilio /config
exec /sbin/setuser nobody /opt/resilio/rslsync --nodaemon --log "/config/btsync.log" --config "/config/btsync.conf"
EOT

cat <<'EOT' > /tmp/btsync.conf
{
  "device_name": "unRAID",
  "listening_port" : 5555,
  "storage_path" : "/config/.sync",
  "use_upnp" : false,

  "download_limit" : 0,
  "upload_limit" : 0,
  "webui" :
  {
    "listen" : "0.0.0.0:8888"
  }
}
EOT

chmod -R +x /etc/service/ /etc/my_init.d/


#########################################
##             INSTALLATION            ##
#########################################

# Install Resilio 2.5.3
mkdir -p /opt/resilio
curl -s -k -L "https://download-cdn.resilio.com/stable/linux-x64/resilio-sync_x64.tar.gz" | tar -xzf - -C /opt/resilio


#########################################
##                 CLEANUP             ##
#########################################

# Clean APT install files
apt-get clean -y
rm -rf /var/lib/apt/lists/* /var/cache/* /var/tmp/*
