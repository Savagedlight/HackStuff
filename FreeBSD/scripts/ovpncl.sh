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

# Host and port the client should connect to.
SERVERHOST='rproxy.example.com'
SERVERPORT='1194'

# Default paths used for auto-generating other paths.
CLIENTCONFDIR='/usr/local/etc/openvpn/clients'
OVPNCONFDIR='/usr/local/etc/openvpn'


alias errecho='>&2 echo'
echo_bold() {
  echo -e "\e[1m${1-}\e[0m"
}

print_help() {
	echo_bold 'ScriptName v1.0'
	echo ''
	echo 'This script handles OpenVPN client configurations.'
	echo 'It will:'
	echo ' - Automatically generate client key pairs if they do not already exist.'
	echo ' - Automatically generate client-side OpenVPN configuration file with relevant connection settings mirroring server.conf.'
	echo ' - Automatically generate server-side client configuration.'
	echo '   Supported settings:'
	echo '   - Enforce a specific IP address for the client'
    echo '   - More upon request :)'
	echo ''
	echo 'If the client certificate already exists, it will:'
	echo ' - Update all the previously merntioned configurations.'
	echo ''
	echo_bold 'Priority of configuration sources for the script'
	echo '1st priority: Configuration file loaded with the -c argument.'
	echo '2nd priority: Environmental variables.'
	echo '3rd priority: Default values.'
	echo ''
	echo_bold 'Return Codes'
	echo ' 0   Some operation which did not alter anything was performed. Typically when run with the -h, -C or -D arguments.'
	echo ' 1   Encountered error. See stderr for details.'
	echo ' 2   Client-side configuration was created or changed.'
	echo ' 4   Client-side configuration was NOT changed.'
	echo ''
	echo_bold 'Required Arguments'
	echo ' -n client_name'
	echo '    Specifies a client name. Client name must be a single word. May contain numbers.'
	echo ''
	echo_bold 'Optional Arguments'
	echo ' -a ipAddress'
	echo '    Server will force the specified IP address onto the clients tunnel endpoint.'
	echo ''
    echo ' -c /path/to/config/file'
    echo '    Specifies an absolute or relative path to a configuration file.'
    echo '    Variables defined in the configuration file will override defaults, and environmental variables.'
    echo '    If the specified path does not exist, the script will throw an error and exit.'
    echo ''
	echo ' -C'
	echo '    An example configuration file for use with -c will be echoed to stdout.'
	echo ''
	echo ' -D'
	echo '    Echos variable names and values to stdout, then exits. No changes will be made.'
	echo '    Useful for verifying the specified arguments will give the expected result.'
	echo ''
}

print_exampleconfig() {
  echo '#!/bin/sh'
  echo '# Configuration file for ScriptName. Use with -c /path/to/this/file'
  echo ''
  echo '#'
  echo '# Connection Info'
  echo '#'
  echo 'SERVERHOST=rproxy.example.com'
  echo 'SERVERPORT=1194'
  echo ''
  echo '#'
  echo '# Base Paths'
  echo '#'
  echo ''
  echo '# Directory to store client-side configurations and clients key pairs'
  echo "CLIENTCONFDIR='${CLIENTCONFDIR}'"
  echo '# Directory containing OpenVPN servers configuration files.'
  echo "OVPNCONFDIR='${OVPNCONFDIR}'"
  echo ''
  echo '#'
  echo "# Generated Paths"
  echo '#'
  echo ''
  echo '# Client configuration file and key pair directory.'
  echo 'CLIENTCONFFILE="$CLIENTCONFDIR/$CLIENTNAME.conf"'
  echo 'CLIENTKEYDIR="$CLIENTCONFDIR/$CLIENTNAME/"'
  echo ''
  echo '# Server configuration file.'
  echo '# Used for auto-fetching parameters when generating client-side config.'
  echo 'SERVERCONF="$OVPNCONFDIR/server.conf"'
  echo ''
  echo '# EasyRSA: Directory where EasyRSA stores generated keys'
  echo 'EASYRSAKEYS="${OVPNCONFDIR}/easy-rsa/keys/"'
  echo ''
  echo '# Certificate Authoritys public certificate'
  echo 'CAPATH="${OVPNCONFDIR}/cacert.pem"'
  echo ''
  echo '# Server-Side client configuration file'
  echo 'SERVERSIDECONFPATH="${OVPNCONFDIR}/csr/${CLIENTNAME}"'
  
  echo '# OpenVPN server/client linknet subnet mask'
  echo "OVPNLINKNETSUBNETMASK=\$(grep \"^server \" \$SERVERCONF | cut -d ' ' -f 3)"
}
#
# Parse options
#
while getopts "h?CDen:a:c:" opt; do
  case "$opt" in
  h|\?)
    print_help
    exit 0
    ;;
  n)
	CLIENTNAME=$OPTARG
    ;;
  a)
    OVPNLINKNETCLIENTIP=$OPTARG
	;;
  c)
	. ${OPTARG}
    ;;
  e)
    echo 'Should override defaults using environmental variables.'
	exit 0
	;;
  C)
    print_exampleconfig
	exit 0
	;;
  D)
    PRINTVARIABLES=1
	;;
  esac
done

if [ -z "${CLIENTNAME}" ]
then
  errecho 'Missing client name! See help (-h) for more info.'
  exit 1
fi

# Client configuration file (used by OpenVPN client)
if [ -z "${CLIENTCONFFILE}" ]
then
  CLIENTCONFFILE="${CLIENTCONFDIR}/$CLIENTNAME.conf"
fi
if [ -z "${CLIENTKEYDIR}" ]
then
  CLIENTKEYDIR="${CLIENTCONFDIR}/$CLIENTNAME"
fi
# Server configuration file. Used for auto-fetching parameters for generating client config.
if [ -z "${SERVERCONF}" ]
then
  SERVERCONF="${OVPNCONFDIR}/server.conf"
fi

# EasyRSA: Directory where EasyRSA stores generated keys.
if [ -z "${EASYRSAKEYS}" ]
then
  EASYRSAKEYS="${OVPNCONFDIR}/easy-rsa/keys"
fi

# Certificate authority's certificate
if [ -z "${CAPATH}" ]
then
  CAPATH="${OVPNCONFDIR}/cacert.pem"
fi

# Server-side client configuration path, for this client.
if [ -z "${SERVERSIDECLIENTCONFPATH}" ]
then
  SERVERSIDECLIENTCONFPATH="${OVPNCONFDIR}/csr/${CLIENTNAME}"
fi

if [ -z "${OVPNLINKNETSUBNETMASK}" ]
then
  OVPNLINKNETSUBNETMASK=$(grep "^server " $SERVERCONF | cut -d ' ' -f 3)
fi

if [ -n "$PRINTVARIABLES" ]
then
  echo_bold 'Client Connection Info'
  echo " SERVERHOST               ${SERVERHOST}"
  echo " SERVERPORT               ${SERVERPORT}"
  echo ''
  echo_bold 'Force client endpoint IP address?'
  echo " OVPNLINKNETCLIENTIP      ${OVPNLINKNETCLIENTIP}"
  echo " OVPNLINKNETSUBNETMASK    ${OVPNLINKNETSUBNETMASK}"
  echo ''
  echo_bold 'Base Paths:'
  echo " CLIENTCONFDIR            ${CLIENTCONFDIR}"
  echo " OVPNCONFDIR              ${OVPNCONFDIR}"
  echo ''
  echo_bold 'Generated paths'
  echo " CLIENTCONFFILE           ${CLIENTCONFFILE}"
  echo " CLIENTKEYDIR             ${CLIENTKEYDIR}"
  echo " SERVERCONF               ${SERVERCONF}"
  echo " EASYRSAKEYS              ${EASYRSAKEYS}"
  echo " CAPATH                   ${CAPATH}"
  echo " SERVERSIDECLIENTCONFPATH ${SERVERSIDECLIENTCONFPATH}"
  echo ''
  echo 'ALL the above variables may be overridden in -c config_file or environmental variables.'
  echo 'DO TAKE CARE to properly account for client name and such.'
  exit 0
fi

#
# End of adjustable variables
#

# Check if client's certificate directory exists. If not, generate keys etc.
if [ ! -e $CLIENTKEYDIR ]
then
  # Create keys
  cd /usr/local/etc/openvpn/easy-rsa
  . ./vars
  ./build-key $1
  if [ ! -f "$EASYRSAKEYS/$CLIENTNAME.crt" ] || [ ! -f "$EASYRSAKEYS/$CLIENTNAME.key" ]
  then
    errecho "Something went wrong: Generated client certificates were not found at the expected location."  
    errecho "  I attempted to generate them because client name '${CLIENTNAME}' didn't have any known keys."
    exit 1
  fi
  # Create directory and move keys there
  mkdir -p $CLIENTKEYDIR
  mv "$EASYRSAKEYS/$CLIENTNAME.crt" "$CLIENTKEYDIR/pubcert.pem"
  mv "$EASYRSAKEYS/$CLIENTNAME.key" "$CLIENTKEYDIR/privatekey.pem"
else
  echo ''
  echo 'Clients certificates already exist. Reusing!'
  echo '  Refreshing client-side OpenVPN configuration.'
  echo '  Refreshing server-side client configuration.'
  echo ''
  CLIENTSIDECONFIGMD5PRE=$(md5 -q ${CLIENTCONFFILE})
fi


echo "Creating OpenVPN client-side configuration in ${CLIENTCONFFILE}"
echo "  This configuration file should be transferred to the client in a secure way."
echo '  Setting connection parameters.'
cat <<EOF                                                          > $CLIENTCONFFILE
# This is the client configuration file for $CLIENTNAME
client
resolv-retry infinite
user nobody
group nobody
nobind
EOF

# Add which server(s) to connect to.
echo "remote ${SERVERHOST} ${SERVERPORT}"                          >> $CLIENTCONFFILE

echo '  Setting synced connectiong paramters, based on server.conf.'
# Autoconf (from grep $SERVERCONF)
grep 'dev '       $SERVERCONF     | grep "^[^#;]"                  >> $CLIENTCONFFILE
grep 'proto '     $SERVERCONF     | grep "^[^#;]"                  >> $CLIENTCONFFILE
grep 'cipher '    $SERVERCONF     | grep "^[^#;]"                  >> $CLIENTCONFFILE
grep 'comp-lzo'   $SERVERCONF     | grep "^[^#;]"                  >> $CLIENTCONFFILE
grep 'tls-cipher' $SERVERCONF     | grep "^[^#;]"                  >> $CLIENTCONFFILE
grep 'persist-'   $SERVERCONF     | grep "^[^#;]"                  >> $CLIENTCONFFILE

echo '  Adding certificates and private key.'
printf "\n<ca>\n"                                                  >> $CLIENTCONFFILE
cat $CAPATH                                                        >> $CLIENTCONFFILE
printf "</ca>\n"                                                   >> $CLIENTCONFFILE
printf "\n<cert>"                                                  >> $CLIENTCONFFILE
grep -v '^ ' "${CLIENTKEYDIR}/pubcert.pem" | grep -v 'Certificate' >> $CLIENTCONFFILE
printf "</cert>\n"                                                 >> $CLIENTCONFFILE
printf "\n<key>\n"                                                 >> $CLIENTCONFFILE
cat "${CLIENTKEYDIR}/privatekey.pem"                               >> $CLIENTCONFFILE
printf "</key>\n"                                                  >> $CLIENTCONFFILE

echo ''
if [ ! -z "${OVPNLINKNETCLIENTIP}"
then
  echo 'Creating server-side client configuration'
  # TODO: Kinda dirty!
  echo "# Server-side client configuration for client '${CLIENTNAME}'"  > $SERVERSIDECLIENTCONFPATH
  echo "ifconfig-push ${OVPNLINKNETCLIENTIP} ${OVPNLINKNETSUBNETMASK}"      >> $SERVERSIDECLIENTCONFPATH
fi


CLIENTSIDECONFIGMD5POST=$(md5 -q ${CLIENTCONFFILE})
echo ''
if [ "${CLIENTSIDECONFIGMD5PRE}" = "${CLIENTSIDECONFIGMD5POST}" ]
then
  echo 'Client-side configuration was not changed.'
  return 4
else
  echo_bold 'Client-side configuration WAS changed.'
  return 2
fi