FROM gvenzl/oracle-free:23.8-slim

# scripts que rodam a cada start
COPY start/ /container-entrypoint-startdb.d/
# scripts que rodam só na 1ª inicialização
COPY init/  /container-entrypoint-initdb.d/

# garante permissão de execução nos .sh
RUN chmod +x /container-entrypoint-startdb.d/*.sh