FROM gvenzl/oracle-free:23.8-slim

# Copia scripts de inicialização com permissões corretas
COPY --chmod=0755 start/ /container-entrypoint-startdb.d/
COPY init/ /container-entrypoint-initdb.d/

# Garante que o usuário oracle seja o dono dos diretórios
USER root
RUN mkdir -p /opt/oracle/oradata/FREE /opt/oracle/oradata/FREEPDB1 /opt/oracle/diag && \
    chown -R 54321:54321 /opt/oracle/oradata /opt/oracle/diag

# Volta para o usuário oracle
USER 54321

# Expõe a porta padrão do Oracle
EXPOSE 1521

# Define healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=5m --retries=3 \
  CMD /opt/oracle/product/23ai/dbhomeFree/bin/sqlplus -s sys/$$ORACLE_PASSWORD@localhost:1521/FREE as sysdba <<< "SELECT 1 FROM DUAL;" || exit 1