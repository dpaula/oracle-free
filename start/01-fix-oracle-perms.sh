#!/bin/bash
set -e

echo "[fix] Configurando permissões e diretórios Oracle..."

# Este script roda ANTES do Oracle iniciar, então temos que garantir permissões corretas
# no volume montado

# Verifica qual usuário está executando
CURRENT_USER=$(id -u)
echo "[fix] Script executando como UID: $CURRENT_USER"

# Se estivermos como root, podemos configurar as permissões
if [ "$CURRENT_USER" = "0" ]; then
    echo "[fix] Executando como root - configurando permissões..."

    # Cria todos os diretórios necessários
    mkdir -p /opt/oracle/oradata/FREE
    mkdir -p /opt/oracle/oradata/FREEPDB1
    mkdir -p /opt/oracle/diag
    mkdir -p /opt/oracle/admin
    mkdir -p /opt/oracle/audit

    # Se o volume foi montado e já tem arquivos, corrige as permissões
    if [ -d "/opt/oracle/oradata" ]; then
        echo "[fix] Corrigindo permissões do volume montado..."
        chown -R 54321:54321 /opt/oracle/oradata
        find /opt/oracle/oradata -type d -exec chmod 755 {} \;
        find /opt/oracle/oradata -type f -exec chmod 644 {} \;
    fi

    # Outros diretórios Oracle
    chown -R 54321:54321 /opt/oracle/diag
    chown -R 54321:54321 /opt/oracle/admin 2>/dev/null || true
    chown -R 54321:54321 /opt/oracle/audit 2>/dev/null || true

    echo "[fix] Permissões configuradas com sucesso!"
else
    echo "[fix] Não é root - tentando criar diretórios como usuário $CURRENT_USER..."
    mkdir -p /opt/oracle/oradata/FREE 2>/dev/null || true
    mkdir -p /opt/oracle/oradata/FREEPDB1 2>/dev/null || true
    mkdir -p /opt/oracle/diag 2>/dev/null || true
fi

echo "[fix] Script de permissões concluído!"