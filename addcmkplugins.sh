#!/bin/sh
#
# Version 0.1
# Date: 2024-01-06
#
# This script is intended to install the necessary checkmk-plugins for a debian-system. This is only needed if you are running the RAW-Edition of checkMK, as the the commercial versions can handle the plugins with the backery.
# WARNING: No errorhandling

# General settings
SERVER=monitor.lan                      # URL of CheckMK-server
INSTANCE=monitoring                     # Name of the instace on the server
AGENT=check-mk-agent_2.2.0p17-1_all.deb # Name of the current agent-file on the sever
INSTALLAGENT=YES                        # Should the agent be installed if not already there?
SERVERUSER=cmkadmin                     # User to register agent with

# Which plugins should be installed. Activate with "YES"

APT=YES         # Check for apt updates
APTDELAY=21600  # run every 6h (seconds)

APACHE2=NO      # Check apache-status

NGINX=NO        # Check nginx-status

MYSQL=NO        # Check mysql-status

POSTGRES=NO     # postgres postgres

############################################################################
# No changes beyond this line if you don't really know what you are doing. #
############################################################################

PLUGINSDIR=/usr/lib/check_mk_agent/plugins
AGENTURL=https://$SERVER/$INSTANCE/check_mk/agents/$AGENT

# Downloads the plugin from the server
# load_plugin PLUGINNAME DESTINATION
load_plugin()
{
   if [ -n $2 ]; then
        PREFIX=$2       
else
        PREFIX=$PLUGINSDIR
   fi
    wget --no-check-certificate -P $PREFIX https://$SERVER/$INSTANCE/check_mk/agents/plugins/$1
    chmod 755 $PREFIX/$1
}


# Downloads the plugin from the server for asynchronous start.
# load_plugin_async PLUGINNAME DELAY_IN_SECONDS
load_plugin_async()
{
    if [ ! -d $PLUGINSDIR/$2 ]; then
        mkdir $PLUGINSDIR/$DELAY
    fi
#    cd $PLUGINSDIR/$DELAY
    DESTINATION=$PLUGINSDIR/$DELAY
    load_plugin $1 $DESTINATION
}

####
# check for root
if [ `id -u` -ne 0 ]; then
        echo "This script must be run as root."
        exit 1
fi

if [ $INSTALLAGENT = "YES" ]; then
    HOSTNAME=`hostname -f`
    echo "We will try to install the agent and register it at the server now."
    echo "You should add the host to the CheckMK-Server before you continue."
    echo "Press Return to continue or crtl-c to exit:"; read YN
# test if agent is installed and install
    if ! dpkg -l | grep check-mk-agent; then
        echo "CheckMK-agent is not installed, it will be downloaded and installed now."
        cd /tmp
        wget --no-check-certificate -P '/tmp' $AGENTURL
        dpkg -i /tmp/$AGENT
        rm /tmp/$AGENT
#register the agent on the server
        echo "Now we will try to register the agent."
        echo "Should we use $HOSTNAME as hostname to register? This means it should be the name you used on the server (Y/N)";read YN
        if [ ! $YN="Y"] && [ ! $YN="y" ] ; then
            echo "Please give the hostname we should use to register the host"; read HOSTNAME
        fi
        echo "We try to register the host using the hostname: $HOSTNAME"
        cmk-agent-ctl register --hostname $HOSTNAME --server $SERVER --site $INSTANCE --user $SERVERUSER
    fi
fi


if [ ! -d $PLUGINSDIR ]; then
    echo "Das Verzeichnis $PLUGINSDIR ist nicht vorhanden. Es hat den Anschein, dass check-mk-agent noch nicht installiert ist."
    exit 1
fi

if [ $APT = "YES" ]; then
    DELAY=21600
    load_plugin_async mk_apt $DELAY
fi

if [ $APACHE2 = "YES" ]; then
    load_plugin apache2_status.py
fi

if [ $NGINX = "YES" ]; then
    load_plugin nginx2_status.py
fi

if [ $MYSQL = "YES" ]; then
    load_plugin mk_mysql2
fi
if [ $POSTGRES = "YES" ]; then
    load_plugin mk_postgres2.py
fi
echo "You should run a new service discovery on the checkmk-server"
