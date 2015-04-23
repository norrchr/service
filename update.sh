#!/bin/bash
# 1=up-to-date 0=needs update
VERS=$(curl https://raw.githubusercontent.com/r0t3n/service/master/core/__version.tcl --max-time 10 --silent | egrep -ie "variable vers(major|minor|bugfix)" | tr -d \" | awk '{print $3}' | awk '{getline b;getline c;printf("%s.%s.%s\n",$0,b,c)}')
COMMIT=$(git rev-parse HEAD)
RESULT=$(git pull)
CODE=$?
NCOMMIT=$(git rev-parse HEAD)
if [[ $CODE -eq 0 ]];
then
	if [[ $COMMIT == $NCOMMIT ]];
	then
		echo "0 $VERS $COMMIT"
	else
		echo "1 $VERS $NCOMMIT"
	fi
else
	echo "-1 $RESULT"
fi
