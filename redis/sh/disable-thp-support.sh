#!/bin/sh
set -e

# The following two lines disable THP support.
echo "never" > /sys/kernel/mm/transparent_hugepage/enabled
echo "never" > /sys/kernel/mm/transparent_hugepage/defrag