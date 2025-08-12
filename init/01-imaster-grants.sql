WHENEVER SQLERROR EXIT SQL.SQLCODE;

-- Verifica se estamos no contexto correto
SELECT sys_context('USERENV', 'CON_NAME') as CONTAINER FROM dual;

-- Muda para a PDB
ALTER SESSION SET CONTAINER = FREEPDB1;

-- Verifica novamente o container
SELECT sys_context('USERENV', 'CON_NAME') as CONTAINER FROM dual;

-- Cria o usuário se não existir (com tratamento de erro)
DECLARE
user_exists NUMBER;
BEGIN
SELECT COUNT(*) INTO user_exists FROM dba_users WHERE username = 'IMASTER';

IF user_exists = 0 THEN
        EXECUTE IMMEDIATE 'CREATE USER IMASTER IDENTIFIED BY "IMaster"';
        DBMS_OUTPUT.PUT_LINE('Usuário IMASTER criado com sucesso');
ELSE
        DBMS_OUTPUT.PUT_LINE('Usuário IMASTER já existe');
END IF;
END;
/

-- Concede privilégios DBA ao usuário
GRANT DBA TO IMASTER;

-- Define quota ilimitada no tablespace USERS
ALTER USER IMASTER QUOTA UNLIMITED ON USERS;

-- Permite conexão
GRANT CREATE SESSION TO IMASTER;
GRANT CONNECT TO IMASTER;
GRANT RESOURCE TO IMASTER;

-- Verifica se o usuário foi criado corretamente
SELECT username, account_status, default_tablespace FROM dba_users WHERE username = 'IMASTER';

COMMIT;