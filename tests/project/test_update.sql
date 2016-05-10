create or replace function project.test_update() returns void as $$
    declare
        _project_id       int;
        _project_name     text;
        _project_owner_id int;
    begin 
        _project_name     = 'New project ' || random();

        _project_owner_id = users.add('login', 'password', 'Elephant Sam', 'samelephant82@gmail.com', true);

        IF assert.not_null(_project_owner_id) THEN 

            _project_id = project.add(
                _project_name,
                _project_owner_id,
                'https://github.com/postgres-ci/core.git', 
                'Ho-Ho-Ho'
            );

            IF assert.not_null(_project_id) THEN 

                PERFORM   
                    assert.equal(_project_name,      project_name),
                    assert.equal('postgres-ci/core', github_name),
                    assert.equal('Ho-Ho-Ho',         github_secret)
                FROM postgres_ci.projects 
                WHERE project_id = _project_id;
  
            END IF;

            IF assert.exception(
                $sql$ SELECT project.update(-1, '', 0, '', '') $sql$, 
                exception_message  := 'NOT_FOUND',
                exception_sqlstate := 'P0002'
            ) THEN 

                PERFORM project.update(
                    _project_id,
                    'UPDATE_' || _project_name,
                    _project_owner_id,
                    'https://github.com/postgres-ci/core.git', 
                    'Ho-Ho-Ho2'
                );

                PERFORM   
                    assert.equal('UPDATE_' || _project_name, project_name),
                    assert.equal('postgres-ci/core', github_name),
                    assert.equal('Ho-Ho-Ho2',        github_secret)
                FROM postgres_ci.projects 
                WHERE project_id = _project_id;
            END IF;

        END IF;

    end;
$$ language plpgsql security definer;



