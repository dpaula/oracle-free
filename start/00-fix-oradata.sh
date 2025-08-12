#!/bin/sh
set -e
# garante as pastas esperadas e o owner correto
mkdir -p /opt/oracle/oradata/FREE /opt/oracle/oradata/FREEPDB1
chown -R 54321:54321 /opt/oracle/oradata