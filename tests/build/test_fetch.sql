create or replace function build.test_fetch() returns void as $$
  declare 
        _project_id       int;
        _project_owner_id int;
        _build_id         int;
        _commit_id        int;
    begin 

        _project_owner_id = users.add('login', 'password', 'Elephant Sam', 'samelephant82@gmail.com', true);

        IF assert.not_null(_project_owner_id) THEN 

            _project_id = project.add(
                'project',
                _project_owner_id,
                'https://github.com/postgres-ci/core.git', 
                ''
            );

            IF assert.not_null(_project_id) THEN 

                _commit_id  = hook.commit(
                    (SELECT project_token FROM postgres_ci.projects WHERE project_id = _project_id),
                    'master',
                    encode(digest('commit' || clock_timestamp(), 'sha1'), 'hex'),
                    'message',
                    CURRENT_TIMESTAMP - '1 day'::interval,
                    'Elephant Sam',
                    'samelephant82@gmail.com',
                    'Elephant Sam',
                    'samelephant82@gmail.com'
                );

                PERFORM hook.commit(
                    (SELECT project_token FROM postgres_ci.projects WHERE project_id = _project_id),
                    'master',
                    encode(digest('commit' || clock_timestamp(), 'sha1'), 'hex'),
                    'message',
                    CURRENT_TIMESTAMP - '1 day'::interval,
                    'Elephant Sam',
                    'samelephant82@gmail.com',
                    'Elephant Sam',
                    'samelephant82@gmail.com'
                );

                IF assert.not_null(_commit_id) THEN 

                    _build_id = (SELECT build_id FROM postgres_ci.builds WHERE commit_id = _commit_id LIMIT 1);

                    IF assert.equal(_build_id, build_id) FROM build.fetch() THEN 

                        PERFORM assert.not_equal(_build_id, build_id) FROM build.fetch();

                        PERFORM build.fetch();

                        PERFORM assert.true(NOT FOUND);

                    END IF;

                END IF;

            END IF;

        END IF;
    end;
$$ language plpgsql security definer;