# Banco de Dados Oracle Free - Guia de Deploy para Railway.com

## Problema Resolvido
O Dockerfile original estava usando comandos `apt-get`, que não funcionam em contêineres baseados no Oracle Linux. Isso foi corrigido substituindo pelos comandos `microdnf`.

## Variáveis de Ambiente para Railway.com
Configure estas variáveis de ambiente no seu serviço Railway.com:

```
ORACLE_PASSWORD=ChangeMe123!
APP_USER=IMASTER
APP_USER_PASSWORD=IMaster
ORACLE_CHARACTERSET=AL32UTF8
TZ=America/Sao_Paulo
```

## Configuração de Volume
Monte o volume em: `/opt/oracle/oradata`

**Importante para Railway.com**: O volume será montado com permissões específicas do Railway.com. O script de inicialização irá automaticamente:
- Detectar o ambiente Railway.com e usar estratégias específicas de criação de diretórios
- Criar a estrutura correta de diretórios Oracle (`FREE/FREEPDB1`, `FREE/pdbseed`)
- Configurar as permissões adequadas para o usuário Oracle (UID 54321)
- Aguardar até 60 segundos para o volume estar disponível
- Usar múltiplas estratégias de fallback para lidar com restrições de permissão

## Solução de Problemas Railway.com

Se você encontrar erros de permissão como "Permission denied" ou "Cannot create folder", o script implementa as seguintes estratégias automaticamente:

1. **Detecção automática**: O script detecta se está executando no Railway.com
2. **Diagnósticos detalhados**: Verifica propriedades do filesystem e montagem do volume
3. **Múltiplas estratégias de criação**:
   - Criação normal de diretório
   - Criação com sudo
   - Criação específica para Railway.com via root
   - Escalação temporária para root
4. **Continuação resiliente**: O script continua mesmo se algumas operações falharem
5. **Logging detalhado**: Fornece informações completas sobre cada tentativa

Os logs mostrarão mensagens como:
- `[fix] Detectado ambiente Railway.com - usando estratégias específicas`
- `[fix] ✓ Diretório criado com sucesso` ou `[fix] ✗ FALHA: Não foi possível criar`

## O que a Configuração Faz

1. **Imagem Base**: Usa `gvenzl/oracle-free:23.8-slim` (baseada no Oracle Linux)
2. **Permissões**: Instala sudo e configura as permissões adequadas do usuário Oracle
3. **Scripts de Inicialização**: 
   - `00-fix-oracle-perms.sh`: Configura permissões de volume e diretórios
   - `01-open-pdb.sql`: Abre bancos de dados plugáveis e configura o listener
4. **Inicialização**: 
   - `01-imaster-grants.sql`: Cria usuário IMASTER com privilégios DBA no FREEPDB1

## Detalhes da Conexão
- **Host**: Sua URL atribuída pelo Railway.com
- **Porta**: 1521
- **Nome do Serviço**: FREEPDB1
- **Nome de Usuário**: IMASTER
- **Senha**: IMaster
- **Nome de Usuário Admin**: SYS
- **Senha Admin**: ChangeMe123!

## Principais Mudanças Realizadas
- Substituído `apt-get` por `microdnf` no Dockerfile
- Todos os scripts já são compatíveis com Oracle Free 23.8
- Tratamento adequado de erros e lógica de criação de usuário
- Gerenciamento de volume e permissões incluído