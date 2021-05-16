    mg.requested_memory_kb/1024 AS RequestedMemoryInMb,
    mg.granted_memory_kb/1024 AS GrantedMemoryInMb,
    LEFT JOIN sys.dm_exec_query_memory_grants mg ON mg.plan_handle = cp.plan_handle