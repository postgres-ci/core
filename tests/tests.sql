\i auth/test_login.sql
\i auth/test_logout.sql
\i auth/test_get_user.sql
\i hook/test_commit.sql
\i project/test_add.sql
\i project/test_update.sql
\i project/test_add_commit.sql
\i project/test_github_name.sql
\i project/test_get_branch_id.sql
\i users/test_add.sql
\i users/test_update.sql
\i users/test_delete.sql
\i postgres_ci/test_sha1.sql


do $$ declare
    namespace text;
    procedure text;
begin
    FOR namespace, procedure IN VALUES 
        ('auth',        'test_login'),
        ('auth',        'test_logout'),
        ('auth',        'test_get_user'),
        ('hook',        'test_commit'),
        ('project',     'test_add'),
        ('project',     'test_update'),
        ('project',     'test_add_commit'),
        ('project',     'test_github_name'),
        ('project',     'test_get_branch_id'),
        ('users',       'test_add'),
        ('users',       'test_update'),
        ('users',       'test_delete'),
        ('postgres_ci', 'test_sha1')
    LOOP 
        PERFORM assert.add_test(namespace, procedure);
    END LOOP;
end$$;