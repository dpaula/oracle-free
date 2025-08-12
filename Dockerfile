FROM gvenzl/oracle-free:23.8-slim

# Instala sudo para permitir que o usuário oracle execute comandos privilegiados
USER root
RUN microdnf update -y && microdnf install -y sudo && \
    echo "oracle ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    microdnf clean all

# Cria o diretório de dados e configura permissões básicas
RUN mkdir -p /opt/oracle/oradata && \
    chown -R 54321:54321 /opt/oracle/oradata && \
    chmod -R 755 /opt/oracle/oradata

# Copia scripts de inicialização
COPY --chmod=0755 start/ /container-entrypoint-startdb.d/
COPY init/ /container-entrypoint-initdb.d/

# Volta para o usuário oracle
USER 54321

# Expõe a porta
EXPOSE 1521