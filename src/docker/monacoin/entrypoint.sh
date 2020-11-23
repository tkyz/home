#!/bin/sh -eu

trap 'monacoin-cli stop' SIGTERM

exec monacoind "$@"
