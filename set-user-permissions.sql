-- To creae a user you must login
-- to the database you want to create
DECLARE @login varchar(100) = NULL;
DECLARE @user varchar(100) = @login + 'usr';
-- If you only want set privileges for 1 database.
DECLARE @permissionsToDatabase VARCHAR(100) = NULL;

DECLARE @grant BIT = 0;
DECLARE @revoke BIT = 0;
DECLARE @deny BIT = 0;

-- Grants the users permission to connect to a database.
DECLARE @privilegeConnect BIT = 0;
DECLARE @privileageShowPlan BIT = 0;
DECLARE @privileageExecute BIT = 0;
DECLARE @privileageSelect BIT = 0;
DECLARE @privileageInsert BIT = 0;
DECLARE @privileageUpdate BIT = 0;
DECLARE @privileageDelete BIT = 0;
DECLARE @privileageCreateTable BIT = 0;
DECLARE @privileageCreateView BIT = 0;
DECLARE @privileageCreateStoredProcedure BIT = 0;
DECLARE @privileageCreateType BIT = 0;
DECLARE @privileageCreateFunction BIT = 0;
DECLARE @privileageCreateDefault BIT = 0;
DECLARE @privileageAlterSchemaDbo BIT = 0;
--The REFERENCES permission on a table is needed to create a FOREIGN KEY constraint that references that table.
--The REFERENCES permission is needed on an object to create a FUNCTION or VIEW with the WITH SCHEMABINDING clause that references that object.
DECLARE @privileageReference BIT = 0;

IF @grant =0 AND @revoke IS NULL AND @deny IS NULL
BEGIN
	SELECT '@privileage, @revoke and @deny can not be NULL but have to be 0';
END
IF @grant = 0 AND @revoke  = 0 AND @deny  = 0
BEGIN
	SELECT '@privileage, @revoke and @deny can not all be 0';
END
ELSE IF @grant = 1 AND (@revoke = 1 OR @deny = 1)
BEGIN
	SELECT 'You cannot have GRANT and REVOKE or DENY together';
END
ELSE IF @revoke  = 1 AND (@grant = 1 OR @deny = 1)
BEGIN
	SELECT 'You cannot have REVOKE and GRANT or DENY together';
END
ELSE IF @deny  = 1 AND (@grant = 1 OR @revoke = 1)
BEGIN
	SELECT 'You cannot have DENY and GRANT or REVOKE together';
END
ELSE IF @login IS NOT NULL AND @user IS NOT NULL
BEGIN
	IF NOT EXISTS (SELECT Name  
				   FROM [sys].[database_principals]
				   WHERE [type] = 'S' 
				   AND Name = @user)
	BEGIN
		EXEC ('CREATE USER [' + @user + '] FOR LOGIN ['+@login+'] WITH DEFAULT_SCHEMA=[dbo]')
	END


	DECLARE @permissions NVARCHAR(100);
	IF @privilegeConnect = 1
	BEGIN
		SET @permissions = ' CONNECT ';
	END

	-- What you want the user
	IF @privileageShowPlan = 1
	BEGIN
		IF LEN(@permissions) > 0
		BEGIN
			SET @permissions += ', SHOWPLAN ';
		END
		ELSE
		BEGIN
			SET @permissions = ' SHOWPLAN ';
		END
	END

	IF @privileageExecute = 1
	BEGIN
		IF LEN(@permissions) > 0
		BEGIN
			SET @permissions += ', EXECUTE ';
		END
		ELSE
		BEGIN
			SET @permissions = ' EXECUTE ';
		END
	END


	IF @privileageSelect = 1
	BEGIN
		IF LEN(@permissions) > 0
		BEGIN
			SET @permissions += ', SELECT ';
		END
		ELSE
		BEGIN
			SET @permissions = ' SELECT ';
		END
	END

	IF @privileageInsert = 1
	BEGIN
		IF LEN(@permissions) > 0
		BEGIN
			SET @permissions += ', INSERT ';
		END
		ELSE
		BEGIN
			SET @permissions = ' INSERT ';
		END
	END

	IF @privileageUpdate = 1
	BEGIN
		IF LEN(@permissions) > 0
		BEGIN
			SET @permissions += ', UPDATE ';
		END
		ELSE
		BEGIN
			SET @permissions = ' UPDATE ';
		END
	END
	  
	IF @privileageDelete = 1
	BEGIN
		IF LEN(@permissions) > 0
		BEGIN
			SET @permissions += ', DELETE ';
		END
		ELSE
		BEGIN
			SET @permissions = ' DELETE ';
		END
	END

	IF @privileageCreateTable = 1
	BEGIN
		IF LEN(@permissions) > 0
		BEGIN
			SET @permissions += ', CREATE TABLE ';
		END
		ELSE
		BEGIN
			SET @permissions = ' CREATE TABLE ';
		END
	END
	 
	IF @privileageCreateView = 1
	BEGIN
		IF LEN(@permissions) > 0
		BEGIN
			SET @permissions += ', CREATE VIEW ';
		END
		ELSE
		BEGIN
			SET @permissions = ' CREATE VIEW ';
		END
	END
	
	IF @privileageCreateStoredProcedure = 1
	BEGIN
		IF LEN(@permissions) > 0
		BEGIN
			SET @permissions += ', CREATE PROCEDURE ';
		END
		ELSE
		BEGIN
			SET @permissions = ' CREATE PROCEDURE ';
		END
	END

	IF @privileageCreateType = 1
	BEGIN
		IF LEN(@permissions) > 0
		BEGIN
			SET @permissions += ', CREATE TYPE ';
		END
		ELSE
		BEGIN
			SET @permissions = ' CREATE TYPE ';
		END
	END
	 
	IF @privileageCreateFunction = 1
	BEGIN
		IF LEN(@permissions) > 0
		BEGIN
			SET @permissions += ', CREATE FUNCTION ';
		END
		ELSE
		BEGIN
			SET @permissions = ' CREATE FUNCTION ';
		END
	END
	 
	IF @privileageCreateDefault = 1
	BEGIN
		IF LEN(@permissions) > 0
		BEGIN
			SET @permissions += ', CREATE DEFAULT ';
		END
		ELSE
		BEGIN
			SET @permissions = ' CREATE DEFAULT ';
		END
	END

	IF @privileageAlterSchemaDbo = 1
	BEGIN
		IF LEN(@permissions) > 0
		BEGIN
			SET @permissions += ', ALTER ON SCHEMA::dbo ';
		END
		ELSE
		BEGIN
			SET @permissions = ' ALTER ON SCHEMA::dbo ';
		END
	END
	 
	IF @privileageReference = 1
	BEGIN
		IF LEN(@permissions) > 0
		BEGIN
			SET @permissions += ', REFERENCES ';
		END
		ELSE
		BEGIN
			SET @permissions = ' REFERENCES';
		END
	END

	DECLARE @privilegeType NVARCHAR(100);

	IF @grant = 1
	BEGIN
		SET @privilegeType = 'Grant';
	END
	ELSE IF @revoke = 1
	BEGIN
		SET @privilegeType = 'REVOKE';
	END
	ELSE IF @deny = 1
	BEGIN
		SET @privilegeType = 'DENY';
	END

	DECLARE @sqlToRun NVARCHAR(200);
	IF LEN(@permissions) > 0
	BEGIN
		IF @permissionsToDatabase IS NULL
		BEGIN
			SET @sqlToRun = @privilegeType + @permissions + ' TO ' + @user + ';';
		END
		ELSE
		BEGIN
			SET @sqlToRun = @privilegeType + @permissions + ' ON ' + @permissionsToDatabase + ' TO ' + @user + ';'
			
		END

		SELECT 'Executed ''' + @sqlToRun + '''.';
		EXEC(@sqlToRun);
	END
	ELSE
	BEGIN
		SELECT 'No privileges to set.';
	END
END
ELSE
BEGIN
	SELECT '@login or @user is NULL';
END