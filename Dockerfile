FROM gvenzl/oracle-free:23.8-slim

# scripts que rodam a cada start
COPY --chmod=0755 start/ /container-entrypoint-startdb.d/
# scripts que rodam só na 1ª inicialização
COPY init/ /container-entrypoint-initdb.d/