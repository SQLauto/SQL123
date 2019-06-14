USE master

-- To create a login you must
-- login into maser as an admin
-- and run the below script.
DECLARE @login varchar(100 ) = NULL
DECLARE @password varchar(100) = NULL

IF @login IS NOT NULL AND @password IS NOT NULL AND NOT EXISTS(SELECT *  FROM sys.sql_logins WHERE NAME = @login) 
BEGIN
	EXEC('CREATE LOGIN ' + @login + ' WITH PASSWORD = ''' + @password + '''')
END
ELSE
BEGIN
	SELECT '@password cannot be null.'
	END
END