-- https://sqlperformance.com/2021/01/sql-performance/use-case-sp_prepare
DECLARE @param1 BIGINT = NULL;
DECLARE @params NVARCHAR(MAX) = NULL;
DECLARE @sql nvarchar(MAX) = NULL;

EXEC sys.sp_executesql @sql, @params, @param1;