DECLARE @top INT = 10;

SELECT TOP(10)
    qt.query_sql_text,
    CAST(query_plan AS XML) AS 'Execution Plan',
    rs.avg_duration
FROM sys.query_store_plan qp
    INNER JOIN sys.query_store_query q
    ON qp.query_id = q.query_id
    INNER JOIN sys.query_store_query_text qt
    ON q.query_text_id = qt.query_text_id
    INNER JOIN sys.query_store_runtime_stats rs
    ON qp.plan_id = rs.plan_id
WHERE query_plan NOT LIKE '%sys.query_store%'
ORDER BY rs.avg_duration DESC;