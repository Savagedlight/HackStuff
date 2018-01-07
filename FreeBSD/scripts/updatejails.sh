#!/bin/sh
# Copyright (c) 2018 Marie Helene Kvello-Aune (marieheleneka at gmail dot com; https://savagedlight.me)
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
# This script automatically does a 'make installworld' with DESTDIR of all directories found in /usr/jails
# It does NOT manage etcupdate, sorry.
#

C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_CYAN='\033[0;36m'
C_NONE='\033[0;0m'

cd /usr/src
echo "Found" `ls -ld /usr/jails/* | wc -l` "jails"
for d in /usr/jails/*/; do
        echo -e "${C_CYAN}Updating jail ${C_YELLOW}${d}${C_NONE}"
        make installworld DESTDIR=${d} > /dev/null 2>&1
done
echo -e "${C_GREEN}Done.${C_NONE}"
