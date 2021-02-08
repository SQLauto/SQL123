DECLARE @showOnlyCurrentRequest BIT = 1;
DECLARE @showMyCurrentSession BIT = 0;
DECLARE @queryLike NVARCHAR(MAX) = NULL;
-- You can kill a session with the command below.
-- KILL { session ID | UOW } [ WITH STATUSONLY ]


SELECT
IIF(req.session_id IS NULL, 'FALSE', 'TRUE') AS IsCurrentRequest,
@@SPID MyCurrentSessionId,
sdes.session_id,
req.command AS SQLCommandType,
req.status AS SQLCommandStatus,
CAST(sdest.Query AS XML) XmlQuery,
req.percent_complete AS '% Complete',
req.estimated_completion_time AS EstimatedCompletionTime,
req.scheduler_id AS ScheduleId,
sdest.DatabaseName,
t.resource_type AS TransactionResourceType,
t.resource_subtype AS TransactionResourceSubType,
t.resource_subtype AS TransactionResourceDescription,
t.request_mode AS TransactionRequestMode,
t.request_type AS TransactionRequestType,
t.request_status AS TransactionRequestStatus,
t.request_reference_count AS TransactionRequestReferenceCount,
t.request_owner_type AS TransactionRequestOwerType,
req.granted_query_memory AS GrantedQueryMemoryNumberOfPagesAllocated,
req.start_time AS RequestStartDateTime,
req.total_elapsed_time AS TotalElapsedTimeInMillisecondsRequest,
sdes.last_request_start_time AS LastSessionStartDateTime,
sdes.last_request_end_time AS LastSessionEndDateTime,
sdes.row_count,
req.wait_time,
req.wait_type,
req.wait_resource,
req.cpu_time,
sdes.host_name, 
sdes.program_name,
sdes.client_interface_name,
sdes.login_name,
sdes.login_time,
sdes.nt_domain,
sdes.nt_user_name,
sdec.client_net_address,
sdec.local_net_address,
sdest.ObjectName
FROM sys.dm_exec_sessions AS sdes
INNER JOIN sys.dm_exec_connections AS sdec ON sdec.session_id = sdes.session_id
LEFT JOIN  sys.dm_tran_locks t ON sdes.session_id = t.request_session_id
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
LEFT  JOIN sys.dm_exec_requests req on sdes.session_id = req.session_id
WHERE 
(
    (req.session_id IS NOT NULL OR IIF(req.session_id IS NULL, 0, 1) = @showOnlyCurrentRequest)
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

