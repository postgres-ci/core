create or replace function build.test_stop() returns void as $$
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

                IF assert.not_null(_commit_id) THEN 

                    _build_id = (SELECT build_id FROM postgres_ci.builds WHERE commit_id = _commit_id LIMIT 1);

                    PERFORM assert.exception(
                        $sql$ SELECT build.stop($sql$ || _build_id || $sql$, '', '') $sql$, 
                        exception_message  := 'NOT_FOUND',
                        exception_sqlstate := 'P0002'
                    );
                        
                    IF assert.true(build.accept(_build_id)) THEN 

                        PERFORM build.start(_build_id);
                    
                        PERFORM build.stop(_build_id, 'config', '');

                        PERFORM assert.exception(
                            $sql$ SELECT build.stop($sql$ || _build_id || $sql$, '', '') $sql$, 
                            exception_message  := 'NOT_FOUND',
                            exception_sqlstate := 'P0002'
                        );

                        PERFORM 
                            assert.equal('config',  config),
                            assert.equal('success', status)
                        FROM postgres_ci.builds
                        WHERE build_id = _build_id;

                        PERFORM assert.true(FOUND);

                    END IF;
                END IF;

                -- errors

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

                IF assert.not_null(_commit_id) THEN 

                    _build_id = (SELECT build_id FROM postgres_ci.builds WHERE commit_id = _commit_id LIMIT 1);

                    PERFORM assert.exception(
                        $sql$ SELECT build.stop($sql$ || _build_id || $sql$, '', '') $sql$, 
                        exception_message  := 'NOT_FOUND',
                        exception_sqlstate := 'P0002'
                    );
                        
                    IF assert.true(build.accept(_build_id)) THEN 

                        PERFORM build.start(_build_id);
                    
                        PERFORM build.stop(_build_id, 'config', 'Error');

                        PERFORM assert.exception(
                            $sql$ SELECT build.stop($sql$ || _build_id || $sql$, '', '') $sql$, 
                            exception_message  := 'NOT_FOUND',
                            exception_sqlstate := 'P0002'
                        );

                        PERFORM 
                            assert.equal('config',  config),
                            assert.equal('Error', error),
                            assert.equal('failed', status)
                        FROM postgres_ci.builds
                        WHERE build_id = _build_id;

                        PERFORM assert.true(FOUND);

                    END IF;
                END IF;

            END IF;

        END IF;
    end;
$$ language plpgsql security definer;