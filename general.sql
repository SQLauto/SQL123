-- SELECT * FROM sys.database_scoped_configurations

SELECT 
Name AS DatabaseName, 
compatibility_level AS CompatibilityLevel, 
N'https://docs.microsoft.com/en-us/sql/t-sql/statements/alter-database-transact-sql-compatibility-level' AS CompatibiltyList
FROM sys.databases