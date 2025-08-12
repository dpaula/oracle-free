WHENEVER SQLERROR EXIT SQL.SQLCODE;

-- Aguarda um pouco para garantir que o CDB esteja totalmente inicializado
EXEC DBMS_LOCK.SLEEP(5);

-- Verifica se estamos conectados ao CDB
SELECT name, cdb FROM v$database;

-- Abre todas as PDBs
ALTER PLUGGABLE DATABASE ALL OPEN;

-- Salva o estado da FREEPDB1 para abrir automaticamente no boot
ALTER PLUGGABLE DATABASE FREEPDB1 SAVE STATE;

-- Configura o listener para aceitar conexões externas
-- Usando 0.0.0.0 para aceitar de qualquer interface
ALTER SYSTEM SET LOCAL_LISTENER='(ADDRESS=(PROTOCOL=TCP)(HOST=0.0.0.0)(PORT=1521))' SCOPE=BOTH;

-- Força re-registro dos serviços no listener
ALTER SYSTEM REGISTER;

-- Aguarda um pouco para o registro ser efetivado
EXEC DBMS_LOCK.SLEEP(2);

-- Verifica os serviços registrados
SELECT name, value FROM v$parameter WHERE name = 'local_listener';

COMMIT;