FROM gvenzl/oracle-free:23.8-slim

# roda em TODO start: abre PDB, salva estado e registra listener
COPY start/00-open-pdb.sql /container-entrypoint-startdb.d/00-open-pdb.sql

# roda só na PRIMEIRA inicialização (depois que o APP_USER existir)
COPY init/01-imaster-grants.sql /container-entrypoint-initdb.d/01-imaster-grants.sql