\i project/test_github_name.sql
\i users/add.sql


select assert.add_test('project', 'test_github_name');
select assert.add_test('users', 'test_add');

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