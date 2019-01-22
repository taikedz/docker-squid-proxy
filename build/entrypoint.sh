#!/usr/bin/env bash

options=(
	-N # prevent daemonizing
	-f /etc/squid3/squid-alt.conf
)

echo "Arguments: [$*]"

if [[ -n "$*" ]]; then
	if [[ "$1" =~ ^/ ]]; then
		"$@"
	else
		options=("$@")
	fi
fi

set -x
#squid -z # initialize cache directories
exec squid "${options[@]}"
