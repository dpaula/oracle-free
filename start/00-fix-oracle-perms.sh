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

# Função para corrigir permissões com tratamento de erros melhorado
fix_perms() {
    local dir="$1"
    echo "[fix] Corrigindo permissões de: $dir"
    
    # Primeiro tenta sem sudo (caso já seja root ou tenha permissões)
    if chown -R 54321:54321 "$dir" 2>/dev/null; then
        echo "[fix] Permissões de propriedade definidas diretamente"
    elif [ "$CURRENT_USER" != "0" ] && sudo -n chown -R 54321:54321 "$dir" 2>/dev/null; then
        echo "[fix] Permissões de propriedade definidas via sudo"
    else
        echo "[fix] Aviso: Não foi possível alterar propriedade, continuando..."
    fi
    
    # Define permissões de diretórios e arquivos
    if find "$dir" -type d -exec chmod 755 {} \; 2>/dev/null; then
        echo "[fix] Permissões de diretórios definidas diretamente"
    elif [ "$CURRENT_USER" != "0" ] && sudo -n find "$dir" -type d -exec chmod 755 {} \; 2>/dev/null; then
        echo "[fix] Permissões de diretórios definidas via sudo"
    else
        echo "[fix] Aviso: Não foi possível alterar permissões de diretórios"
    fi
    
    # Só aplica permissões de arquivo se existirem arquivos
    if [ "$(find "$dir" -type f 2>/dev/null | wc -l)" -gt 0 ]; then
        if find "$dir" -type f -exec chmod 644 {} \; 2>/dev/null; then
            echo "[fix] Permissões de arquivos definidas diretamente"
        elif [ "$CURRENT_USER" != "0" ] && sudo -n find "$dir" -type f -exec chmod 644 {} \; 2>/dev/null; then
            echo "[fix] Permissões de arquivos definidas via sudo"
        else
            echo "[fix] Aviso: Não foi possível alterar permissões de arquivos"
        fi
    fi
}

# Corrige permissões do volume raiz
echo "[fix] Corrigindo permissões do volume raiz..."
fix_perms "/opt/oracle/oradata"

# Cria estrutura de diretórios Oracle correta
echo "[fix] Criando estrutura de diretórios Oracle..."

# Diretório principal FREE (Container Database)
if [ ! -d "/opt/oracle/oradata/FREE" ]; then
    echo "[fix] Criando diretório FREE (CDB)..."
    mkdir -p /opt/oracle/oradata/FREE
    fix_perms "/opt/oracle/oradata/FREE"
fi

# Diretório FREEPDB1 dentro de FREE (Pluggable Database)
if [ ! -d "/opt/oracle/oradata/FREE/FREEPDB1" ]; then
    echo "[fix] Criando diretório FREE/FREEPDB1 (PDB)..."
    mkdir -p /opt/oracle/oradata/FREE/FREEPDB1
    fix_perms "/opt/oracle/oradata/FREE/FREEPDB1"
fi

# Diretório pdbseed dentro de FREE (PDB Seed)
if [ ! -d "/opt/oracle/oradata/FREE/pdbseed" ]; then
    echo "[fix] Criando diretório FREE/pdbseed (PDB Seed)..."
    mkdir -p /opt/oracle/oradata/FREE/pdbseed
    fix_perms "/opt/oracle/oradata/FREE/pdbseed"
fi

# Cria diretórios adicionais necessários para o Oracle
ORACLE_DIRS=(
    "/opt/oracle/oradata/FREE/controlfile"
    "/opt/oracle/oradata/FREE/onlinelog"
    "/opt/oracle/oradata/FREE/temp"
)

for oracle_dir in "${ORACLE_DIRS[@]}"; do
    if [ ! -d "$oracle_dir" ]; then
        echo "[fix] Criando diretório $oracle_dir..."
        mkdir -p "$oracle_dir"
        fix_perms "$oracle_dir"
    fi
done

# Verifica resultado final
echo "[fix] Estrutura final de diretórios:"
find /opt/oracle/oradata -type d -exec ls -ld {} \; 2>/dev/null || true

echo "[fix] Script de permissões concluído com sucesso!"