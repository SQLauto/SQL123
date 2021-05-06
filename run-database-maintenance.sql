DECLARE @keepOnline BIT = 0;
DECLARE @databaseName NVARCHAR(MAX) = NULL;
DECLARE @defrag BIT = 0;
DECLARE @updateStatistics BIT = 0;


IF ISNULL(@databaseName, '') != '' BEGIN
    DECLARE @databaseTable NVARCHAR(255);
    DECLARE @table NVARCHAR(255);
    DECLARE @cmd NVARCHAR(1000);

    DECLARE DatabaseCursor CURSOR READ_ONLY FOR  
    SELECT Name 
    FROM sys.databases   
    WHERE NAME = @databaseName
    AND State = 0 -- database is online
    AND is_in_standby = 0 -- database is not read only for log shipping
    ORDER BY 1;

    OPEN DatabaseCursor;

    FETCH NEXT FROM DatabaseCursor INTO @databaseTable
    WHILE @@FETCH_STATUS = 0  
    BEGIN

    SET @cmd = 
    '
    DECLARE TableCursor CURSOR 
    READ_ONLY FOR 
    SELECT ''['' + table_catalog + ''].['' + table_schema + ''].['' +  
    table_name + '']'' as tn
    FROM [' + @databaseTable + '].Information_Schema.Tables
    WHERE table_type = ''BASE TABLE'';
    ';
    -- create table cursor  
    EXEC (@cmd);
    OPEN TableCursor;

    FETCH NEXT FROM TableCursor INTO @table WHILE @@FETCH_STATUS = 0 BEGIN
        BEGIN TRY
            IF ISNULL(@defrag, 0) = 1 BEGIN
                IF @keepOnline = 1 BEGIN
                    SET @cmd = 'ALTER INDEX ALL ON ' + @table + ' REBUILD WITH (ONLINE = ON);';
                END
                ELSE BEGIN
                    SET @cmd = 'ALTER INDEX ALL ON ' + @table + ' REBUILD;';
                END
                PRINT @cmd;
                EXEC (@cmd);
            END
            IF ISNULL(@updateStatistics, 0) = 1 BEGIN
                SET @cmd = 'UPDATE STATISTICS ' + @table + ';';
                PRINT @cmd;
                EXEC (@cmd);
            END
        END TRY
        BEGIN CATCH
            PRINT '---';
            PRINT @cmd;
            PRINT ERROR_MESSAGE() ;
            PRINT '---';
        END CATCH

        FETCH NEXT FROM TableCursor INTO @table;
    END   

    CLOSE TableCursor;
    DEALLOCATE TableCursor;

    FETCH NEXT FROM DatabaseCursor INTO @databaseTable;
    END;
    CLOSE DatabaseCursor;
    DEALLOCATE DatabaseCursor;
END
ELSE BEGIN
    SELECT '@databaseName is null empty and must have a value.';
END