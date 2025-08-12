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