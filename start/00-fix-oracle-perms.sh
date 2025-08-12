#!/bin/bash

echo "[fix] Configurando permissões e diretórios Oracle..."

CURRENT_USER=$(id -u)
echo "[fix] Script executando como UID: $CURRENT_USER"

# Verifica se estamos executando em Railway.com
if [ -n "$RAILWAY_ENVIRONMENT" ] || [ -n "$RAILWAY_SERVICE_NAME" ]; then
    echo "[fix] Detectado ambiente Railway.com - usando estratégias específicas"
    RAILWAY_ENV=true
else
    RAILWAY_ENV=false
fi

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
    if $RAILWAY_ENV; then
        echo "[fix] Railway.com: Tentando continuar sem volume montado..."
    else
        exit 1
    fi
fi

echo "[fix] Volume encontrado - verificando permissões e propriedades..."
ls -la /opt/oracle/oradata/ || echo "[fix] Não foi possível listar o diretório"
df -h /opt/oracle/oradata || echo "[fix] Não foi possível verificar informações do filesystem"
mount | grep oradata || echo "[fix] Não foi possível encontrar informações de montagem"

# Função robusta para criar diretórios com fallbacks para Railway.com
create_oracle_dir() {
    local dir="$1"
    local description="$2"
    
    echo "[fix] Criando diretório $description: $dir"
    
    # Se o diretório já existe, apenas corrige permissões
    if [ -d "$dir" ]; then
        echo "[fix] Diretório $dir já existe"
        fix_perms "$dir"
        return 0
    fi
    
    # Estratégia 1: mkdir normal
    if mkdir -p "$dir" 2>/dev/null; then
        echo "[fix] ✓ Diretório criado com sucesso: $dir"
        fix_perms "$dir"
        return 0
    fi
    
    # Estratégia 2: mkdir com sudo
    if [ "$CURRENT_USER" != "0" ] && sudo -n mkdir -p "$dir" 2>/dev/null; then
        echo "[fix] ✓ Diretório criado com sudo: $dir"
        fix_perms "$dir"
        return 0
    fi
    
    # Estratégia 3: Para Railway.com, tenta criar como root primeiro
    if $RAILWAY_ENV && [ "$CURRENT_USER" != "0" ]; then
        echo "[fix] Railway.com: Tentando criar como root..."
        if sudo su -c "mkdir -p '$dir' && chown 54321:54321 '$dir' && chmod 755 '$dir'" 2>/dev/null; then
            echo "[fix] ✓ Diretório criado via root no Railway.com: $dir"
            return 0
        fi
    fi
    
    # Estratégia 4: Tenta mudando temporariamente para root
    if [ "$CURRENT_USER" != "0" ] && sudo -n su - root -c "mkdir -p '$dir'" 2>/dev/null; then
        echo "[fix] ✓ Diretório criado mudando para root: $dir"
        fix_perms "$dir"
        return 0
    fi
    
    echo "[fix] ✗ FALHA: Não foi possível criar $dir - continuando..."
    return 1
}

# Função para corrigir permissões com tratamento de erros melhorado
fix_perms() {
    local dir="$1"
    echo "[fix] Corrigindo permissões de: $dir"
    
    # Verifica se o diretório existe
    if [ ! -d "$dir" ]; then
        echo "[fix] Aviso: Diretório não existe: $dir"
        return 1
    fi
    
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
    
    return 0
}

# Corrige permissões do volume raiz
echo "[fix] Corrigindo permissões do volume raiz..."
fix_perms "/opt/oracle/oradata"

# Cria estrutura de diretórios Oracle correta
echo "[fix] Criando estrutura de diretórios Oracle..."

# Diretório principal FREE (Container Database)
create_oracle_dir "/opt/oracle/oradata/FREE" "FREE (CDB)"

# Diretório FREEPDB1 dentro de FREE (Pluggable Database)
create_oracle_dir "/opt/oracle/oradata/FREE/FREEPDB1" "FREE/FREEPDB1 (PDB)"

# Diretório pdbseed dentro de FREE (PDB Seed)
create_oracle_dir "/opt/oracle/oradata/FREE/pdbseed" "FREE/pdbseed (PDB Seed)"

# Cria diretórios adicionais necessários para o Oracle
ORACLE_DIRS=(
    "/opt/oracle/oradata/FREE/controlfile:Arquivos de controle"
    "/opt/oracle/oradata/FREE/onlinelog:Logs online"
    "/opt/oracle/oradata/FREE/temp:Arquivos temporários"
)

echo "[fix] Criando diretórios adicionais do Oracle..."
for oracle_dir_info in "${ORACLE_DIRS[@]}"; do
    IFS=':' read -r oracle_dir description <<< "$oracle_dir_info"
    create_oracle_dir "$oracle_dir" "$description"
done

# Verifica resultado final
echo "[fix] Estrutura final de diretórios:"
find /opt/oracle/oradata -type d -exec ls -ld {} \; 2>/dev/null || true

echo "[fix] Script de permissões concluído com sucesso!"