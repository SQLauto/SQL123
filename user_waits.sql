SELECT w.session_id
, w.wait_duration_ms
, w.wait_type
, w.blocking_session_id
, w.resource_description
, s.program_name
, t.text
, t.dbid
, s.cpu_time
, s.memory_usage
FROM sys.dm_os_waiting_tasks w
    INNER JOIN sys.dm_exec_sessions s
    ON w.session_id = s.session_id
    INNER JOIN sys.dm_exec_requests r
    ON s.session_id = r.session_id
OUTER APPLY sys.dm_exec_sql_text (r.sql_handle) t
WHERE s.is_user_process = 1