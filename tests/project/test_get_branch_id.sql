create or replace function project.test_get_branch_id() returns void as $$
    declare 
        _project_id       int;
        _project_owner_id int;
        _branch           text; 
        _branch_id        int;
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

                IF assert.true(NOT EXISTS(
                        SELECT null FROM postgres_ci.branches WHERE project_id = _project_id AND branch = 'master'
                    )
                ) THEN 

                    _branch_id = project.get_branch_id(_project_id, 'master');

                    IF assert.not_null(_branch_id) THEN 

                        PERFORM assert.equal(_branch_id,     project.get_branch_id(_project_id, 'master'));
                        PERFORM assert.not_equal(_branch_id, project.get_branch_id(_project_id, 'master2'));

                    END IF;

                END IF;

            END IF;

        END IF;
    end;
$$ language plpgsql security definer;
