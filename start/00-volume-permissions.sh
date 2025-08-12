#!/bin/bash
set -e

echo "[volume] Configurando permissões do volume Railway..."

# Este script roda como o primeiro para corrigir permissões do volume
# antes de qualquer inicialização do Oracle

ORACLE_DATA_DIR="/opt/oracle/oradata"
CURRENT_USER=$(id -u)

echo "[volume] UID atual: $CURRENT_USER"
echo "[volume] Verificando volume em: $ORACLE_DATA_DIR"

# Se o diretório existe (volume montado)
if [ -d "$ORACLE_DATA_DIR" ]; then
    echo "[volume] Volume detectado - verificando permissões..."

    # Lista as permissões atuais
    ls -la "$ORACLE_DATA_DIR" || true

    # Se rodando como root, corrige as permissões
    if [ "$CURRENT_USER" = "0" ]; then
        echo "[volume] Executando como root - corrigindo permissões..."

        # Garante que oracle (54321) seja dono de tudo no volume
        chown -R 54321:54321 "$ORACLE_DATA_DIR"

        # Corrige permissões de diretórios e arquivos
        find "$ORACLE_DATA_DIR" -type d -exec chmod 755 {} \; 2>/dev/null || true
        find "$ORACLE_DATA_DIR" -type f -exec chmod 644 {} \; 2>/dev/null || true

        # Para arquivos específicos do Oracle que precisam de permissões especiais
        find "$ORACLE_DATA_DIR" -name "*.ctl" -exec chmod 644 {} \; 2>/dev/null || true
        find "$ORACLE_DATA_DIR" -name "*.dbf" -exec chmod 644 {} \; 2>/dev/null || true
        find "$ORACLE_DATA_DIR" -name "*.log" -exec chmod 644 {} \; 2>/dev/null || true

        echo "[volume] Permissões do volume corrigidas!"

        # Verifica as permissões após correção
        echo "[volume] Permissões após correção:"
        ls -la "$ORACLE_DATA_DIR" || true

    else
        echo "[volume] Não é root - não pode alterar permissões"
        echo "[volume] Permissões atuais:"
        ls -la "$ORACLE_DATA_DIR" || true
    fi
else
    echo "[volume] Diretório $ORACLE_DATA_DIR não existe - criando..."
    mkdir -p "$ORACLE_DATA_DIR" 2>/dev/null || true

    if [ "$CURRENT_USER" = "0" ]; then
        chown -R 54321:54321 "$ORACLE_DATA_DIR" 2>/dev/null || true
    fi
fi

echo "[volume] Script de volume concluído!"