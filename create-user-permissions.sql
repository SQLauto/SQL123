-- To creae a user you must login
-- to the database you want to create
DECLARE @login varchar(100) = NULL;
DECLARE @user varchar(100) = @login + 'usr'

-- Grants the users permission to connect to a database.
DECLARE @grantConnect BIT = 0;
DECLARE @grantShowPlan BIT = 1;
DECLARE @grantExecute BIT = 0;
DECLARE @grantSelect BIT = 0;
DECLARE @grantInsert BIT = 0;
DECLARE @grantUpdate BIT = 0;
DECLARE @grantDelete BIT = 0;
DECLARE @grantCreateTable BIT = 0;
DECLARE @grantCreateView BIT = 0;
DECLARE @grantCreateStoredProcedure BIT = 0;
DECLARE @grantCreateType BIT = 0;
DECLARE @grantCreateFunction BIT = 0;
DECLARE @grantCreateDefault BIT = 0;
DECLARE @grantAlterSchemaDbo BIT = 0;
--The REFERENCES permission on a table is needed to create a FOREIGN KEY constraint that references that table.
--The REFERENCES permission is needed on an object to create a FUNCTION or VIEW with the WITH SCHEMABINDING clause that references that object.
DECLARE @grantReference BIT = 0;

--GRANT SELECT [object like table] TO [user];
-- remove  REVOKE SHOWPLAN FROM mikeusr;


IF @login IS NOT NULL AND @user IS NOT NULL
BEGIN
	IF NOT EXISTS (SELECT Name  
				   FROM [sys].[database_principals]
				   WHERE [type] = 'S' 
				   AND Name = @user)
	BEGIN
		EXEC ('CREATE USER [' + @user + '] FOR LOGIN ['+@login+'] WITH DEFAULT_SCHEMA=[dbo]')
	END

	IF @grantConnect = 1
	BEGIN
		EXEC('GRANT SHOWPLAN TO [' + @user + ']')
	END

	-- What you want the user
	IF @grantShowPlan = 1
	BEGIN
		EXEC('GRANT SHOWPLAN TO [' + @user + ']')
	END

	IF @grantExecute = 1
	BEGIN
		EXEC('GRANT EXECUTE TO [' + @user + ']')
	END

	IF @grantSelect = 1
	BEGIN
		EXEC('GRANT SELECT TO [' + @user + ']')
	END

	IF @grantInsert = 1
	BEGIN
		EXEC('GRANT INSERT TO [' + @user + ']')
	END

	IF @grantUpdate = 1
	BEGIN
		EXEC('GRANT UPDATE TO [' + @user + ']')
	END
	  
	IF @grantDelete = 1
	BEGIN
		EXEC('GRANT DELETE TO [' + @user + ']')
	END

	IF @grantCreateTable = 1
	BEGIN
			EXEC('GRANT CREATE TABLE TO [' + @user + ']')
	END
	 
	IF @grantCreateView = 1
	BEGIN
			EXEC('GRANT CREATE VIEW TO [' + @user + ']')
	END
	
	IF @grantCreateStoredProcedure = 1
	BEGIN
			EXEC('GRANT CREATE PROCEDURE TO [' + @user + ']')
	END

	IF @grantCreateType = 1
	BEGIN
			EXEC('GRANT CREATE TYPE TO [' + @user + ']')
	END
	 
	IF @grantCreateFunction = 1
	BEGIN
		EXEC('GRANT CREATE FUNCTION TO [' + @user + ']')
	END
	 
	IF @grantCreateDefault = 1
	BEGIN
		EXEC('GRANT CREATE DEFAULT TO [' + @user + ']')
	END

	IF @grantAlterSchemaDbo = 1
	BEGIN
			EXEC('GRANT ALTER ON SCHEMA::dbo TO [' + @user + ']')
	END
	 
	IF @grantReference = 1
	BEGIN
			EXEC('GRANT REFERENCES TO [' + @user + ']')
	END
END