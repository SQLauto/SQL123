DECLARE @dt DATETIME2 = DATEADD(minute, -120, GETDATE());
DECLARE @top INT = 5;
DECLARE @plainId INT;
DECLARE @queryId INT;

SET @plainId = NULL;
SET @queryId = NULL;

DECLARE @showDuration BIT = 1;
DECLARE @showTotalDuration BIT = 0;
DECLARE @showTotalExecutions BIT = 0;
DECLARE @showIo BIT = 0;
DECLARE @showCpu BIT = 0;
DECLARE @showMemory BIT = 0;
DECLARE @showParallelism BIT = 0;

DECLARE @showSpidSesisonLoginInformation BIT = 0;
DECLARE @showSpidSessionRuntimeStats BIT = 0;
DECLARE @showSpidRequestRuntimeStats BIT = 0;
DECLARE @showSpidRequestQuery BIT = 0;
DECLARE @showSpidRequestWaitStat BIT = 0;


IF @showSpidSesisonLoginInformation = 1 OR @showSpidSessionRuntimeStats = 1 OR @showSpidRequestRuntimeStats = 1 OR @showSpidRequestQuery = 1 OR @showSpidRequestWaitStat = 1 BEGIN
    SELECT s.session_id AS SPID,
        login_name AS SessionLoginName,
        s.original_login_name AS SessionOriginalLoginName,
        nt_user_name AS SessionNtUserName,
        nt_domain AS SessionNtDomain,
        login_time AS SessionLoginTime,
        s.client_version AS SessionClientVersion,
        s.client_interface_name AS SessionClient,
        s.status AS SessionStatus,
        s.cpu_time AS SessionCpuTime,
        s.memory_usage AS SessionMemoryUsage8KBPages,
        s.total_elapsed_time AS SessionTotalElapedTime,
        s.total_scheduled_time As SessionTotalTimeScheduledForExection,
        s.last_request_start_time AS SessionRequestedStartTime,
        s.last_request_end_time AS SessionRequestedEndTime,
        s.reads AS SessionReadsPerformed,
        s.writes AS SessionWritesPerformed,
        s.logical_reads AS SessionLogicalReads,
        s.is_user_process AS SessionIsUserProcess,
        s.text_size,
        CASE
	 WHEN s.transaction_isolation_level = 0 THEN 'Unspecified'
	 WHEN s.transaction_isolation_level = 1 THEN 'Read Uncomitted'
	 WHEN s.transaction_isolation_level = 2 THEN 'Read Committed'
	 WHEN s.transaction_isolation_level = 5 THEN 'Repeatable'
	 WHEN s.transaction_isolation_level = 4 THEN 'Serializable'
	 WHEN s.transaction_isolation_level = 5 THEN 'Snapshot'
	 ELSE 'View here https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-exec-sessions-transact-sql?view=sql-server-2017 to find out'
	END As SessionTransactionIsolationLevel,
        s.lock_timeout AS SessionLockTimeout,
        s.deadlock_priority AS SessionDeadlockPriority,
        s.row_count AS SessionRowCount,
        s.prev_error AS SessionPreviousError,
        s.last_successful_logon AS SessionLastSuccessfulLogon,
        s.last_unsuccessful_logon AS SessionLastUnSuccessfulLogon,
        DB_NAME(s.database_id) AS SessionDatabase,
        s.open_transaction_count AS SessionOpenTransactionCount,
        r.start_time As RequestStartTime,
        r.status As RequestStatus,
        r.command As RequestCommand,
        DB_NAME(r.database_id) AS RequestDatabase,
        r.blocking_session_id AS RequestBlockingSessionId,
        r.wait_type AS RequestWaitType,
        r.wait_time AS RequestWaitTime,
        r.last_wait_type AS RequestLastWaitType,
        r.wait_resource AS RequestWaitResource,
        r.sql_handle AS RequestSqlHandle,
        r.statement_start_offset AS RequestStatementStartOffset,
        r.statement_end_offset AS RequestStatementEndOffset,
        r.plan_handle AS RequestPlanHandle,
        r.user_id AS RequestUserId,
        r.connection_id AS RequestConnectionId,
        r.open_transaction_count AS RequestOpenTransactionCount,
        transaction_id AS RequestTransactionId,
        r.cpu_time AS RequestCpuTime,
        r.total_elapsed_time AS RequestTotalElapedTime,
        r.scheduler_id AS RequestSchedulerThatIsSchedulingTheRequest,
        r.reads AS RequestReads,
        r.writes AS RequestWrites,
        r.logical_reads AS RequestLogicalReads,
        CASE
	 WHEN r.transaction_isolation_level = 0 THEN 'Unspecified'
	 WHEN r.transaction_isolation_level = 1 THEN 'Read Uncomitted'
	 WHEN r.transaction_isolation_level = 2 THEN 'Read Committed'
	 WHEN r.transaction_isolation_level = 5 THEN 'Repeatable'
	 WHEN r.transaction_isolation_level = 4 THEN 'Serializable'
	 WHEN r.transaction_isolation_level = 5 THEN 'Snapshot'
	 ELSE 'View here https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-exec-sessions-transact-sql?view=sql-server-2017 to find out'
	END As RequestTransactionIsolationLevel,
        r.lock_timeout AS RequestLockTimeout,
        r.deadlock_priority AS RequestDeadlockPriority,
        r.row_count AS RequestRowCount,
        r.prev_error AS RequestPreviousError,
        r.nest_level AS RequestNestLevel,
        r.granted_query_memory AS RequestQueryMemoryGrant,
        r.dop AS RequestDegreeOfParallelismForQuery,
        r.parallel_worker_count AS RequestParallelWorkerCount
    INTO #TempSessionsAndRequests
    FROM sys.dm_exec_sessions s
        JOIN sys.dm_exec_requests r on r.session_id = s.session_id

    IF @showSpidSesisonLoginInformation = 1 BEGIN

        SELECT SPID,
            SessionDatabase,
            SessionLoginName
		SessionNtUserName,
            SessionNtDomain,
            SessionNtDomain
		SessionLoginTime,
            SessionClient,
            SessionClientVersion,
            SessionIsUserProcess,
            SessionStatus,
            SessionTotalElapedTime,
            SessionRequestedStartTime,
            SessionRequestedEndTime,
            SessionLastSuccessfulLogon,
            SessionLastUnSuccessfulLogon
        FROM #TempSessionsAndRequests
        WHERE SPID = @@SPID

    END

    IF @showSpidSessionRuntimeStats = 1 BEGIN

        SELECT
            SPID,
            SessionDatabase,
            SessionLoginName,
            SessionStatus,
            SessionCpuTime,
            SessionMemoryUsage8KBPages,
            SessionReadsPerformed,
            SessionWritesPerformed,
            SessionLogicalReads,
            SessionTransactionIsolationLevel,
            SessionLockTimeout
		SessionDeadlockPriority,
            SessionRowCount,
            SessionPreviousError
        FROM #TempSessionsAndRequests
        WHERE SPID = @@SPID

    END

    IF @showSpidRequestRuntimeStats = 1 BEGIN

        SELECT
            SPID,
            RequestDatabase,
            RequestStartTime,
            RequestStatus,
            RequestOpenTransactionCount AS 'Open Trans Count',
            RequestTransactionId,
            RequestCpuTime,
            RequestTotalElapedTime,
            RequestReads,
            RequestWrites,
            RequestLogicalReads,
            RequestTransactionIsolationLevel,
            RequestLockTimeout,
            RequestDeadlockPriority,
            RequestRowCount,
            RequestPreviousError,
            RequestNestLevel,
            RequestParallelWorkerCount
        FROM #TempSessionsAndRequests
        WHERE SPID = @@SPID

    END

    IF @showSpidRequestWaitStat = 1 BEGIN

        SELECT
            SPID,
            SessionDatabase,
            RequestCommand,
            RequestBlockingSessionId,
            RequestWaitType,
            RequestWaitTime,
            RequestLastWaitType,
            RequestWaitResource
        FROM #TempSessionsAndRequests
        WHERE SPID = @@SPID

    END

    IF @showSpidRequestQuery = 1 BEGIN

        SELECT
            SPID,
            SessionDatabase,
            RequestCommand,
            sqlText.text As SqlText,
            substring
		  (REPLACE
			(REPLACE
			  (SUBSTRING
				(sqlText.text
				, (r.RequestStatementStartOffset/2) + 1
				, (
				   (CASE RequestStatementEndOffset
					  WHEN -1
					  THEN DATALENGTH(sqlText.text)  
					  ELSE r.RequestStatementEndOffset
					  END
						- r.RequestStatementStartOffset)/2) + 1)
		   , CHAR(10), ' '), CHAR(13), ' '), 1, 512)  AS 'Currently Executing',
            RequestQueryMemoryGrant,
            RequestCpuTime,
            RequestLogicalReads,
            RequestRowCount,
            RequestPreviousError,
            RequestDegreeOfParallelismForQuery,
            RequestStatementStartOffset,
            RequestStatementEndOffset,
            planHandle.query_plan
        FROM #TempSessionsAndRequests AS r
		CROSS APPLY sys.dm_exec_sql_text(r.RequestSqlHandle) AS sqlText
		CROSS APPLY sys.dm_exec_query_plan(r.RequestPlanHandle) AS planHandle
        WHERE SPID = @@SPID

    END

    DROP TABLE #TempSessionsAndRequests
END

IF @showDuration = 1 OR @showCpu = 1 OR @showIo = 1 OR @showMemory = 1 OR @showParallelism = 1 OR @showTotalDuration = 1 OR @showTotalExecutions = 1 BEGIN

    SELECT *
    INTO #tempQueryStoreRuntimeStats
    FROM sys.query_store_runtime_stats

    SELECT
        @@SPID AS SPID,
        qsp.plan_id,
        qsq.query_id,
        qsq.object_id,
        OBJECT_NAME(qsq.object_id) AS 'Database Object',
        ca_aggregate_runtime_stats.FirstExecutionTime,
        ca_aggregate_runtime_stats.LastExecutionTime,
        ca_runtime_executions.TotalExections AS TotalExections,
        FORMAT(ca_runtime_executions.TotalExections, '###,###,###') AS TotalExectionsAsString,
        ca_runtime_executions.TotalDuration AS TotalDuration,
        FORMAT(ca_runtime_executions.TotalDuration, '###,###,###') + ' ms' AS TotalDurationString,
        Convert(varchar(1000), FLOOR(ca_runtime_executions.TotalDuration/(10006060))) + ' h ' +
		Convert(varchar(1000), FLOOR(( ca_runtime_executions.TotalDuration%(10006060))/(100060))) + ' m ' +
		Convert(varchar(1000), FLOOR(((ca_runtime_executions.TotalDuration%(10006060))%(100060))/1000)) + ' s ' +
		Convert(varchar(1000), FLOOR(((ca_runtime_executions.TotalDuration%(10006060))%(100060))%1000)) + ' ms' AS TotalDurationInFormatAsString,

        ca_aggregate_runtime_stats.AvgDuration AS AvgDuration,
        CONVERT(VARCHAR(100), CAST(ca_aggregate_runtime_stats.AvgDuration AS FLOAT) / 1000) + ' ms' AS AvgDurationAsString,
        ca_aggregate_runtime_stats.LastDuration AS LastDuration,
        CONVERT(VARCHAR(100), CAST(ca_aggregate_runtime_stats.LastDuration AS FLOAT) / 1000) + ' ms' AS LastDurationAsString,
        ca_aggregate_runtime_stats.MinDuration AS MinDuration,
        CONVERT(VARCHAR(100), CAST(ca_aggregate_runtime_stats.MinDuration AS FLOAT) / 1000) + ' ms' AS MinDurationAsString,
        ca_aggregate_runtime_stats.MaxDuration AS MaxDuration,
        CONVERT(VARCHAR(100), CAST(ca_aggregate_runtime_stats.MaxDuration AS FLOAT) / 1000) + ' ms' AS MaxDurationAsString,
        LEN(qsqt.query_sql_text) AS SQLTextLength,
        qsqt.query_sql_text,
        ca_queries_for_plan.total_queries_for_plan AS 'Queries For Plan',
        ca_aggregate_runtime_stats.AvgRowCount,
        ca_aggregate_runtime_stats.LastRowCount,
        ca_aggregate_runtime_stats.MaxRowCount,
        ca_aggregate_runtime_stats.MinRowCount,
        ca_aggregate_runtime_stats.AvgCpuTime AS AvgCpuTime,
        CONVERT(VARCHAR(100), CAST(ca_aggregate_runtime_stats.AvgCpuTime AS FLOAT) / 1000) + ' ms' AS AvgCpuTimeAsString,
        ca_aggregate_runtime_stats.LastCpuTime AS LastCpuTime,
        CONVERT(VARCHAR(100), CAST(ca_aggregate_runtime_stats.LastCpuTime AS FLOAT) / 1000) + ' ms' AS LastCpuTimeAsString,
        ca_aggregate_runtime_stats.MinCpuTime AS MinCpuTime,
        CONVERT(VARCHAR(100), CAST(ca_aggregate_runtime_stats.MinCpuTime AS FLOAT) / 1000) + ' ms' AS MinCpuTimeAsString,
        ca_aggregate_runtime_stats.MaxCpuTime AS MaxCpuTime,
        CONVERT(VARCHAR(100), CAST(ca_aggregate_runtime_stats.MaxCpuTime AS FLOAT) / 1000) + ' ms' AS MaxCpuTimeAsString,
        ca_aggregate_runtime_stats.AvgMaxUsedMemory * 0.001 AS AvgMemoryInMegabytes,
        ca_aggregate_runtime_stats.LastMaxUsedMemory * 0.001 AS LastMemoryInMegabytes,
        ca_aggregate_runtime_stats.MinMaxUsedMemory * 0.001 AS MinMemoryInMegabytes,
        ca_aggregate_runtime_stats.MaxMaxUsedMemory * 0.001 AS MaxMemoryInMegabytes,
        ca_aggregate_runtime_stats.AvgDop AS AvgDegreeOfParallelism,
        ca_aggregate_runtime_stats.LastDop AS LastDegreeOfParallelism,
        ca_aggregate_runtime_stats.MinDop AS MinDegreeOfParallelism,
        ca_aggregate_runtime_stats.MaxDop AS MaxDegreeOfParallelism,
        ca_aggregate_runtime_stats.AvgLogicalIoReads,
        ca_aggregate_runtime_stats.LastLogicalIoReads,
        ca_aggregate_runtime_stats.MinLogicalIoReads,
        ca_aggregate_runtime_stats.MaxLogicalIoReads,
        ca_aggregate_runtime_stats.AvgLogicalIoWrites,
        ca_aggregate_runtime_stats.LastLogicalIoWrites,
        ca_aggregate_runtime_stats.MinLogicalIoWrites,
        ca_aggregate_runtime_stats.MaxLogicalIoWrites,
        ca_aggregate_runtime_stats.AvgPhysicalIoReads,
        ca_aggregate_runtime_stats.LastPhysicalIoReads,
        ca_aggregate_runtime_stats.MinPhysicalIoReads,
        ca_aggregate_runtime_stats.MaxPhysicalIoReads,
        ca_aggregate_runtime_stats.AvgNumPhysicalIoReads,
        ca_aggregate_runtime_stats.LastNumPhysicalIoReads,
        ca_aggregate_runtime_stats.MinNumPhysicalIoReads,
        ca_aggregate_runtime_stats.MaxNumPhysicalIoReads,
        CAST(qsp.query_plan AS XML) AS 'Execution Plan'
    INTO #QueryStoreData
    FROM sys.query_store_plan qsp (NOLOCK)
        INNER JOIN sys.query_store_query qsq (NOLOCK)
        ON qsp.query_id = qsq.query_id
        INNER JOIN sys.query_store_query_text qsqt (NOLOCK)
        ON qsq.query_text_id = qsqt.query_text_id
	CROSS APPLY
	(
		SELECT
            MAX(qrs.last_execution_time) AS LastExecutionTime, MIN(qrs.first_execution_time) AS FirstExecutionTime,
            AVG(qrs.avg_rowcount) AS AvgRowCount, MAX(qrs.last_rowcount) AS LastRowCount, MAX(qrs.max_rowcount) AS MaxRowCount, MIN(qrs.min_rowcount) AS MinRowCount,
            AVG(qrs.avg_duration) AS AvgDuration, MAX(qrs.last_duration) AS LastDuration, MAX(qrs.max_duration) AS MaxDuration, MIN(qrs.min_duration) AS MinDuration,
            AVG(qrs.avg_cpu_time) AS AvgCpuTime, MAX(qrs.last_cpu_time) AS LastCpuTime, MAX(qrs.max_cpu_time) AS MaxCpuTime, MIN(qrs.min_cpu_time) AS MinCpuTime,
            AVG(qrs.avg_query_max_used_memory) AS AvgMaxUsedMemory, MAX(qrs.last_query_max_used_memory) AS LastMaxUsedMemory, MAX(qrs.max_query_max_used_memory) AS MaxMaxUsedMemory, MIN(qrs.min_query_max_used_memory) AS MinMaxUsedMemory,
            AVG(qrs.avg_dop) AS AvgDop, MAX(qrs.last_dop) AS LastDop, MAX(qrs.max_dop) AS MaxDop, MIN(qrs.min_dop) AS MinDop,
            AVG(qrs.avg_logical_io_reads) AS AvgLogicalIoReads, MAX(qrs.last_logical_io_reads) AS LastLogicalIoReads, MAX(qrs.max_logical_io_reads) AS MaxLogicalIoReads, MIN(qrs.min_logical_io_reads) AS MinLogicalIoReads,
            AVG(qrs.avg_logical_io_writes) AS AvgLogicalIoWrites, MAX(qrs.last_logical_io_writes) AS LastLogicalIoWrites, MAX(qrs.max_logical_io_writes) AS MaxLogicalIoWrites, MIN(qrs.min_logical_io_writes) AS MinLogicalIoWrites,
            AVG(qrs.avg_physical_io_reads) AS AvgPhysicalIoReads, MAX(qrs.last_physical_io_reads) AS LastPhysicalIoReads, MAX(qrs.max_physical_io_reads) AS MaxPhysicalIoReads, MIN(qrs.min_physical_io_reads) AS MinPhysicalIoReads,
            AVG(qrs.avg_num_physical_io_reads) AS AvgNumPhysicalIoReads, MAX(qrs.last_num_physical_io_reads) AS LastNumPhysicalIoReads, MAX(qrs.max_num_physical_io_reads) AS MaxNumPhysicalIoReads, MIN(qrs.min_num_physical_io_reads) AS MinNumPhysicalIoReads
        FROM #tempQueryStoreRuntimeStats qrs (NOLOCK)
            INNER JOIN sys.query_store_runtime_stats_interval i on qrs.runtime_stats_interval_id = i.runtime_stats_interval_id
        WHERE qrs.plan_id = qsp.plan_id
            AND i.end_time >= @dt
        GROUP BY qrs.plan_id
	) ca_aggregate_runtime_stats
	CROSS APPLY
	(
		SELECT CONVERT(int, SUM(rs.avg_duration))*0.001 AS TotalDuration,
            SUM(rs.count_executions) AS TotalExections
        FROM #tempQueryStoreRuntimeStats rs (NOLOCK)
        WHERE rs.plan_id = qsp.plan_id
            AND rs.first_execution_time >= @dt
        GROUP BY rs.plan_id
	) ca_runtime_executions
	CROSS APPLY
	(
		SELECT COUNT(ca_qsp.query_id) AS total_queries_for_plan
        FROM sys.query_store_plan AS ca_qsp
        WHERE ca_qsp.plan_id = qsp.plan_id
        GROUP BY ca_qsp.plan_id
	) ca_queries_for_plan
    WHERE qsqt.query_sql_text NOT LIKE N'%sys.query_store%'
        AND qsqt.query_sql_text NOT LIKE N'%sys.dm%'
        AND (@plainId IS NULL OR qsp.plan_id = @plainId)
        AND (@queryId IS NULL OR qsp.query_id = @queryId)

    DROP TABLE #tempQueryStoreRuntimeStats;


    IF @showDuration = 1 BEGIN

        SELECT TOP(@top)
            SPID,
            plan_id,
            query_id,
            TotalExections,
            SQLTextLength,
            AvgDurationAsString,
            LastDurationAsString,
            MinDurationAsString,
            MaxDurationAsString,
            [Database Object],
            object_id,
            FirstExecutionTime,
            LastExecutionTime,
            query_sql_text,
            [Queries For Plan],
            [Execution Plan]
        FROM #QueryStoreData
        ORDER BY AvgDuration DESC

    END

    IF @showTotalDuration = 1 BEGIN

        SELECT TOP(@top)
            SPID,
            plan_id,
            query_id,
            TotalExections,
            SQLTextLength,
            TotalDuration,
            TotalDurationString,
            TotalDurationInFormatAsString,
            [Database Object],
            object_id,
            FirstExecutionTime,
            LastExecutionTime,
            query_sql_text,
            [Queries For Plan],
            [Execution Plan]
        FROM #QueryStoreData
        ORDER BY TotalDuration DESC

    END

    IF @showTotalExecutions = 1 BEGIN

        SELECT TOP(@top)
            SPID,
            plan_id,
            query_id,
            TotalExections,
            TotalExectionsAsString,
            SQLTextLength,
            [Database Object],
            object_id,
            FirstExecutionTime,
            LastExecutionTime,
            query_sql_text,
            [Queries For Plan],
            [Execution Plan]
        FROM #QueryStoreData
        ORDER BY TotalExections DESC

    END


    IF @showCpu = 1 BEGIN

        SELECT TOP(@top)
            SPID,
            plan_id,
            query_id,
            TotalExections,
            SQLTextLength,
            AvgCpuTimeAsString,
            LastCpuTimeAsString,
            MinCpuTimeAsString,
            MaxCpuTimeAsString,
            [Database Object],
            object_id,
            FirstExecutionTime,
            LastExecutionTime,
            query_sql_text,
            [Queries For Plan],
            [Execution Plan]
        FROM #QueryStoreData
        ORDER BY AvgCpuTime DESC

    END

    IF @showMemory = 1 BEGIN

        SELECT TOP(@top)
            SPID,
            plan_id,
            query_id,
            TotalExections,
            SQLTextLength,
            AvgMemoryInMegabytes,
            LastMemoryInMegabytes,
            MinMemoryInMegabytes,
            MaxMemoryInMegabytes,
            [Database Object],
            object_id,
            FirstExecutionTime,
            LastExecutionTime,
            query_sql_text,
            [Queries For Plan],
            [Execution Plan]
        FROM #QueryStoreData
        ORDER BY AvgMemoryInMegabytes DESC

    END

    IF @showParallelism = 1 BEGIN

        SELECT TOP(@top)
            SPID,
            plan_id,
            query_id,
            TotalExections,
            SQLTextLength,
            AvgDegreeOfParallelism,
            LastDegreeOfParallelism,
            MinDegreeOfParallelism,
            MaxDegreeOfParallelism,
            [Database Object],
            object_id,
            FirstExecutionTime,
            LastExecutionTime,
            query_sql_text,
            [Queries For Plan],
            [Execution Plan]
        FROM #QueryStoreData
        ORDER BY AvgDegreeOfParallelism DESC

    END

    IF @showIo = 1 BEGIN

        SELECT TOP(@top)
            SPID,
            plan_id,
            query_id,
            TotalExections,
            SQLTextLength,
            AvgLogicalIoReads,
            LastLogicalIoReads,
            MinLogicalIoReads,
            MaxLogicalIoReads,
            AvgLogicalIoWrites,
            LastLogicalIoWrites,
            MinLogicalIoWrites,
            MaxLogicalIoWrites,
            AvgPhysicalIoReads,
            LastPhysicalIoReads,
            MinPhysicalIoReads,
            MaxPhysicalIoReads,
            AvgNumPhysicalIoReads,
            LastNumPhysicalIoReads,
            MinNumPhysicalIoReads,
            MaxNumPhysicalIoReads,
            [Database Object],
            object_id,
            FirstExecutionTime,
            LastExecutionTime,
            query_sql_text,
            [Queries For Plan],
            [Execution Plan]
        FROM #QueryStoreData
        ORDER BY AvgLogicalIoReads DESC

    END

    DROP TABLE #QueryStoreData
END