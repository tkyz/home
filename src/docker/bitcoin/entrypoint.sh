#!/bin/sh -eu

trap 'bitcoin-cli stop' SIGTERM

exec bitcoind "$@"
