create or replace function build.test_add_part() returns void as $$
  declare 
        _project_id       int;
        _project_owner_id int;
        _build_id         int;
        _commit_id        int;
        _part_id          int;
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

                        
                    IF assert.true(build.accept(_build_id)) THEN 

                        PERFORM build.start(_build_id);
                    
                        _part_id = build.add_part(
                            _build_id,
                            'version:42',
                            'image',
                            'container_id',
                            'output',
                            CURRENT_TIMESTAMP,
                            '[]'
                        );

                        IF assert.not_null(_part_id) THEN 

                            PERFORM 
                                assert.equal(_build_id,      build_id),
                                assert.equal('image',        image),
                                assert.equal('container_id', container_id),
                                assert.equal('version:42',   version),
                                assert.equal('output',       output),
                                assert.true(success)
                            FROM postgres_ci.parts 
                            WHERE part_id = _part_id;

                            PERFORM assert.true(FOUND);

                            PERFORM assert.equal(0, (SELECT COUNT(*) FROM postgres_ci.tests WHERE part_id = _part_id)::int);
                        END IF;


                        _part_id = build.add_part(
                            _build_id,
                            'version:42',
                            'image',
                            'container_id',
                            'output',
                            CURRENT_TIMESTAMP,
                            '[{"function" : "fn", "duration" : 0.42, "errors" : []}, {"function" : "fn2", "duration" : 0.42, "errors" : [{"message" : ""}]}]'
                        );

                        IF assert.not_null(_part_id) THEN 

                            PERFORM 
                                assert.equal(_build_id,      build_id),
                                assert.equal('image',        image),
                                assert.equal('container_id', container_id),
                                assert.equal('version:42',   version),
                                assert.equal('output',       output),
                                assert.false(success)
                            FROM postgres_ci.parts 
                            WHERE part_id = _part_id;

                            PERFORM assert.true(FOUND);


                            PERFORM 
                                assert.equal(2, COUNT(*)::int),
                                assert.equal(1, (COUNT(*) FILTER (WHERE jsonb_array_length(errors) > 0))::int),
                                assert.equal(1, (COUNT(*) FILTER (WHERE jsonb_array_length(errors) = 0))::int)
                            FROM postgres_ci.tests WHERE part_id = _part_id;

                            PERFORM assert.true(FOUND);

                            PERFORM build.stop(_build_id, 'config', '');

                            PERFORM 
                                assert.equal('config',  config),
                                assert.equal('failed', status)
                            FROM postgres_ci.builds
                            WHERE build_id = _build_id;

                            PERFORM assert.true(FOUND);
                        END IF;

                    END IF;
                END IF;

            END IF;

        END IF;
    end;
$$ language plpgsql security definer; 