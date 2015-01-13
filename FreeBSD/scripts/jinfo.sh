#!/bin/sh
# Copyright (c) 2015 Savagedlight (marieheleneka@gmail.com, http://savagedlight.me)
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

JAILS=`jls -n name | cut -d '=' -f 2`

OP="JAIL MEM SWAP PROC FILES %CPU tCPU\n"

for jail in $JAILS; do
  # Really need to optimize this.
  i_MEM=`rctl -h -u jail:$jail | grep memoryuse= | grep -v vmemoryuse | cut -d '=' -f 2`
  i_SWAP=`rctl -h -u jail:$jail | grep swapuse= | cut -d '=' -f 2`
  i_PROC=`rctl -h -u jail:$jail | grep maxproc= | cut -d '=' -f 2`
  i_FILES=`rctl -h -u jail:$jail | grep files= | cut -d '=' -f 2`
  i_CPU=`rctl -h -u jail:$jail | grep pcpu= | cut -d '=' -f 2`
  i_tCPU=`rctl -h -u jail:$jail | grep cputime= | cut -d '=' -f 2`

  # This, too, needs optimization.
  OP="$OP\n$jail $i_MEM $i_SWAP $i_PROC $i_FILES $i_CPU $i_tCPU"
done

echo -e "$OP" | column -t
