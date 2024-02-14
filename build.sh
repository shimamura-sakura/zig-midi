#!/bin/sh

set -ue

zig build-exe -fsingle-threaded main.zig "$@"
