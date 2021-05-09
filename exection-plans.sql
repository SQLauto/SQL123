-- Indexes: https://docs.microsoft.com/en-us/sql/relational-databases/sql-server-index-design-guide
-- Joins: https://docs.microsoft.com/en-us/sql/relational-databases/performance/joins
-- Removing Cache: https://www.sqlskills.com/blogs/glenn/eight-different-ways-to-clear-the-sql-server-plan-cache/
-- 2019 setting LAST_QUERY_PLAN_STATS: https://sqlrus.com/2020/07/using-last_query_plan_stats-in-sql-server-2019/
-- SELECT * FROM sys.database_scoped_configurations WHERE name = 'LAST_QUERY_PLAN_STATS';
-- ALTER DATABASE SCOPED CONFIGURATION SET LAST_QUERY_PLAN_STATS = OFF; (ON|OFF);
-- DBCC FREEPROCCACHE; -- Remove all elements from the plan cache for the entire instance
-- DBCC FREEPROCCACHE WITH NO_INFOMSGS; -- Flush the plan cache for the entire instance and suppress the regular completion message
-- DBCC FREEPROCCACHE (<plan handle>);

DECLARE @queryLike NVARCHAR(MAX) = NULL;
DECLARE @databaseName NVARCHAR(MAX) = NULL;
DECLARE @queryPlanLike NVARCHAR(MAX) = NULL;
DECLARE @lastExecutedDateTime DATETIME2 = NULL;
DECLARE @objectType NVARCHAR(MAX) = NULL;
DECLARE @viewExectionPlans BIT = 1; 
DECLARE @viewHowManyOfObjectTypes BIT = 1;
DECLARE @howManyRows INT = 20;
	
IF ISNULL(@viewExectionPlans, 0) = 1 BEGIN
    SELECT TOP(ISNULL(@howManyRows, 10))
	DB_NAME(qp.dbid) DatabaseName,
    qsp.plan_id AS QueryStorePlanId,
    len(sqlText.text) QueryLength,
	qs.plan_generation_num AS PlanGenerationNumber,	
    sqlText.text,
	statement_start_offset AS StatementStartOffset,
	statement_end_offset AS StatementEndOffset,
    qs.creation_time,
    qs.last_execution_time,
    cp.cacheobjtype, 
    cp.objtype, 
    OBJECT_ID(qp.objectid) AS ObjectName, 
    qs.last_rows,
    qs.last_logical_reads, 
    qs.last_logical_writes,
    qs.last_physical_reads,
    cp.size_in_bytes,
	sqlText.number AS NumberedStoredProcedure,
    qs.execution_count AS NumberOfTimesPlanHasExecutedSinceLastCompiled,
    cp.usecounts As NumberOfTimesCacheObjectLookedUp,
    cp.refcounts AS NumberOfCacheObjectsReferencingThisCacheObject, 
    qp.query_plan,
	-- Actual Exuection Plan when LAST_QUERY_PLAN_STATS is on.
	-- Only works in SQL Server 2019 and greater.
	-- qps.query_plan,
    cp.plan_handle
    FROM sys.dm_exec_cached_plans cp
    LEFT JOIN sys.dm_exec_query_stats qs ON cp.plan_handle = qs.plan_handle
    LEFT JOIN sys.query_store_plan qsp ON qs.query_plan_hash = qsp.query_plan_hash AND qs.plan_handle = QS.plan_handle
    OUTER APPLY sys.dm_exec_sql_text(cp.plan_handle) sqlText
    OUTER APPLY sys.dm_exec_query_plan(cp.plan_handle ) qp
	-- Only works in SQL Server 2019 and greater.
	-- OUTER APPLY sys.dm_exec_query_plan_stats(cp.plan_handle) qps
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
        (@lastExecutedDateTime IS NOT NULL AND qs.last_execution_time > @lastExecutedDateTime)
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
END
IF ISNULL(@viewHowManyOfObjectTypes, 0) = 1 BEGIN
    SELECT objtype, 
    COUNT(*) as NumberOfPlans,
    SUM(CAST(size_in_bytes as bigint))/1024/1024 as SizeInMBs,
    AVG(usecounts) as AvgNumberOfTimesCacheObjectLookedUp
    FROM sys.dm_exec_cached_plans
    GROUP BY objtype
END