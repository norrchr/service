#!/bin/bash
# 1=up-to-date 0=needs update
VERS=$(curl https://raw.githubusercontent.com/r0t3n/service/master/core/__version.tcl --silent | egrep -ie "variable vers(major|minor|bugfix)" | tr -d \" | awk '{print $3}' | awk '{getline b;getline c;printf("%s.%s.%s\n",$0,b,c)}')
[ "`git log --pretty=%H ...refs/heads/master^ | head -n 1`" = "`git ls-remote origin -h refs/heads/master |cut -f1`" ] && echo "1 $VERS" || echo "0 $VERS"
