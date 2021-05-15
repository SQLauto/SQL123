-- SELECT * FROM sys.database_scoped_configurations
-- select * from sys.messages
-- select * from sys.sql_modules

SELECT 
Name AS DatabaseName, 
compatibility_level AS CompatibilityLevel, 
N'https://docs.microsoft.com/en-us/sql/t-sql/statements/alter-database-transact-sql-compatibility-level' AS CompatibiltyList
FROM sys.databases

SELECT database_id, create_date, snapshot_isolation_state, snapshot_isolation_state_desc, is_read_committed_snapshot_on, *
FROM SYS.databases

-- Make sure all users are off the database.
-- https://docs.microsoft.com/en-us/troubleshoot/sql/analysis-services/enable-snapshot-transaction-isolation-level
--ALTER DATABASE <database> SET READ_COMMITTED_SNAPSHOT ON/OFF;
--GO
--ALTER DATABASE <database> SET ALLOW_SNAPSHOT_ISOLATION ON/OFF;

select * from sys.database_files;
select * from tempdb.sys.database_files;
select cmd,* from sys.sysprocesses where blocked > 0
select * from sys.dm_tran_locks

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