WITH coverage AS (
    SELECT 
        namespace.nspname || '.' || func.proname AS func,
        CASE WHEN tests.proname IS NOT NULL 
            THEN '+' 
            ELSE '-' 
        END AS covered
    FROM pg_proc func
    JOIN pg_namespace namespace ON func.pronamespace = namespace.oid
    LEFT JOIN pg_proc tests     ON func.pronamespace = tests.pronamespace 
        AND func.proname = RIGHT(tests.proname, -5)
    WHERE namespace.nspname NOT LIKE 'pg_%'
    AND   namespace.nspname NOT IN ('assert', 'information_schema')
    AND   func.proname      NOT LIKE 'test_%'
    AND   func.prolang      NOT IN (12, 13) -- @see pg_language
    ORDER BY covered DESC, func
)
SELECT func, covered FROM coverage
UNION ALL (
    SELECT 'Coverage: ', (
        SELECT 
            (
                (
                    (COUNT(*) FILTER (WHERE covered = '+'))::numeric / COUNT(*)::numeric
                ) * 100
            )::int
        FROM coverage
    )::text || '% of functions'
);