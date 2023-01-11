#!/usr/bin/env bash
# This file replaces the original entrypoint and allows us to run from the /tmp directory which is the only writeable directory.

# Copy the main tor execuable to /tmp
cp /usr/bin/torproxy.sh /tmp/torproxy.sh

# Execute the original entrypoint from the new tmp location
/sbin/tini -s -- /tmp/torproxy.sh


