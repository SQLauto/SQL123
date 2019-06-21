-- ======================Login Creation======================

-- Create logins on master database.
-- DEFAULT_DATABASE doesn't work on Azure.
-- ALTER LOGIN <login> WITH DEFAULT_DATABASE = [new_default_database]
-- CREATE LOGIN <login name> WITH PASSWORD = <password>
-- CREATE LOGIN <login name> WITH PASSWORD = <password>, DEFAULT_DATABASE = <database-name>
-- DROP LOGIN <login name>

-- ======================User Creation======================
-- Create user on database you want permission to. 
-- CREATE USER <user, normally put 'usr' after login name> FOR LOGIN <login name> WITH DEFAULT_SCHEMA=dbo

-- ======================Role Creation======================
-- Create a role
-- CREATE ROLE <role name> AUTHORIZATION <role owner, can use CURRENT_USER, which is the default if AUTHORIZATION is left off.  I also like setting it to dbo>;
-- ALTER ROLE <role name> ADD MEMBER <role, user, login>;   


-- What you want the user 
-- Complete List: https://docs.microsoft.com/en-us/sql/t-sql/statements/grant-transact-sql?view=sql-server-2017
-- CONNECT, SHOWPLAN, EXECUTE, SELECT, INSERT, UPDATE, DELETE
-- CREATE TABLE, CREATE VIEW, CREATE PROCEDURE, CREATE TYPE, CREATE FUNCTION, CREATE DEFAULT, REFERENCES, CREATE SCHEMA
-- ALTER ON SCHEMA::dbo, ALTER ON SCHEMA::<put schema>
-- VIEW SERVER, STATE VIEW DATABASE STATE
-- EXEC
-- VIEW DEFINITION
-- ALTER
-- ALTER ANY USER
-- SELECT ON <view, table etc> TO

-- Can also use
-- GRANT: Give permission
-- DENY: Deny permission
-- REVOKE: Removed granted permission

-- GRANT <PRIVILEGES>  TO <role, user, login>;
-- GRANT <PRIVILEGES> ON OBJECT::SCHEMA::<The Shema>, <object name like sp and tables> TO <role, user, login>;

 -- Add user/login/role to another role
-- Complete list on what each roles does: https://docs.microsoft.com/en-us/sql/relational-databases/security/authentication-access/database-level-roles
-- public
-- db_role_vs_admin
-- db_owner
-- db_accessadmin
-- db_securityadmin
-- db_ddladmin
-- db_backupoperator
-- db_datareader
-- db_datawriter
-- db_denydatareader
-- db_denydatawriter

-- No loger use this because Microsoft is discontinuing it.
 --exec sp_addrolemember '<role to be a member of>', '<roll to add as a memeber>'
 
-- Read more about it here: https://docs.microsoft.com/en-us/sql/t-sql/statements/alter-role-transact-sql?view=sql-server-2017
-- ALTER ROLE <Role Name, including built in ones> [add | drop] member <user/role/login>;

