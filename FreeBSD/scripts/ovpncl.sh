#!/bin/sh
#
# Copyright (c) 2015 Marie Helene Kvello-Aune (marieheleneka at gmail dot com; http://savagedlight.me)
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
# 

#
# WARNING: This script is a work in progress!
#
# This script handles OpenVPN client configurations.
# It will:
# - Automatically generate client key pairs if they don't exist
# - Automatically generate client-side openvpn configuration file,
#   with connection settings, synced to server's server.conf
# - Automatically generate server-side client configuration, such as:
# -- enforcing a specific IP address for the client
#
# If the client certificates already exist, it will:
# - Update all the previously mentioned configurations
# - Check if client-side configuration actually changed, and report on this.

#
# USAGE
# To be documented in "-h" parameter later
#
# ./ovpncl.sh -n clientName [-i forced_ip_address ]
#
# example: ./ovpncl.sh -n backend1 -i 192.0.2.10
#


# 
# You may want to configure some variables further down.
#

alias errecho='>&2 echo'
alias erralreadyexist='errecho "The first name must be a client name, and the client must not already exist."'

if [ "$1" ]
then
  CLIENTNAME=$1
else
  echo 'You may provide client name as first (and only) argument to this script.'
  echo 'Please enter client name (single word):'
  echo "TODO: MAKE THIS WORK. For now, provide argument."
  exit
fi

#
# Adjustable Variables
#

# Host and port the client should connect to.
SERVERHOST='rproxy.example.com'
SERVERPORT='1194'

# Client configuration file (used by OpenVPN client)
CLIENTCONFFILE="/usr/local/etc/openvpn/clients/$CLIENTNAME.conf"
CLIENTCERTDIR="/usr/local/etc/openvpn/clients/$CLIENTNAME/"
# Server configuration file. Used for auto-fetching parameters for generating client config.
SERVERCONF='/usr/local/etc/openvpn/server.conf'

# EasyRSA: Directory where EasyRSA stores generated keys.
EASYRSAKEYS='/usr/local/etc/openvpn/easy-rsa/keys/'


# Certificate authority's certificate
CAPATH='/usr/local/etc/openvpn/cacert.pem'

# Server-side client configuration path, for this client.
SERVERSIDECLIENTCONFPATH="/usr/local/etc/openvpn/csr/$CLIENTNAME"

#
# End of adjustable variables
#

echo "Client name: $CLIENTNAME"

# Check if client's certificate directory exists. If not, generate keys etc.
if [ ! -e $CLIENTCERTDIR ]
then
  # Create keys
  cd /usr/local/etc/openvpn/easy-rsa
  . ./vars
  ./build-key $1
  if [ ! -f "$EASYRSAKEYS/$CLIENTNAME.crt" ] || [ ! -f "$EASYRSAKEYS/$CLIENTNAME.key" ]
  then
    errecho "Something went wrong: Generated client certificates were not found at the expected location."  
    errecho "  I attempted to generate them because client name '$CLIENTNAME' didn't have any known keys."
    exit 
  fi
  # Create directory and move keys there
  mkdir -p $CLIENTCERTDIR
  mv "$EASYRSAKEYS/$CLIENTNAME.crt" "$CLIENTCERTDIR/pubcert.pem"
  mv "$EASYRSAKEYS/$CLIENTNAME.key" "$CLIENTCERTDIR/privatekey.pem"
else
  echo ''
  echo 'Clients certificates already exist!'
  echo '  Using existing key pair.'
  echo '  Updating client-side OpenVPN configuration.'
  echo '  Remember to re-deploy on client!'
  echo ''
fi


echo "Creating OpenVPN client-side configuration in $CLIENTCONFFILE"
echo '  Setting connection parameters.'
cat <<EOF                                      > $CLIENTCONFFILE
# This is the client configuration file for $CLIENTCONFFILE
client
resolv-retry infinite
user nobody
group nobody
nobind
EOF

# Add which server(s) to connect to.
echo "remote $SERVERHOST $SERVERPORT"                             >> $CLIENTCONFFILE

echo '  Setting synced connectiong paramters, based on server.conf.'
# Autoconf (from grep $SERVERCONF)
grep 'dev '       $SERVERCONF                                     >> $CLIENTCONFFILE
grep 'proto '     $SERVERCONF                                     >> $CLIENTCONFFILE
grep 'cipher '    $SERVERCONF                                     >> $CLIENTCONFFILE
grep 'comp-lzo'   $SERVERCONF                                     >> $CLIENTCONFFILE
grep 'tls-cipher' $SERVERCONF                                     >> $CLIENTCONFFILE
grep 'persist-'   $SERVERCONF                                     >> $CLIENTCONFFILE

echo '  Adding certificates and private key.'
printf "\n<ca>\n"                                                 >> $CLIENTCONFFILE
cat $CAPATH                                                       >> $CLIENTCONFFILE
printf "</ca>\n"                                                  >> $CLIENTCONFFILE
printf "\n<cert>"                                                 >> $CLIENTCONFFILE
grep -v '^ ' "$CLIENTCERTDIR/pubcert.pem" | grep -v 'Certificate' >> $CLIENTCONFFILE
printf "</cert>\n"                                                >> $CLIENTCONFFILE
printf "\n<key>\n"                                                >> $CLIENTCONFFILE
cat "$CLIENTCERTDIR/privatekey.pem"                               >> $CLIENTCONFFILE
printf "</key>\n"                                                 >> $CLIENTCONFFILE

if [ ! -d $SERVERSIDECLIENTCONFPATH ]
then
  mkdir -p $SERVERSIDECLIENTCONFPATH
fi
echo ''
echo 'Creating server-side client configuration'
# TODO: Actually create this file.
echo '  I still need to be implemented.'
