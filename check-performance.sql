-- MAAIgnore
DECLARE @showOnlyCurrentRequest BIT = 1;
DECLARE @showMyCurrentSession BIT = 0;
DECLARE @queryLike NVARCHAR(MAX) = NULL;
-- You can kill a session with the command below.
-- KILL { session ID | UOW } [ WITH STATUSONLY ]

IF SERVERPROPERTY('Edition') = 'SQL Azure' BEGIN
    SELECT TOP 1 
    dtu_limit AS 'DTU Limit',
    cpu_limit AS 'CPU Limit',
    avg_instance_cpu_percent AS 'Avg Cpu %',
    avg_data_io_percent AS 'Avg IO %',
    avg_log_write_percent AS 'Avg Write %',
    avg_memory_usage_percent AS 'Avg Memory %',
    avg_log_write_percent AS 'Avg Log Write %',
    max_worker_percent AS 'Max Worker %',
    max_session_percent AS 'Max Session %'
    FROM sys.dm_db_resource_stats
    ORDER BY end_time DESC
END

SELECT DISTINCT
DB_NAME() AS DatabaseName, 
r.blocking_session_id AS BlockerSessionId,
r.session_id AS SessionIdBlocked,
CONVERT(VARCHAR(100), FLOOR(sp.waittime/1000.0/60/60/24)) + 'd'
+ ':' + CONVERT(VARCHAR(100), FLOOR(sp.waittime/1000.0/60/60%24)) + 'h'
+ ':' + CONVERT(VARCHAR(100), FLOOR(sp.waittime/1000.0/60%60)) + 'm'
+ ':' + CONVERT(VARCHAR(100), FLOOR(sp.waittime/1000.0%60)) + 's'
+ ':' + CONVERT(VARCHAR(100), sp.waittime/10000 % 1000) + 'ms'
AS LockWaitTime,
tl.resource_type AS ResourceType,
ca_count_resource_type.ResourceLockTypeCount,
tl.resource_subtype AS ResourceSubType,
tl.request_type AS TransactionType,
tl.request_status AS TransactionStatus,
tl.resource_lock_partition AS ResourceLockPartition,
CASE
	WHEN tl.request_mode = 'Sch-S' THEN 'Sch-S - Schema stability'
	WHEN tl.request_mode = 'Sch-M' THEN 'Sch-M - Schema modification'
	WHEN tl.request_mode = 'S' THEN 'S - Shared'
	WHEN tl.request_mode = 'U' THEN 'U - Update'
	WHEN tl.request_mode = 'X' THEN 'X - Exclusive'
	WHEN tl.request_mode = 'IS' THEN 'IS - Intent Shared'
	WHEN tl.request_mode = 'IU' THEN 'IU - Intent Update'
	WHEN tl.request_mode = 'IX' THEN 'IS - Intent Exclusive'
	WHEN tl.request_mode = 'SIU' THEN 'SIU - Shared Intent Update'
	WHEN tl.request_mode = 'SIX' THEN 'SIX - Shared Intent Exclusive'
	WHEN tl.request_mode = 'UIX' THEN 'UIX - Update Intent Exclusive'
	WHEN tl.request_mode = 'BU' THEN 'BU - Used by bulk operations'
	WHEN tl.request_mode = 'RangeS_S' THEN 'RangeS_S - Shared Key-Range & Shared Resource lock'
	WHEN tl.request_mode = 'RangeS_U' THEN 'RangeS_U - Shared Key-Range & Update Resource lock'
	WHEN tl.request_mode = 'RangeI_N' THEN 'RangeI_N - Insert Key-Range & Null Resource lock'
	WHEN tl.request_mode = 'RangeI_S' THEN 'RangeI_S - Key-Range Conversion lock, created by an overlap of RangeI_N & S locks'
	WHEN tl.request_mode = 'RangeI_U' THEN 'RangeI_U - Key-Range Conversion lock, created by an overlap of RangeI_N & U locks'
	WHEN tl.request_mode = 'RangeI_X' THEN 'RangeI_X - Key-Range Conversion lock, created by an overlap of RangeI_N & X locks'
	WHEN tl.request_mode = 'RangeX_S' THEN 'RangeX_S - Key-Range Conversion lock, created by an overlap of RangeI_N and RangeS_S locks'
	WHEN tl.request_mode = 'RangeX_U' THEN 'RangeX_U - Key-Range Conversion lock, created by an overlap of RangeI_N and RangeS_U locks'
	WHEN tl.request_mode = 'RangeX_X' THEN 'RangeX_X - Exclusive Key-Range and Exclusive Resource lock. This is a conversion lock used when updating a key in a range'
	ELSE tl.request_mode + ' - Unknown'
END AS TransactionMode,
tl.request_owner_type AS OwnerType,
tl.request_reference_count AS ReferenceCount
FROM sys.dm_tran_locks tl
JOIN sys.dm_exec_requests r ON tl.request_session_id = r.blocking_session_id
JOIN sys.sysprocesses sp ON r.session_id = sp.spid
CROSS APPLY
(
	SELECT COUNT(DISTINCT tl2.resource_associated_entity_id) AS ResourceLockTypeCount
	FROM sys.dm_tran_locks tl2
	JOIN sys.dm_exec_requests r2 ON tl2.request_session_id = r2.blocking_session_id
	WHERE tl2.resource_type = tl.resource_type
	AND r2.blocking_session_id = r.blocking_session_id
) ca_count_resource_type

SELECT 
IIF(req.session_id IS NULL, 'FALSE', 'TRUE') AS IsCurrentRequest,
sdest.DatabaseName,
@@SPID MyCurrentSessionId,
sdes.session_id as SessionId,
req.blocking_session_id AS BlockingSessionId,
req.open_transaction_count AS OpenTransactions,
req.command AS SQLCommandType,
req.status AS SQLCommandStatus,
d.snapshot_isolation_state AS SnapshotIsolationState,
d.snapshot_isolation_state_desc AS SnapshotIsolationStateDesc, 
d.is_read_committed_snapshot_on AS IsReadCommittedSnapshotOn,
CAST(sdest.Query AS XML) XmlQuery,
req.percent_complete AS '% Complete',
req.estimated_completion_time AS EstimatedCompletionTime,
req.scheduler_id AS ScheduleId,
req.start_time AS RequestStartDateTime,
CONVERT(VARCHAR(100), FLOOR(sp.waittime/1000.0/60/60/24)) + 'd'
+ ':' + CONVERT(VARCHAR(100), FLOOR(sp.waittime/1000.0/60/60%24)) + 'h'
+ ':' + CONVERT(VARCHAR(100), FLOOR(sp.waittime/1000.0/60%60)) + 'm'
+ ':' + CONVERT(VARCHAR(100), FLOOR(sp.waittime/1000.0%60)) + 's'
+ ':' + CONVERT(VARCHAR(100), sp.waittime/10000 % 1000) + 'ms'
AS RequestTotalElapsedTime,
CONVERT(VARCHAR(100), FLOOR(sp.waittime/1000.0/60/60/24)) + 'd'
+ ':' + CONVERT(VARCHAR(100), FLOOR(sp.waittime/1000.0/60/60%24)) + 'h'
+ ':' + CONVERT(VARCHAR(100), FLOOR(sp.waittime/1000.0/60%60)) + 'm'
+ ':' + CONVERT(VARCHAR(100), FLOOR(sp.waittime/1000.0%60)) + 's'
+ ':' + CONVERT(VARCHAR(100), sp.waittime/10000 % 1000) + 'ms'
AS LockWaitTime,
t.resource_type AS TransactionResourceType,
t.resource_subtype AS TransactionResourceSubType,
t.resource_subtype AS TransactionResourceDescription,
CASE
	WHEN t.request_mode = 'Sch-S' THEN 'Sch-S - Schema stability'
	WHEN t.request_mode = 'Sch-M' THEN 'Sch-M - Schema modification'
	WHEN t.request_mode = 'S' THEN 'S - Shared'
	WHEN t.request_mode = 'U' THEN 'U - Update'
	WHEN t.request_mode = 'X' THEN 'X - Exclusive'
	WHEN t.request_mode = 'IS' THEN 'IS - Intent Shared'
	WHEN t.request_mode = 'IU' THEN 'IU - Intent Update'
	WHEN t.request_mode = 'IX' THEN 'IS - Intent Exclusive'
	WHEN t.request_mode = 'SIU' THEN 'SIU - Shared Intent Update'
	WHEN t.request_mode = 'SIX' THEN 'SIX - Shared Intent Exclusive'
	WHEN t.request_mode = 'UIX' THEN 'UIX - Update Intent Exclusive'
	WHEN t.request_mode = 'BU' THEN 'BU - Used by bulk operations'
	WHEN t.request_mode = 'RangeS_S' THEN 'RangeS_S - Shared Key-Range & Shared Resource lock'
	WHEN t.request_mode = 'RangeS_U' THEN 'RangeS_U - Shared Key-Range & Update Resource lock'
	WHEN t.request_mode = 'RangeI_N' THEN 'RangeI_N - Insert Key-Range & Null Resource lock'
	WHEN t.request_mode = 'RangeI_S' THEN 'RangeI_S - Key-Range Conversion lock, created by an overlap of RangeI_N & S locks'
	WHEN t.request_mode = 'RangeI_U' THEN 'RangeI_U - Key-Range Conversion lock, created by an overlap of RangeI_N & U locks'
	WHEN t.request_mode = 'RangeI_X' THEN 'RangeI_X - Key-Range Conversion lock, created by an overlap of RangeI_N & X locks'
	WHEN t.request_mode = 'RangeX_S' THEN 'RangeX_S - Key-Range Conversion lock, created by an overlap of RangeI_N and RangeS_S locks'
	WHEN t.request_mode = 'RangeX_U' THEN 'RangeX_U - Key-Range Conversion lock, created by an overlap of RangeI_N and RangeS_U locks'
	WHEN t.request_mode = 'RangeX_X' THEN 'RangeX_X - Exclusive Key-Range and Exclusive Resource lock. This is a conversion lock used when updating a key in a range'
	ELSE t.request_mode + ' - Unknown'
END AS TransactionMode,
t.resource_lock_partition AS TransactonResourceLockPartition,
t.request_type AS TransactionType,
t.request_status AS TransactionStatus,
t.request_reference_count AS TransactionReferenceCount,
t.request_owner_type AS TransactionOwerType,
req.transaction_id AS TransactionId,
CASE
	WHEN req.transaction_isolation_level = 0 THEN '0 - Unspecified'
	WHEN req.transaction_isolation_level = 1 THEN '1 - ReadUncomitted'
	WHEN req.transaction_isolation_level = 2 THEN '2 - ReadCommitted'
	WHEN req.transaction_isolation_level = 3 THEN '3 - Repeatable'
	WHEN req.transaction_isolation_level = 4 THEN '4 - Serializable'
	WHEN req.transaction_isolation_level = 5 THEN '5 - Snapshot'
	ELSE CAST(req.transaction_isolation_level as NCHAR(1)) + ' - Unknown'
END AS TransactionIsolationLevel,
FORMAT(req.granted_query_memory, N'N0') AS GrantedQueryMemoryNumberOfPagesAllocated,
sdes.last_request_start_time AS LastSessionStartDateTime,
sdes.last_request_end_time AS LastSessionEndDateTime,
req.wait_time,
req.wait_type,
req.wait_resource,
req.writes,
req.reads,
req.logical_reads,
req.row_count,
FORMAT(mg.ideal_memory_kb/1024, N'N0') AS IdealMemoryInMb,
FORMAT(mg.requested_memory_kb/1024, N'N0') AS RequestedMemoryInMb,
FORMAT(mg.granted_memory_kb/1024, N'N0') AS GrantedMemoryInMb,
mg.grant_time AS GrantTime,
FORMAT(mg.query_cost, N'N0') AS QueryCost,
req.cpu_time AS CPUTime,
sdes.host_name AS HostName, 
sdes.program_name AS ProgramName,
sdes.client_interface_name,
sdes.login_name,
sdes.login_time,
sdes.nt_domain,
sdes.nt_user_name,
sdec.client_net_address,
sdec.local_net_address
FROM sys.dm_exec_sessions AS sdes
JOIN sys.databases d ON sdes.database_id = d.database_id
LEFT JOIN sys.sysprocesses sp ON sdes.session_id = sp.spid
JOIN sys.dm_exec_connections AS sdec ON sdec.session_id = sdes.session_id
LEFT JOIN  sys.dm_tran_locks t ON sdes.session_id = t.request_session_id
LEFT JOIN sys.dm_exec_query_memory_grants mg ON sdes.session_id = mg.session_id
CROSS APPLY 
(
    SELECT DB_NAME(dbid) AS DatabaseName ,OBJECT_ID(objectid) AS ObjectName,
           ISNULL
           (
               (
                   SELECT TEXT AS [processing-instruction(definition)]
                   FROM sys.dm_exec_sql_text(sdec.most_recent_sql_handle)
                   FOR XML PATH(''), 
                   TYPE
                ), 
                ''
            ) AS Query
    FROM sys.dm_exec_sql_text(sdec.most_recent_sql_handle)
) sdest
LEFT JOIN sys.dm_exec_requests req on sdes.session_id = req.session_id
WHERE 
(
    ISNULL(req.session_id, 0) = @showOnlyCurrentRequest
    OR req.session_id IS NOT NULL
)
AND 
(
    (sdes.session_id <> @@SPID AND @showMyCurrentSession = 0)
    OR @showMyCurrentSession = 1
)
AND
(
    (@queryLike IS NOT NULL AND CAST(sdest.Query AS NVARCHAR(MAX)) LIKE '%' + @queryLike + '%')
    OR @queryLike IS NULL
)
ORDER BY req.total_elapsed_time, sdec.session_id

