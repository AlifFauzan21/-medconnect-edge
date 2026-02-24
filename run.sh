#!/bin/bash
set -e
cd "$(dirname "$0")"
exec "./venv/bin/$1" "${@:2}"
