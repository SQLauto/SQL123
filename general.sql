-- SELECT * FROM sys.database_scoped_configurations
-- select * from sys.messages
-- select * from sys.sql_modules

SELECT 
Name AS DatabaseName, 
compatibility_level AS CompatibilityLevel, 
N'https://docs.microsoft.com/en-us/sql/t-sql/statements/alter-database-transact-sql-compatibility-level' AS CompatibiltyList
FROM sys.databases

select * from sys.database_files;
select * from tempdb.sys.database_files;

 SELECT name AS FileName,
    size*1.0/128 AS FileSizeInMB,
    CASE max_size
        WHEN 0 THEN 'Autogrowth is off.'
        WHEN -1 THEN 'Autogrowth is on.'
        ELSE 'Log file grows to a maximum size of 2 TB.'
    END,
    growth AS 'GrowthValue',
    'GrowthIncrement' =
        CASE
            WHEN growth = 0 THEN 'Size is fixed.'
            WHEN growth > 0 AND is_percent_growth = 0
                THEN 'Growth value is in 8-KB pages.'
            ELSE 'Growth value is a percentage.'
        END
FROM tempdb.sys.database_files;