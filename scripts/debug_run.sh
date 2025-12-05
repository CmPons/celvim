#!/usr/bin/env bash

set -e

if [[ -z "$1" ]]; then
	echo "A line must be provided"
	exit 1
fi
LINE=$1

if [[ -z "$2" ]]; then
	echo "A file name must be provided"
	exit 1
fi
FILE=$2
cd $(dirname $2)

PID=$(ps -e | grep frontend | awk '{print $1}')
while [ -z $PID ]
do
  echo "Waiting for 'frontend' to launch..."
  sleep 1
  PID=$(ps -e | grep frontend | awk '{print $1}')
done

echo "Launching GDB - breakpoint $FILE:$LINE PID $PID"

cleanup() {
  echo "Cleaning up GDB session..."
  if [[ -n $GDB_PID ]]; then
    sudo kill $GDB_PID 2>/dev/null || true
  fi
}
trap cleanup EXIT


sudo -E rust-gdb -q -ex "set pagination off" -ex "attach $PID" -ex "b $FILE:$LINE" -ex "tui e" -ex "c"
GDB_PID=$!
