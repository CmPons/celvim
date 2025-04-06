#!/usr/bin/env bash

set -e

if [[ -z "$1" ]]; then
	echo "A test name must be provided!"
	exit 1
fi
TEST_NAME=$1

if [[ -z "$2" ]]; then
	echo "A working directory must be provided"
	exit 1
fi
cd $(dirname $2)

echo "Working in dir $PWD and test $TEST_NAME"

cwd=$PWD
while [[ ! -f "Cargo.toml" ]]; do
	if [[ $pwd == "/" ]]; then
		echo "Could not find Cargo.toml"
		exit 1
	fi
	cd ..
done
CARGO_CRATE=$(basename $PWD)
echo "Found crate name $CARGO_CRATE..."
cd $cwd

cwd=$PWD
while [[ ! -f "Cargo.lock" ]]; do
	if [[ $pwd == "/" ]]; then
		echo "Could not find Cargo.lock"
		exit 1
	fi
	cd ..
done
CARGO_LOCK_DIR=$PWD
echo "Found Cargo.lock in $CARGO_LOCK_DIR"

echo "Executing cargo test --no-run"
TEST_BIN_PATH=$(cargo t --no-run 2>&1 | grep -o "target/debug/deps/$CARGO_CRATE[a-zA-Z0-9_.-]*")
echo "Done! Test Binary is [$TEST_BIN_PATH]"

echo "Launching GDB"
rust-gdb $TEST_BIN_PATH -ex "rbreak $TEST_NAME" -ex "run $TEST_NAME > /dev/null" -ex "tui e"

