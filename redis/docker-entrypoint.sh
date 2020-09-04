#!/bin/sh
set -e

chown -R redis:redis /usr/local/etc/redis

# The following two lines disable THP support.
echo "never" > /sys/kernel/mm/transparent_hugepage/enabled
echo "never" > /sys/kernel/mm/transparent_hugepage/defrag

redis-server /usr/local/etc/redis/redis.conf