#!/bin/sh -eu

trap 'litecoin-cli stop' SIGTERM

exec litecoind "$@"
