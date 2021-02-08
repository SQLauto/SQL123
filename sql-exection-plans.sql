-- DBCC FREEPROCCACHE (0x060009006BCD5029505CD63DC502000001000000000000000000000000000000000000000000000000000000);
DECLARE @queryLike NVARCHAR(MAX) = 'select Count(Logger)';
DECLARE @databaseName NVARCHAR(MAX) = 'VirtueScriptImport';
DECLARE @queryPlanLike NVARCHAR(MAX) = NULL;
DECLARE @lastExecutedDateTime DATETIME2 = NULL;
DECLARE @objectType NVARCHAR(MAX) = NULL;

SELECT TOP 10 
len(sqlText.text) QueryLength, DB_NAME(qp.dbid) DatabaseName, 
cp.cacheobjtype, cp.objtype,
OBJECT_ID(qp.objectid) AS ObjectName, 
qp.number, cp.plan_handle,
qs.execution_count,cp.refcounts, CP.usecounts,
qs.creation_time,qs.last_execution_time,
qs.last_rows,qs.last_logical_reads, qs.last_logical_writes,qs.last_physical_reads,
cp.size_in_bytes, cp.usecounts, sqlText.text
,qp.query_plan
FROM sys.dm_exec_cached_plans cp
JOIN sys.dm_exec_query_stats qs ON cp.plan_handle = qs.plan_handle
CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle)AS sqlText
CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle)AS qp
WHERE
(
    (@queryLike IS NOT NULL AND CAST(sqlText.text AS NVARCHAR(MAX)) LIKE '%' + @queryLike + '%')
    OR @queryLike IS NULL
)
AND
(
    (@queryPlanLike IS NOT NULL AND CAST(qp.query_plan AS NVARCHAR(MAX)) LIKE '%' + @queryPlanLike + '%')
    OR @queryPlanLike IS NULL
)
AND
(
    (@lastExecutedDateTime IS NOT NULL AND last_execution_time > @lastExecutedDateTime)
    OR @lastExecutedDateTime IS NULL
)
AND
(
    (@objectType IS NOT NULL AND cp.objtype = @objectType)
    OR @objectType IS NULL
)
AND
(
    (@databaseName IS NOT NULL AND DB_NAME(qp.dbid) = @databaseName)
    OR @databaseName IS NULL
)
AND (text NOT LIKE '%@queryLike%')
ORDER BY last_execution_time DESC