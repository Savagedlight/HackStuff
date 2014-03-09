#!/bin/sh
#
# Poudriere BulkBuild Queuer Script
# A script made by Savagedlight (http://savagedlight.me/) (marieheleneka at gmail dot com)
#
# This script is designed to instruct Poudriere to perform bulk builds
# based on files residing in a specific directory.
# The authors use case was to create a package repository
# for each machine, jail or VM which needed custom packages.
#
# File names are formatted as BuildJailName.SetName[.ignored]
# Example: 10_0x64.rproxy.
#
#
#
# This script is licenced under the 2-clause BSD license:
# Copyright (c) 2014, "Savagedlight" (http://savagedlight.me/) (marieheleneka at gmail dot com)
# All rights reserved.
#
# Redistribution and use in source and binary forms,
# with or without modification, are permitted provided
# that the following conditions are met:
#
# 1. Redistributions of source code must retain the
# above copyright notice, this list of conditions and
# the following disclaimer.
#
# 2. Redistributions in binary form must reproduce
# the above copyright notice, this list of conditions
# and the following disclaimer in the documentation and/or
# other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
# CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
# INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
# DAMAGE.
#

PrintHelp() {
  echo "Savagedlight's Poudriere Enqueuer Script"
  echo "Licensed under the 2-clause BSD license. See source for details."
  echo
  echo "First (and only) parameter must be either 'help' (displays this text),"
  echo "or a path to a directory which contains files to work on."
  echo
  echo "Files contain a list of packages in the standard Poudriere format,"
  echo "but the file names are formatted as 'BuildJailName.Set[.ignored]'"
  echo "Directories, and files starting with a '.' are ignored."
  echo
  echo "Example file names: "
  echo "  10_0x64.php-web"
  echo "  10_0x86.django.some_comment"
  echo
  echo "These would be built on the 10_0x64 and 10_0x86 jails (respectively),"
  echo "and the sets would be php-web and django (respectively)"
  echo
  echo "The poudriere queue names would be the same as the file names."
}

# Check parameters.
if [ "${1}" == "help" ]; then
  PrintHelp
  exit
fi

if [ -z "${1}" ]; then
  echo "You must provide a directory as first variable."
  PrintHelp
  exit
else
  if [ -d "${1}" ]; then
    dirtoscan="/usr/local/etc/poudriere.d/pkglists/"
  else
    echo "${1} is not a directory."
    PrintHelp
    exit
  fi
fi

QueueStuff() {
 # Parameters
 # 1: queue name
 # 2: path to file with ports to build
 # 3: build jail name
 # 4: set name
 poudriere queue "$1" bulk -f "$2" -j $3 -z $4 >> /dev/null
}

# -I: Don't list hidden files (which is default for root)
# -R: Find files recursively in this directory
# -S -r: Sort by size, smallest first
for f in `ls -ISr $dirtoscan`
do
  file=$dirtoscan$f
  if [ -d "$file" ]; then
    echo "$f is a directory. Skipping."
  else
    fname=`basename $file`
    vm=`echo $fname | cut -d'.' -f1`
    set=`echo $fname | cut -d'.' -f2`
    QueueStuff "$fname" "$file" "$vm" "$set"
  fi
done;
