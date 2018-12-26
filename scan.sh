#!/bin/bash
set -euo pipefail

retry(){
	until "$@"; do
		echo "$@ failed, delaying randomly"
		sleep ${RANDOM:1:1}
	done
}

submit(){
	(
		flock -x 8
		git add "$1"
		git commit -m "Updating $1"
		git push
	) 8>git.stage
}

scanloop(){
	while true; do
		rm "$1".log || true
		~/bin/ftp.list "$1"
		[ -n "$(git status --porcelain "$1".log)" ] && submit "$1".log
		sleep 3600
	done
}

while true; do 
	echo "$(date) Starting scan"
	nmap -Pn -p 21,2121,2122,80,81,88,8080 -vv -oG scan.gnmap -T5 -n 151.217.0/16 >/dev/null
	submit scan.gnmap
	echo "$(date) Scan ended"
	for ip in $(awk '/21\/open/{print $2}' scan.gnmap ); do
		if [ ! -e "$ip".log ]; then
			echo "Starting scan loop for $ip"
			scanloop "$ip" &
		fi
	done
	sleep 3600
done
