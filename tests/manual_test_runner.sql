-- :~/tests$ psql -d postgres_ci < manual_test_runner.sql
\i tests.sql

select 
    namespace || '.' || procedure as func,
    case 
        when array_length(errors, 1) is null 
        then 'PASS'
        else 'FAIL' 
    end 
    as result,
    to_json(errors) as errors,
    extract(epoch from finished_at - started_at) || 's' as duration
from  assert.test_runner();

\i coverage.sql;