#!/bin/bash

echo "[pre-init] Garantindo estrutura de diretórios Oracle após montagem de volume..."

# Detecta se estamos em Railway.com
if [ -n "$RAILWAY_ENVIRONMENT" ] || [ -n "$RAILWAY_SERVICE_NAME" ]; then
    echo "[pre-init] Detectado ambiente Railway.com - aguardando volume ser montado..."
    RAILWAY_ENV=true
else
    echo "[pre-init] Ambiente local detectado"
    RAILWAY_ENV=false
fi

# Executa como root se necessário para criar diretórios
if [ "$(id -u)" != "0" ] && command -v sudo >/dev/null 2>&1; then
    echo "[pre-init] Executando como usuário não-root, usando sudo quando necessário"
    SUDO_CMD="sudo"
else
    echo "[pre-init] Executando como root ou sudo não disponível"
    SUDO_CMD=""
fi

# Aguarda o volume estar disponível (crítico para Railway.com)
echo "[pre-init] Aguardando volume /opt/oracle/oradata estar disponível..."
for i in {1..60}; do
    if [ -d "/opt/oracle/oradata" ] && [ -w "/opt/oracle/oradata" 2>/dev/null ] || $SUDO_CMD test -w "/opt/oracle/oradata" 2>/dev/null; then
        echo "[pre-init] Volume disponível e gravável após $i tentativas"
        break
    elif [ -d "/opt/oracle/oradata" ]; then
        echo "[pre-init] Volume existe mas não é gravável, tentando corrigir permissões..."
        $SUDO_CMD chown -R 54321:54321 "/opt/oracle/oradata" 2>/dev/null || true
        $SUDO_CMD chmod -R 755 "/opt/oracle/oradata" 2>/dev/null || true
    fi
    echo "[pre-init] Tentativa $i/60 - aguardando volume estar pronto..."
    sleep 2
done

# Verifica se conseguiu acesso ao volume
if [ ! -d "/opt/oracle/oradata" ]; then
    echo "[pre-init] ERRO: Volume não encontrado após 2 minutos!"
    if $RAILWAY_ENV; then
        echo "[pre-init] Railway.com: Tentando criar volume manualmente..."
        $SUDO_CMD mkdir -p "/opt/oracle/oradata" || {
            echo "[pre-init] ERRO CRÍTICO: Impossível criar diretório de dados!"
            exit 1
        }
    else
        exit 1
    fi
fi

# Função para criar diretórios de forma robusta com múltiplas tentativas
ensure_dir() {
    local dir="$1"
    local max_attempts=5
    local attempt=0
    
    echo "[pre-init] Garantindo existência do diretório: $dir"
    
    while [ $attempt -lt $max_attempts ]; do
        attempt=$((attempt + 1))
        
        if [ -d "$dir" ]; then
            echo "[pre-init] ✓ Diretório já existe: $dir (tentativa $attempt)"
            break
        fi
        
        # Tenta criar o diretório
        if mkdir -p "$dir" 2>/dev/null; then
            echo "[pre-init] ✓ Diretório criado diretamente: $dir (tentativa $attempt)"
            break
        elif $SUDO_CMD mkdir -p "$dir" 2>/dev/null; then
            echo "[pre-init] ✓ Diretório criado com sudo: $dir (tentativa $attempt)"
            break
        else
            echo "[pre-init] ✗ Falha na tentativa $attempt/$max_attempts para criar: $dir"
            if [ $attempt -lt $max_attempts ]; then
                echo "[pre-init] Aguardando 2 segundos antes da próxima tentativa..."
                sleep 2
            fi
        fi
    done
    
    # Verifica se o diretório foi criado com sucesso
    if [ ! -d "$dir" ]; then
        echo "[pre-init] ✗ ERRO CRÍTICO: Não foi possível criar diretório após $max_attempts tentativas: $dir"
        return 1
    fi
    
    # Garante permissões corretas com múltiplas tentativas
    local perm_attempts=3
    local perm_attempt=0
    
    while [ $perm_attempt -lt $perm_attempts ]; do
        perm_attempt=$((perm_attempt + 1))
        
        if $SUDO_CMD chown 54321:54321 "$dir" 2>/dev/null; then
            echo "[pre-init] ✓ Propriedade definida para oracle (54321:54321): $dir"
            break
        else
            echo "[pre-init] ! Tentativa $perm_attempt/$perm_attempts falhou ao definir propriedade: $dir"
            [ $perm_attempt -lt $perm_attempts ] && sleep 1
        fi
    done
    
    perm_attempt=0
    while [ $perm_attempt -lt $perm_attempts ]; do
        perm_attempt=$((perm_attempt + 1))
        
        if $SUDO_CMD chmod 755 "$dir" 2>/dev/null; then
            echo "[pre-init] ✓ Permissões definidas (755): $dir"
            break
        else
            echo "[pre-init] ! Tentativa $perm_attempt/$perm_attempts falhou ao definir permissões: $dir"
            [ $perm_attempt -lt $perm_attempts ] && sleep 1
        fi
    done
    
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

# Validação do ambiente Oracle - verifica se SQL*Plus pode ser executado
echo "[pre-init] Validando configuração do ambiente Oracle..."
echo "[pre-init] ORACLE_HOME = $ORACLE_HOME"
echo "[pre-init] PATH = $PATH"
echo "[pre-init] LD_LIBRARY_PATH = $LD_LIBRARY_PATH"

# Verifica se ORACLE_HOME está definido
if [ -z "$ORACLE_HOME" ]; then
    echo "[pre-init] ✗ ERRO: ORACLE_HOME não está definido!"
else
    echo "[pre-init] ✓ ORACLE_HOME está definido: $ORACLE_HOME"
    
    # Verifica se o diretório ORACLE_HOME existe
    if [ -d "$ORACLE_HOME" ]; then
        echo "[pre-init] ✓ Diretório ORACLE_HOME existe"
    else
        echo "[pre-init] ! Aviso: Diretório ORACLE_HOME não existe ainda: $ORACLE_HOME"
    fi
fi

# Verifica se sqlplus está no PATH
if command -v sqlplus >/dev/null 2>&1; then
    echo "[pre-init] ✓ sqlplus encontrado no PATH"
    # Testa se sqlplus pode executar sem erro de biblioteca
    if echo "exit" | sqlplus -V >/dev/null 2>&1; then
        echo "[pre-init] ✓ sqlplus pode executar corretamente"
    else
        echo "[pre-init] ! sqlplus encontrado mas pode ter problemas de biblioteca"
    fi
else
    echo "[pre-init] ! sqlplus não encontrado no PATH - será definido durante inicialização do Oracle"
fi

# Validação final crítica - verifica se todos os diretórios essenciais existem
echo "[pre-init] Executando validação final da estrutura de diretórios..."

# Lista de diretórios críticos que devem existir
CRITICAL_DIRS=(
    "/opt/oracle/oradata/FREE"
    "/opt/oracle/oradata/FREE/FREEPDB1"
    "/opt/oracle/oradata/FREE/pdbseed"
)

validation_failed=false
for critical_dir in "${CRITICAL_DIRS[@]}"; do
    if [ ! -d "$critical_dir" ]; then
        echo "[pre-init] ✗ ERRO CRÍTICO: Diretório essencial não existe: $critical_dir"
        validation_failed=true
    else
        # Verifica se o diretório é gravável
        if [ -w "$critical_dir" ] || $SUDO_CMD test -w "$critical_dir" 2>/dev/null; then
            echo "[pre-init] ✓ Diretório crítico OK: $critical_dir"
        else
            echo "[pre-init] ✗ ERRO CRÍTICO: Diretório não gravável: $critical_dir"
            validation_failed=true
        fi
    fi
done

if [ "$validation_failed" = true ]; then
    echo "[pre-init] ✗ FALHA NA VALIDAÇÃO: Estrutura de diretórios incompleta!"
    echo "[pre-init] Oracle não poderá inicializar corretamente. Abortando..."
    exit 1
fi

# Mostra a estrutura final
echo "[pre-init] ✓ VALIDAÇÃO CONCLUÍDA: Todos os diretórios críticos estão prontos!"
echo "[pre-init] Estrutura final de diretórios:"
find /opt/oracle/oradata -type d -exec ls -ld {} \; 2>/dev/null | head -20 || echo "[pre-init] Estrutura básica criada"

# Criação de arquivo de sinalização para indicar que a preparação foi concluída
echo "[pre-init] Criando arquivo de sinalização..."
echo "$(date): Diretórios Oracle preparados com sucesso pelo script 00-ensure-oracle-dirs.sh" | $SUDO_CMD tee /opt/oracle/oradata/.dirs-ready 2>/dev/null || true

echo "[pre-init] ✓ SUCESSO: Estrutura de diretórios Oracle preparada e validada!"
echo "[pre-init] Oracle pode agora inicializar com segurança."

exit 0