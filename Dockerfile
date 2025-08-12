FROM gvenzl/oracle-free:23.8-slim
COPY --chmod=0755 start/ /container-entrypoint-startdb.d/
COPY init/ /container-entrypoint-initdb.d/