FROM gvenzl/oracle-free:23.8-slim

# Instala sudo para permitir que o usuário oracle execute comandos privilegiados
USER root
RUN microdnf update -y && microdnf install -y sudo && \
    echo "oracle ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    microdnf clean all

# Cria estrutura completa de diretórios Oracle com permissões robustas
# Isso garante que os diretórios existam independentemente do volume mounting
RUN mkdir -p /opt/oracle/oradata/FREE/FREEPDB1 \
             /opt/oracle/oradata/FREE/pdbseed \
             /opt/oracle/oradata/FREE/controlfile \
             /opt/oracle/oradata/FREE/onlinelog \
             /opt/oracle/oradata/FREE/temp && \
    chown -R 54321:54321 /opt/oracle/oradata && \
    chmod -R 755 /opt/oracle/oradata

# Configura variáveis de ambiente para melhor compatibilidade com Railway.com
ENV ORACLE_CHARACTERSET=AL32UTF8 \
    ORACLE_EDITION=free \
    ORACLE_PDB=FREEPDB1 \
    ORACLE_PWD=Oracle123 \
    ORACLE_DATA=/opt/oracle/oradata

# Copia scripts de inicialização (ordem alfabética garante execução sequencial)
# 1. Script pré-inicialização para garantir diretórios (executa primeiro)
COPY --chmod=0755 start/00-ensure-oracle-dirs.sh /container-entrypoint-initdb.d/00-ensure-oracle-dirs.sh
# 2. Script de permissões (executa segundo)
COPY --chmod=0755 start/00-fix-oracle-perms.sh /container-entrypoint-initdb.d/01-fix-oracle-perms.sh
# 3. Scripts de inicialização de usuários
COPY init/ /container-entrypoint-initdb.d/
# 4. Scripts que executam após inicialização da DB
COPY --chmod=0755 start/01-open-pdb.sql /container-entrypoint-startdb.d/

# Volta para o usuário oracle
USER 54321

# Expõe a porta
EXPOSE 1521