#!/bin/bash
#Author: Perry

if [[ $# -eq 1 && $1 =~ ^[0-9]+$ ]]; then
	length=$1
	generated=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w $length | head -1)
	echo "Generating steam of characters.."
	sleep 1
	echo "Generation done: $generated"
else
	echo "Usage: uuid-passwd-gen.sh <length>"
fi
