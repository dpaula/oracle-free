#!/usr/bin/env bash
set -euo pipefail

# UID/GID do usuário 'oracle' na imagem do gvenzl
ORACLE_UID=54321
ORACLE_GID=54321

# Garante diretórios e perms ANTES do Oracle iniciar
mkdir -p /opt/oracle/oradata /opt/oracle/diag
chown -R ${ORACLE_UID}:${ORACLE_GID} /opt/oracle/oradata /opt/oracle/diag || true

# volta a rodar como 'oracle' (uid 54321) e delega pro entrypoint oficial
# 'su' está disponível e root pode trocar sem senha
exec su -s /bin/bash -c "/container-entrypoint.sh" - ${ORACLE_UID}