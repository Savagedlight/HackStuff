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

##############
# Parameters #
##############
blocksize=4096
gelikey="/root/keys/mykey.key"

if [ ! -e "/dev/${1}" ]
then
        echo "First parameter must be name of device to encrypt, relative to /dev/"
        exit
fi

if [ ! -e "${gelikey}" ]
then
        echo "Specified GELI key path doesn't exist."
        exit
fi

geli init -l 256 -P -s ${blocksize} -K ${gelikey} /dev/gpt/${1}
geli attach -p -k /root/keys/storage.eli.key /dev/gpt/${1}
echo "$1 is now encrypted. Provider: /dev/gpt/${1}.eli"
echo "Remember to add device (/dev/gpt/${1}) to rc.conf geli_devices variable!"
echo " "
