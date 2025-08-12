#!/bin/bash
set -e

echo "[fix] Configurando permissões e diretórios Oracle..."

# Verifica se está rodando como root (necessário para mudanças de permissão)
if [ "$(id -u)" != "0" ]; then
    echo "[fix] Script deve rodar como root para configurar permissões"
    exit 1
fi

# Cria diretórios necessários se não existirem
mkdir -p /opt/oracle/oradata/FREE
mkdir -p /opt/oracle/oradata/FREEPDB1
mkdir -p /opt/oracle/diag
mkdir -p /opt/oracle/admin
mkdir -p /opt/oracle/audit

# Define permissões corretas (54321 é o UID do usuário oracle)
echo "[fix] Aplicando ownership para usuário oracle (54321:54321)..."
chown -R 54321:54321 /opt/oracle/oradata
chown -R 54321:54321 /opt/oracle/diag
chown -R 54321:54321 /opt/oracle/admin
chown -R 54321:54321 /opt/oracle/audit

# Define permissões de diretório
chmod -R 755 /opt/oracle/oradata
chmod -R 755 /opt/oracle/diag

echo "[fix] Permissões configuradas com sucesso!"