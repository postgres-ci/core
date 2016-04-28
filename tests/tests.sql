\i auth/test_login.sql
\i auth/test_logout.sql
\i auth/test_get_user.sql
\i project/test_add.sql
\i project/test_github_name.sql
\i users/test_add.sql
\i users/test_delete.sql

do $$ declare
    namespace text;
    procedure text;
begin
    FOR namespace, procedure IN VALUES 
        ('auth',    'test_login'),
        ('auth',    'test_logout'),
        ('auth',    'test_get_user'),
        ('project', 'test_add'),
        ('project', 'test_github_name'),
        ('users',   'test_add'),
        ('users',   'test_delete')

    LOOP 
        PERFORM assert.add_test(namespace, procedure);
    END LOOP;
end$$;

