#!/bin/bash
set -e

echo "[fix] Configurando permissões e diretórios Oracle..."

CURRENT_USER=$(id -u)
echo "[fix] Script executando como UID: $CURRENT_USER"

# Aguarda o volume estar disponível
echo "[fix] Aguardando volume estar disponível..."
for i in {1..30}; do
    if [ -d "/opt/oracle/oradata" ]; then
        echo "[fix] Volume encontrado após $i tentativas"
        break
    fi
    echo "[fix] Tentativa $i/30 - aguardando volume..."
    sleep 2
done

# Verifica se o volume está disponível
if [ ! -d "/opt/oracle/oradata" ]; then
    echo "[fix] ERRO: Volume não encontrado após 60 segundos!"
    exit 1
fi

echo "[fix] Volume encontrado - verificando permissões..."
ls -la /opt/oracle/oradata/ || true

# Função para corrigir permissões
fix_perms() {
    local dir="$1"
    echo "[fix] Corrigindo permissões de: $dir"

    if [ "$CURRENT_USER" = "0" ]; then
        # Como root
        chown -R 54321:54321 "$dir"
        find "$dir" -type d -exec chmod 755 {} \;
        find "$dir" -type f -exec chmod 644 {} \;
    else
        # Como usuário oracle com sudo
        sudo chown -R 54321:54321 "$dir"
        sudo find "$dir" -type d -exec chmod 755 {} \;
        sudo find "$dir" -type f -exec chmod 644 {} \;
    fi
}

# Corrige permissões dos diretórios principais
echo "[fix] Corrigindo permissões do volume..."
fix_perms "/opt/oracle/oradata"

# Cria subdiretórios se não existirem
if [ ! -d "/opt/oracle/oradata/FREE" ]; then
    echo "[fix] Criando diretório FREE..."
    mkdir -p /opt/oracle/oradata/FREE
    fix_perms "/opt/oracle/oradata/FREE"
fi

if [ ! -d "/opt/oracle/oradata/FREEPDB1" ]; then
    echo "[fix] Criando diretório FREEPDB1..."
    mkdir -p /opt/oracle/oradata/FREEPDB1
    fix_perms "/opt/oracle/oradata/FREEPDB1"
fi

# Verifica resultado final
echo "[fix] Permissões após correção:"
ls -la /opt/oracle/oradata/ || true

echo "[fix] Script de permissões concluído com sucesso!"