FROM gvenzl/oracle-free:23.9-slim

# nosso entrypoint que corrige perms antes do Oracle subir
COPY railway-entrypoint.sh /usr/local/bin/railway-entrypoint.sh
RUN chmod 0755 /usr/local/bin/railway-entrypoint.sh

# seus scripts de init (primeira criação) e start (pós-boot)
COPY init/  /container-entrypoint-initdb.d/
COPY start/ /container-entrypoint-startdb.d/

# rodar como root para poder chown/chmod e depois cair pro usuário correto
USER 0
ENTRYPOINT ["/usr/local/bin/railway-entrypoint.sh"]