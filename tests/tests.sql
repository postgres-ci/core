\i auth/test_login.sql
\i auth/test_gc.sql
\i auth/test_logout.sql
\i auth/test_get_user.sql
\i build/test_new.sql
\i build/test_accept.sql
\i build/test_fetch.sql
\i build/test_start.sql
\i build/test_add_part.sql
\i build/test_stop.sql
\i hook/test_commit.sql
\i hook/test_push.sql
\i hook/test_github_push.sql
\i project/test_add.sql
\i project/test_get.sql
\i project/test_update.sql
\i project/test_delete.sql
\i project/test_list.sql
\i project/test_add_commit.sql
\i project/test_github_name.sql
\i project/test_get_github_secret.sql
\i project/test_get_branch_id.sql
\i project/test_get_possible_owners.sql
\i users/test_add.sql
\i users/test_get.sql
\i users/test_update.sql
\i users/test_delete.sql
\i users/test_list.sql
\i notification/test_update_method.sql
\i notification/test_bind_with_telegram.sql
\i notification/test_find_user_by_telegram_username.sql
\i password/test_check.sql
\i password/test_change.sql
\i password/test_reset.sql
\i postgres_ci/test_sha1.sql


do $$ declare
    namespace text;
    procedure text;
begin
    FOR namespace, procedure IN VALUES 
        ('auth',        'test_login'),
        ('auth',        'test_logout'),
        ('auth',        'test_gc'),
        ('auth',        'test_get_user'),
        ('build',       'test_new'),
        ('build',       'test_accept'),
        ('build',       'test_fetch'),
        ('build',       'test_start'),
        ('build',       'test_add_part'),
        ('build',       'test_stop'),
        ('hook',        'test_commit'),
        ('hook',        'test_push'),
        ('hook',        'test_github_push'),
        ('project',     'test_add'),
        ('project',     'test_get'),
        ('project',     'test_update'),
        ('project',     'test_delete'),
        ('project',     'test_add_commit'),
        ('project',     'test_get_github_secret'),
        ('project',     'test_github_name'),
        ('project',     'test_get_branch_id'),
        ('project',     'test_get_possible_owners'),
        ('project',     'test_list'),
        ('users',       'test_add'),
        ('users',       'test_get'),
        ('users',       'test_update'),
        ('users',       'test_delete'),
        ('users',       'test_list'),
        ('notification','test_update_method'),
        ('notification','test_bind_with_telegram'),
        ('notification','test_find_user_by_telegram_username'),
        ('password',    'test_check'),
        ('password',    'test_change'),
        ('password',    'test_reset'),
        ('postgres_ci', 'test_sha1')
    LOOP 
        PERFORM assert.add_test(namespace, procedure);
    END LOOP;
end$$;