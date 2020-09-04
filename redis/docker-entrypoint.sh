#!/bin/sh
set -e

chown -R redis:redis /usr/local/etc/redis
chown -R redis:redis /var/local/redis/backups

redis-server /usr/local/etc/redis/redis.conf