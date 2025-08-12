FROM gvenzl/oracle-free:23.8-slim

# Copia scripts de inicialização com permissões corretas
COPY --chmod=0755 start/ /container-entrypoint-startdb.d/
COPY init/ /container-entrypoint-initdb.d/

# Remove o USER - o script de permissões vai lidar com isso durante runtime

# Expõe a porta padrão do Oracle
EXPOSE 1521

# Define healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=5m --retries=3 \
  CMD /opt/oracle/product/23ai/dbhomeFree/bin/sqlplus -s sys/$$ORACLE_PASSWORD@localhost:1521/FREE as sysdba <<< "SELECT 1 FROM DUAL;" || exit 1