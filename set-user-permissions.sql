-- To creae a user you must login 
-- to the database you want to create 

-- Create user
--CREATE USER <user, normally put 'usr' after login name> FOR LOGIN <login name> WITH DEFAULT_SCHEMA=[dbo]

-- Create a role
-- CREATE ROLE <role name> AUTHORIZATION <role owner, can use CURRENT_USER, which is the default if AUTHORIZATION is left off>;
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

-- Can also use
-- GRANT: Give permission
-- DENY: Deny permission
-- REMOVE: Removed granted permission

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
 --exec sp_addrolemember '<role to be a member of>', '<roll to add as a memeber>'


