#!/bin/sh
#
# Version 0.1
# Date: 2024-01-06
#
# This script is intended to install the necessary checkmk-plugins for a debian-system. This is only needed if you are running the RAW-Edition of checkMK, as the the commercial versions can handle the plugins with the backery.

# General settings
SERVER=monitor.lan
INSTANCE=monitoring

# Which plugins should be installed. Activate with "YES"
APT=YES # Check for apt updates

############################################################################
# No changes beyond this line if you don't really know what you are doing. #
############################################################################

PLUGINSDIR=/usr/lib/check_mk_agent/plugins

# Downloads the plugin from the server
# load_plugin PLUGINNAME
load_plugin()
{
    wget --no-check-certificate https://$SERVER/$INSTANCE/check_mk/agents/plugins/$1
    chmod 755 $1
}

# Downloads the plugin from the server for asynchronous start.
# load_plugin_async PLUGINNAME DELAY_IN_SECONDS
load_plugin_async()
{
    if [ ! -d $PLUGINSDIR/$2 ]; then
        mkdir $PLUGINSDIR/$DELAY
    fi
    cd $PLUGINSDIR/$DELAY
    load_plugin $1
}

####
# check for root
if [ `id -u` -ne 0 ]; then
	echo "This script must be run as root."
	exit 1
fi

if [ ! -d $PLUGINSDIR ]; then
    echo "Das Verzeichnis $PLUGINSDIR ist nicht vorhanden. Es hat den Anschein, dass check-mk-agent noch nicht installiert ist."
    exit 1
fi

if [ $APT = "YES" ]; then
    DELAY=21600
    load_plugin_async mk_apt $DELAY
fi


echo "You should run a new service discovery on the checkmk-server"
