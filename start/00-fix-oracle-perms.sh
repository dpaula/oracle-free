#!/bin/sh
set -e
echo "[fix] ensuring oracle dirs ownership to 54321"
# garante pastas
mkdir -p /opt/oracle/oradata/FREE /opt/oracle/oradata/FREEPDB1
mkdir -p /opt/oracle/diag
# aplica dono correto (db files + diag/log do listener)
chown -R 54321:54321 /opt/oracle/oradata /opt/oracle/diag