#!/bin/sh
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

# This script will check if the specified certificate will
# expire in 14d or less and if so, instruct let's encrypt to renew it.
# It will also reload the configured webserver if certificate is renewed.

#
# Start of configuration
#
LETSENCRYPTSERVER='https://acme-v01.api.letsencrypt.org/directory'
DOMAINS="-d example.com -d domain1.example.com -d someothedomain.example"
DIR=/tmp/letsencrypt-auto

# Probably don't need to edit below here
OPENSSL="/usr/bin/openssl"
LETSENCRYPT="/usr/local/bin/letsencrypt"
# It's good enough to reload nginx. Other webservers may require restart.
RELOADWEBSERVER="/usr/sbin/service nginx reload"

#
# End of configuration.
#

#
# !!! DO NOT EDIT BELOW HERE !!!
#

alias errecho='>&2 echo'

if [ "$1" ]
then
  if [ ! -f "$1" ]
  then
    errecho "First argument must be path to a certificate file. Non-file path provided."
    exit
  fi
else
  errecho "First argument must be path to a certificate file. No argument provided."
  exit
fi

if $OPENSSL x509 -checkend 1209600 -noout -in $1
then
  echo "Good for another 14 days!"
else
  mkdir -p $DIR
  chown -R www:www $DIR
  $LETSENCRYPT certonly --renew --server $LETSENCRYPTSERVER -a webroot --webroot-path=$DIR --agree-dev-preview $DOMAINS
  echo "Certificate should be renewed now. Re-testing..."
  if $OPENSSL x509 -checkend 1209600 -noout -in $1
  then
    echo "Certificate was successfully renewed! Telling webserver..."
    $RELOADWEBSERVER
  else
    errecho "Certificate failed to renew."
    exit
  fi
fi
