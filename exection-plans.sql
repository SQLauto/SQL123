-- MAAIgnore
-- Indexes: https://docs.microsoft.com/en-us/sql/relational-databases/sql-server-index-design-guide
-- Joins: https://docs.microsoft.com/en-us/sql/relational-databases/performance/joins
-- Removing Cache: https://www.sqlskills.com/blogs/glenn/eight-different-ways-to-clear-the-sql-server-plan-cache/
-- 2019 setting LAST_QUERY_PLAN_STATS: https://sqlrus.com/2020/07/using-last_query_plan_stats-in-sql-server-2019/
-- SELECT * FROM sys.database_scoped_configurations WHERE name = 'LAST_QUERY_PLAN_STATS';
-- ALTER DATABASE SCOPED CONFIGURATION SET LAST_QUERY_PLAN_STATS = OFF; (ON|OFF);
-- DBCC FREEPROCCACHE; -- Remove all elements from the plan cache for the entire instance
-- DBCC FREEPROCCACHE WITH NO_INFOMSGS; -- Flush the plan cache for the entire instance and suppress the regular completion message
-- DBCC FREEPROCCACHE (<plan handle>);

-- TODO Find large differences between used, ideal and granted Memory Grants
-- TODO Search exuction plans for keywords such as indexes.

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @queryLike NVARCHAR(MAX) = null --'from Users';
DECLARE @queryLikeEscapeKey NCHAR(1) = '\';
-- Gets current databse
DECLARE @databaseName NVARCHAR(MAX) = DB_NAME();
DECLARE @queryPlanLike NVARCHAR(MAX) = NULL;
DECLARE @lastExecutedDateTime DATETIME2 = NULL; 
DECLARE @viewHowManyOfObjectTypes BIT = 1;
DECLARE @howManyRows INT = 10;

/* Only get queries that are part of the same execution plan. This must not be a string but hex format */
DECLARE @queryOnPlan NVARCHAR(MAX) = NULL;

/* Show the XML Execution Plan */
DECLARE @showExecutionPlan BIT = 1;

/* All types are: 'UsrTab;Prepared;View;Adhoc;Trigger;Proc' */
DECLARE @objectTypes NVARCHAR(MAX) = 'UsrTab;Prepared;View;Adhoc;Trigger;Proc';

/* This allow me to get the query plan id. */
DECLARE @showPlanIds BIT = 0;

-- Order Bys
DECLARE @last_logical_reads BIT = 0;
DECLARE @avg_logical_reads BIT = 1;
DECLARE @lastCPU BIT = 0;
DECLARE @avgCPU BIT = 0;
DECLARE @lastMemoryGrant BIT = 0;
DECLARE @avgMemoryGrant BIT = 0;
DECLARE @lastSpills BIT = 0;
DECLARE @avgSpills BIT = 0;
DECLARE @lastDuration BIT = 0;
DECLARE @avgDuration BIT = 0;
DECLARE @exectionCount BIT = 0;
DECLARE @excutedInPastMinutes INT = NULL;
	
WITH CTE_ExecutionPlans AS
(
	SELECT
	NULL AS type_desc,
	IIF(ISNULL(@showPlanIds, 0) = 0, NULL, qsp.plan_id)  AS plan_id,
 	/* This will normally get incremented when statistics are updated. */
	qs.plan_generation_num,	
	qs.creation_time,
	qs.last_execution_time,
	cp.cacheobjtype, 
	cp.objtype, 
	execution_count,
	qs.total_elapsed_time,
	qs.last_elapsed_time,
	qs.min_elapsed_time,
	qs.max_elapsed_time,
	cp.size_in_bytes,
	qs.total_rows,
	qs.last_rows,
	qs.min_rows,
	qs.Max_rows,
	qs.total_num_page_server_reads,
	qs.last_num_page_server_reads,
	qs.min_num_page_server_reads,
	qs.max_num_page_server_reads,
	qs.total_logical_reads,
	qs.last_logical_reads,
	qs.min_logical_reads,
	qs.max_logical_reads,
	qs.total_physical_reads,
	qs.last_physical_reads,
	qs.min_physical_reads,
	qs.max_physical_reads,
	qs.total_logical_writes,
	qs.last_logical_writes,
	qs.min_logical_writes,
	qs.max_logical_writes,
	qs.total_grant_kb,
	qs.last_grant_kb,
	qs.min_grant_kb,
	qs.max_grant_kb,
	qs.total_ideal_grant_kb,
	qs.last_ideal_grant_kb,
	qs.min_ideal_grant_kb,
	qs.max_ideal_grant_kb,
	qs.total_used_grant_kb,
	qs.last_used_grant_kb,
	qs.min_used_grant_kb,
	qs.max_used_grant_kb,
	qs.total_dop,
	qs.last_dop,
	qs.min_dop,
	qs.max_dop,
	qs.total_spills,
	qs.last_spills,
	qs.min_spills,
	qs.max_spills,
	qs.total_used_threads,
	qs.last_used_threads,
	qs.min_used_threads,
	qs.max_used_threads,
	qs.total_worker_time,
	qs.last_worker_time,
	qs.min_worker_time,
	qs.max_worker_time,
	cp.usecounts,
	cp.refcounts, 
	qs.statement_start_offset,
	qs.statement_end_offset,
	sqlText.objectid,
	sqlText.dbid,
	sqlText.number,
	sqlText.Text,
	cp.bucketid,
	qs.query_hash,
	qs.query_plan_hash,
	cp.plan_handle,
	cp.parent_plan_handle
	FROM sys.dm_exec_cached_plans cp
	CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) sqlText
	LEFT JOIN sys.dm_exec_query_stats qs ON cp.plan_handle = qs.plan_handle
	LEFT JOIN sys.query_store_plan qsp ON qs.query_plan_hash = qsp.query_plan_hash AND qs.plan_handle = QS.plan_handle
	WHERE
	(
		(@queryLike IS NOT NULL AND CAST(sqlText.text AS NVARCHAR(MAX)) LIKE '%' + @queryLike + '%' ESCAPE @queryLikeEscapeKey)
		OR @queryLike IS NULL
	)
	AND sqlText.text NOT LIKE '%MAAIgnore%'
	AND
	(
		(@lastExecutedDateTime IS NOT NULL AND qs.last_execution_time > @lastExecutedDateTime)
		OR @lastExecutedDateTime IS NULL
	)
	AND
	(
		(@objectTypes IS NOT NULL AND cp.objtype IN(SELECT VALUE FROM STRING_SPLIT(@objectTypes, ';')))
		OR @objectTypes IS NULL
	)
	AND
	(
		(@databaseName IS NOT NULL AND DB_NAME(sqlText.dbid) = @databaseName)
		OR @databaseName IS NULL
	)
	AND (@excutedInPastMinutes IS NULL OR qs.last_execution_time > DATEADD(minute, -@excutedInPastMinutes, GETDATE()))
),
CTE_ExecutionPlans_Distinct AS
(
	SELECT DISTINCT *
	FROM CTE_ExecutionPlans
),
CTE_ExecutionPlan_WithXmlPlan AS
(
	SELECT ep.*,
	qp.query_plan AS ExecutionPlanInXml,
	IIF(ep.plan_handle IS NOT NULL, CONCAT('USE ', DB_NAME(), '; ', 'DBCC FREEPROCCACHE (', CONVERT(VARCHAR(128), ep.plan_handle, 1), ');'), 'N/A') AS FreeExecutionPlan,
	CONCAT('USE ', DB_NAME(), '; ', 'DBCC FREEPROCCACHE;') FreeAllExecutionPlans
	FROM CTE_ExecutionPlans_Distinct ep
	OUTER APPLY sys.dm_exec_query_plan(IIF(ISNULL(@showExecutionPlan, 0) = 0, NULL, ep.plan_handle)) AS qp
)

SELECT TOP(ISNULL(@howManyRows, 10))

OBJECT_NAME(txpt.objectid) AS ObjectName,

txpt.objtype As ObjectType, 
txpt.cacheobjtype AS CacheObjectType, 

SUBSTRING
(
	txpt.text, 
	(txpt.statement_start_offset/2)+1, 
	(
		(
			CASE txpt.statement_end_offset  
				WHEN -1 THEN DATALENGTH(txpt.text)  
				ELSE txpt.statement_end_offset  
			END - txpt.statement_start_offset
		)/2
	) + 1
) 
AS SQLStatementText,
txpt.text AS SqlText,
ExecutionPlanInXml,
txpt.statement_start_offset AS StatementStartOffset,
txpt.statement_end_offset AS StatementEndOffset,

FreeExecutionPlan,
FreeAllExecutionPlans,

txpt.type_desc AS TypeDesc,
DB_NAME(txpt.dbid) DatabaseName,
FORMAT(execution_count, N'N0') AS ExecutionCount,
txpt.objectid AS ObjectId,
txpt.plan_id AS QueryStorePlanId,
txpt.plan_generation_num AS GenerationNumber,	
txpt.creation_time AS CompiledDateTime,
txpt.last_execution_time AS LastExecutionDateTime,
txpt.bucketid AS BucketId,

FORMAT(txpt.total_elapsed_time, N'N0') AS TotalElapsedTimeInMS,
CONVERT(VARCHAR(100), FLOOR(txpt.total_elapsed_time/txpt.execution_count/1000000.0/60/60/24)) + 'd'
+ ':' + CONVERT(VARCHAR(100), FLOOR(txpt.total_elapsed_time/txpt.execution_count/1000000.0/60/60%24)) + 'h'
+ ':' + CONVERT(VARCHAR(100), FLOOR(txpt.total_elapsed_time/txpt.execution_count/1000000.0/60%60)) + 'm'
+ ':' + CONVERT(VARCHAR(100), FLOOR(txpt.total_elapsed_time/txpt.execution_count/1000000.0%60)) + 's'
+ ':' + CONVERT(VARCHAR(100), txpt.total_elapsed_time/txpt.execution_count/1000%1000) + 'ms'
+ ':' + LEFT(CONVERT(VARCHAR(100), txpt.total_elapsed_time/txpt.execution_count%1000), 3) + 'ns'
AS AvgDuration,

CONVERT(VARCHAR(100), FLOOR(txpt.total_elapsed_time/1000000.0/60/60/24)) + 'd'
+ ':' + CONVERT(VARCHAR(100), FLOOR(txpt.total_elapsed_time/1000000.0/60/60%24)) + 'h'
+ ':' + CONVERT(VARCHAR(100), FLOOR(txpt.total_elapsed_time/1000000.0/60%60)) + 'm'
+ ':' + CONVERT(VARCHAR(100), FLOOR(txpt.total_elapsed_time/1000000.0%60)) + 's'
+ ':' + CONVERT(VARCHAR(100), txpt.total_elapsed_time/1000%1000) + 'ms'
+ ':' + LEFT(CONVERT(VARCHAR(100), txpt.total_elapsed_time%1000), 3) + 'ns'
AS TotalDuration,

CONVERT(VARCHAR(100), FLOOR(txpt.last_elapsed_time/1000000.0/60/60/24)) + 'd'
+ ':' + CONVERT(VARCHAR(100), FLOOR(txpt.last_elapsed_time/1000000.0/60/60%24)) + 'h'
+ ':' + CONVERT(VARCHAR(100), FLOOR(txpt.last_elapsed_time/1000000.0/60%60)) + 'm'
+ ':' + CONVERT(VARCHAR(100), FLOOR(txpt.last_elapsed_time/1000000.0%60)) + 's'
+ ':' + CONVERT(VARCHAR(100), txpt.last_elapsed_time/1000%1000) + 'ms'
+ ':' + LEFT(CONVERT(VARCHAR(100), txpt.last_elapsed_time%1000), 3) + 'ns'
AS LastDuration,

CONVERT(VARCHAR(100), FLOOR(txpt.min_elapsed_time/1000000.0/60/60/24)) + 'd'
+ ':' + CONVERT(VARCHAR(100), FLOOR(txpt.min_elapsed_time/1000000.0/60/60%24)) + 'h'
+ ':' + CONVERT(VARCHAR(100), FLOOR(txpt.min_elapsed_time/1000000.0/60%60)) + 'm'
+ ':' + CONVERT(VARCHAR(100), FLOOR(txpt.min_elapsed_time/1000000.0%60)) + 's'
+ ':' + CONVERT(VARCHAR(100), txpt.min_elapsed_time/1000%1000) + 'ms'
+ ':' + LEFT(CONVERT(VARCHAR(100), txpt.min_elapsed_time%1000), 3) + 'ns'
AS MinDuration,

CONVERT(VARCHAR(100), FLOOR(txpt.max_elapsed_time/1000000.0/60/60/24)) + 'd'
+ ':' + CONVERT(VARCHAR(100), FLOOR(txpt.max_elapsed_time/1000000.0/60/60%24)) + 'h'
+ ':' + CONVERT(VARCHAR(100), FLOOR(txpt.max_elapsed_time/1000000.0/60%60)) + 'm'
+ ':' + CONVERT(VARCHAR(100), FLOOR(txpt.max_elapsed_time/1000000.0%60)) + 's'
+ ':' + CONVERT(VARCHAR(100), txpt.max_elapsed_time/1000%1000) + 'ms'
+ ':' + LEFT(CONVERT(VARCHAR(100), txpt.max_elapsed_time%1000), 3) + 'ns'
AS MaxDuration,

FORMAT(txpt.size_in_bytes, N'N0') AS SizeInBytes,
    
FORMAT(txpt.total_rows/txpt.execution_count, N'N0') AS AvgRows,
FORMAT(txpt.total_rows, N'N0') AS TotalRows,
FORMAT(txpt.last_rows, N'N0') AS LastRows,
FORMAT(txpt.min_rows, N'N0') AS MinRows,
FORMAT(txpt.Max_rows, N'N0') AS MaxRows,

FORMAT(txpt.total_num_page_server_reads/txpt.execution_count, N'N0') AS AvgNumPageServerReads,
FORMAT(txpt.total_num_page_server_reads, N'N0') AS TotalNumPageServerReads,
FORMAT(txpt.last_num_page_server_reads, N'N0') AS LastNumPageServerReads,
FORMAT(txpt.min_num_page_server_reads, N'N0') AS MinNumPageServerReads,
FORMAT(txpt.max_num_page_server_reads, N'N0') AS MaxNumPageServerReads,

FORMAT(txpt.total_logical_reads/txpt.execution_count, N'N0') AS AvgLogicalReads,
FORMAT(txpt.total_logical_reads, N'N0') AS TotalLogicalReads,
FORMAT(txpt.last_logical_reads, N'N0') AS LastLogicalReads,
FORMAT(txpt.min_logical_reads, N'N0') AS MinLogicalReads,
FORMAT(txpt.max_logical_reads, N'N0') AS MaxLogicalReads,

FORMAT(txpt.total_physical_reads/txpt.execution_count, N'N0') AS AvgPhysicalReads,
FORMAT(txpt.total_physical_reads, N'N0') AS TotalPhysicalReads,
FORMAT(txpt.last_physical_reads, N'N0') AS LastPhysicalReads,
FORMAT(txpt.min_physical_reads, N'N0') AS MinPhysicalReads,
FORMAT(txpt.max_physical_reads, N'N0') AS MaxPhysicalReads,

FORMAT(txpt.total_logical_writes/txpt.execution_count, N'N0') AS AvgLogicalWrites,
FORMAT(txpt.total_logical_writes, N'N0') AS TotalLogicalWrites,
FORMAT(txpt.last_logical_writes, N'N0') AS LastLogicalWrites,
FORMAT(txpt.min_logical_writes, N'N0') AS MinLogicalWrites,
FORMAT(txpt.max_logical_writes, N'N0') AS MaxLogicalWrites,

FORMAT(txpt.total_grant_kb/txpt.execution_count/1024, N'N0') AS AvgMemoryGrantInMb,
FORMAT(txpt.total_grant_kb/1024, N'N0') AS TotalMemoryGrantInMb,
FORMAT(txpt.last_grant_kb/1024, N'N0') AS LastMemoryGrantInMb,
FORMAT(txpt.min_grant_kb/1024, N'N0') AS MinMemoryGrantInMb,
FORMAT(txpt.max_grant_kb/1024, N'N0') AS MaxMemoryGrantInMb,

FORMAT(txpt.total_ideal_grant_kb/txpt.execution_count/1024, N'N0') AS AvgIdealMemoryGrantInMb,
FORMAT(txpt.total_ideal_grant_kb/1024, N'N0') AS TotalIdealMemoryGrantInMb,
FORMAT(txpt.last_ideal_grant_kb/1024, N'N0') AS LastIdealMemoryGrantInMb,
FORMAT(txpt.min_ideal_grant_kb/1024, N'N0') AS MinIdealMemoryGrantInMb,
FORMAT(txpt.max_ideal_grant_kb/1024, N'N0') AS MaxIdealMemoryGrantInMb,

FORMAT(txpt.total_used_grant_kb/txpt.execution_count/1024, N'N0') AS AvgUsedMemoryGrantInMb,
FORMAT(txpt.total_used_grant_kb/1024, N'N0') AS TotalUsedMemoryGrantInMb,
FORMAT(txpt.last_used_grant_kb/1024, N'N0') AS LastUsedMemoryGrantInMb,
FORMAT(txpt.min_used_grant_kb/1024, N'N0') AS MinUsedMemoryGrantInMb,
FORMAT(txpt.max_used_grant_kb/1024, N'N0') AS MaxUsedMemoryGrantInMb,

FORMAT(txpt.total_dop/txpt.execution_count, N'N0') AS AvgDop,
FORMAT(txpt.total_dop, N'N0') AS TotalDop,
FORMAT(txpt.last_dop, N'N0') AS LastDop,
FORMAT(txpt.min_dop, N'N0') AS MinDop,
FORMAT(txpt.max_dop, N'N0') AS MaxDop,

FORMAT(txpt.total_spills/txpt.execution_count, N'N0') AS AvgSpills,
FORMAT(txpt.total_spills, N'N0') AS TotalSpills,
FORMAT(txpt.last_spills, N'N0') AS LastSpills,
FORMAT(txpt.min_spills, N'N0') AS MinSpills,
FORMAT(txpt.max_spills, N'N0') AS MaxSpills,

FORMAT(txpt.total_used_threads/txpt.execution_count, N'N0') AS AvgUsedThreads,
FORMAT(txpt.total_used_threads, N'N0') TotalUsedThreads,
FORMAT(txpt.last_used_threads, N'N0') LastUsedThreads,
FORMAT(txpt.min_used_threads, N'N0') MinUsedThreads,
FORMAT(txpt.max_used_threads, N'N0') MaxUsedThreads,

CONVERT(VARCHAR(100), FLOOR(txpt.total_worker_time/txpt.execution_count/1000000.0/60/60/24)) + 'd'
+ ':' + CONVERT(VARCHAR(100), FLOOR(txpt.total_worker_time/txpt.execution_count/1000000.0/60/60%24)) + 'h'
+ ':' + CONVERT(VARCHAR(100), FLOOR(txpt.total_worker_time/txpt.execution_count/1000000.0/60%60)) + 'm'
+ ':' + CONVERT(VARCHAR(100), FLOOR(txpt.total_worker_time/txpt.execution_count/1000000.0%60)) + 's'
+ ':' + CONVERT(VARCHAR(100), txpt.total_worker_time/txpt.execution_count/1000%1000) + 'ms'
+ ':' + LEFT(CONVERT(VARCHAR(100), txpt.total_worker_time/txpt.execution_count%1000), 3) + 'ns'
AS AvgCPUWorkerTime,

CONVERT(VARCHAR(100), FLOOR(txpt.total_worker_time/1000000.0/60/60/24)) + 'd'
+ ':' + CONVERT(VARCHAR(100), FLOOR(txpt.total_worker_time/1000000.0/60/60%24)) + 'h'
+ ':' + CONVERT(VARCHAR(100), FLOOR(txpt.total_worker_time/1000000.0/60%60)) + 'm'
+ ':' + CONVERT(VARCHAR(100), FLOOR(txpt.total_worker_time/1000000.0%60)) + 's'
+ ':' + CONVERT(VARCHAR(100), txpt.total_worker_time/1000%1000) + 'ms'
+ ':' + LEFT(CONVERT(VARCHAR(100), txpt.total_worker_time%1000), 3) + 'ns'
AS TotalCPUWorkerTime,

CONVERT(VARCHAR(100), FLOOR(txpt.last_worker_time/1000000.0/60/60/24)) + 'd'
+ ':' + CONVERT(VARCHAR(100), FLOOR(txpt.last_worker_time/1000000.0/60/60%24)) + 'h'
+ ':' + CONVERT(VARCHAR(100), FLOOR(txpt.last_worker_time/1000000.0/60%60)) + 'm'
+ ':' + CONVERT(VARCHAR(100), FLOOR(txpt.last_worker_time/1000000.0%60)) + 's'
+ ':' + CONVERT(VARCHAR(100), txpt.last_worker_time/1000%1000) + 'ms'
+ ':' + LEFT(CONVERT(VARCHAR(100), txpt.last_worker_time%1000), 3) + 'ns'
AS LastCPUWorkerTime,

CONVERT(VARCHAR(100), FLOOR(txpt.min_worker_time/1000000.0/60/60/24)) + 'd'
+ ':' + CONVERT(VARCHAR(100), FLOOR(txpt.min_worker_time/1000000.0/60/60%24)) + 'h'
+ ':' + CONVERT(VARCHAR(100), FLOOR(txpt.min_worker_time/1000000.0/60%60)) + 'm'
+ ':' + CONVERT(VARCHAR(100), FLOOR(txpt.min_worker_time/1000000.0%60)) + 's'
+ ':' + CONVERT(VARCHAR(100), txpt.min_worker_time/1000%1000) + 'ms'
+ ':' + LEFT(CONVERT(VARCHAR(100), txpt.min_worker_time%1000), 3) + 'ns'
AS MinCPUWorkerTime,

CONVERT(VARCHAR(100), FLOOR(txpt.max_worker_time/1000000.0/60/60/24)) + 'd'
+ ':' + CONVERT(VARCHAR(100), FLOOR(txpt.max_worker_time/1000000.0/60/60%24)) + 'h'
+ ':' + CONVERT(VARCHAR(100), FLOOR(txpt.max_worker_time/1000000.0/60%60)) + 'm'
+ ':' + CONVERT(VARCHAR(100), FLOOR(txpt.max_worker_time/1000000.0%60)) + 's'
+ ':' + CONVERT(VARCHAR(100), txpt.max_worker_time/1000%1000) + 'ms'
+ ':' + LEFT(CONVERT(VARCHAR(100), txpt.max_worker_time%1000), 3) + 'ns'
AS MaxCPUWorkerTime,

FORMAT(txpt.number, N'N0') AS NumberedStoredProcedure,
FORMAT(txpt.usecounts, N'N0') As NumberOfTimesCacheObjectLookedUp,
FORMAT(txpt.refcounts, N'N0') AS NumberOfCacheObjectsReferencingThisCacheObject, 
FORMAT(LEN(txpt.text), N'N0') QueryLength,
txpt.query_hash AS QueryHash,
txpt.query_plan_hash AS QueryPlanHash,
txpt.plan_handle AS PlanHandle,
txpt.parent_plan_handle AS ParentHandle
FROM CTE_ExecutionPlan_WithXmlPlan txpt
WHERE (txpt.plan_handle = @queryOnPlan OR @queryOnPlan IS NULL)
ORDER BY

CASE WHEN ISNULL(@last_logical_reads, 0) = 1 THEN txpt.last_logical_reads END DESC,
CASE WHEN ISNULL(@avg_logical_reads, 0) = 1 THEN txpt.total_logical_reads/txpt.execution_count END DESC,

CASE WHEN ISNULL(@lastCPU, 0) = 1 THEN txpt.last_worker_time END DESC,
CASE WHEN ISNULL(@avgCPU, 0) = 1 THEN txpt.total_worker_time/txpt.execution_count END DESC,

CASE WHEN ISNULL(@lastMemoryGrant, 0) = 1 THEN txpt.last_grant_kb END DESC,
CASE WHEN ISNULL(@avgMemoryGrant, 0) = 1 THEN txpt.total_grant_kb/txpt.execution_count END DESC,

CASE WHEN ISNULL(@lastSpills, 0) = 1 THEN txpt.last_spills END DESC,
CASE WHEN ISNULL(@avgSpills, 0) = 1 THEN txpt.total_spills/txpt.execution_count END DESC,

CASE WHEN ISNULL(@lastDuration, 0) = 1 THEN txpt.last_elapsed_time END DESC,
CASE WHEN ISNULL(@avgDuration, 0) = 1 THEN txpt.total_elapsed_time/txpt.execution_count END DESC,

CASE WHEN ISNULL(@exectionCount, 0) = 1 THEN txpt.execution_count END DESC,

txpt.last_execution_time DESC;

IF ISNULL(@viewHowManyOfObjectTypes, 0) = 1 BEGIN
    SELECT objtype, 
    FORMAT(COUNT(*), N'N0') as NumberOfPlans,
    FORMAT(SUM(CAST(size_in_bytes as bigint))/1024/1024, N'N0') as SizeInMBs,
    FORMAT(AVG(usecounts), N'N0') as AvgNumberOfTimesCacheObjectLookedUp
    FROM sys.dm_exec_cached_plans
    GROUP BY objtype
END
