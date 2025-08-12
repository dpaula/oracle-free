#!/bin/sh
set -e
# cria as pastas que o DB espera e ajusta dono para o usuário 'oracle' (UID=54321)
mkdir -p /opt/oracle/oradata/FREE /opt/oracle/oradata/FREEPDB1
chown -R 54321:54321 /opt/oracle/oradata