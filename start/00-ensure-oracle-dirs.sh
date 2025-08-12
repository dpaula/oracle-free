#!/bin/bash

echo "[pre-init] Garantindo estrutura de diretórios Oracle antes da inicialização..."

# Executa como root se necessário para criar diretórios
if [ "$(id -u)" != "0" ] && command -v sudo >/dev/null 2>&1; then
    echo "[pre-init] Executando como usuário não-root, usando sudo quando necessário"
    SUDO_CMD="sudo"
else
    echo "[pre-init] Executando como root ou sudo não disponível"
    SUDO_CMD=""
fi

# Função para criar diretórios de forma robusta
ensure_dir() {
    local dir="$1"
    echo "[pre-init] Garantindo existência do diretório: $dir"
    
    if [ -d "$dir" ]; then
        echo "[pre-init] ✓ Diretório já existe: $dir"
    else
        if mkdir -p "$dir" 2>/dev/null || $SUDO_CMD mkdir -p "$dir" 2>/dev/null; then
            echo "[pre-init] ✓ Diretório criado: $dir"
        else
            echo "[pre-init] ✗ ERRO: Falha ao criar diretório: $dir"
            return 1
        fi
    fi
    
    # Garante permissões corretas
    if $SUDO_CMD chown 54321:54321 "$dir" 2>/dev/null; then
        echo "[pre-init] ✓ Propriedade definida para oracle (54321:54321): $dir"
    else
        echo "[pre-init] ! Aviso: Não foi possível definir propriedade: $dir"
    fi
    
    if $SUDO_CMD chmod 755 "$dir" 2>/dev/null; then
        echo "[pre-init] ✓ Permissões definidas (755): $dir"
    else
        echo "[pre-init] ! Aviso: Não foi possível definir permissões: $dir"
    fi
    
    return 0
}

# Lista de todos os diretórios necessários para o Oracle
ORACLE_DIRS=(
    "/opt/oracle/oradata"
    "/opt/oracle/oradata/FREE"
    "/opt/oracle/oradata/FREE/FREEPDB1"
    "/opt/oracle/oradata/FREE/pdbseed"
    "/opt/oracle/oradata/FREE/controlfile"
    "/opt/oracle/oradata/FREE/onlinelog"
    "/opt/oracle/oradata/FREE/temp"
)

echo "[pre-init] Criando estrutura completa de diretórios Oracle..."

# Cria todos os diretórios necessários
for oracle_dir in "${ORACLE_DIRS[@]}"; do
    ensure_dir "$oracle_dir"
done

# Verifica se o volume está montado corretamente
echo "[pre-init] Verificando estado do volume Oracle..."
ls -la /opt/oracle/oradata/ 2>/dev/null || echo "[pre-init] Aviso: Não foi possível listar o diretório de dados"

# Verifica espaço disponível
df -h /opt/oracle/oradata 2>/dev/null || echo "[pre-init] Aviso: Não foi possível verificar espaço em disco"

echo "[pre-init] Estrutura de diretórios Oracle preparada com sucesso!"

# Mostra a estrutura final
echo "[pre-init] Estrutura final de diretórios:"
find /opt/oracle/oradata -type d -exec ls -ld {} \; 2>/dev/null | head -20 || echo "[pre-init] Não foi possível mostrar estrutura completa"

exit 0