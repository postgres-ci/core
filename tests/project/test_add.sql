create or replace function project.test_add() returns void as $$
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

        END IF;

        PERFORM assert.exception(
            $sql$ SELECT project.add('project', $sql$ || _project_owner_id || $sql$, 'https://github.com/postgres-ci/core.git', '') $sql$, 
            exception_table      := 'projects',
            exception_schema     := 'postgres_ci',
            exception_constraint := 'udx_is_github_repo'
        );

        PERFORM assert.exception(
            $sql$ SELECT project.add('project', -1, 'https://github.com/' || random(), '') $sql$, 
            exception_schema     := 'postgres_ci',
            exception_sqlstate   := '23503',
            exception_constraint := 'fk_project_owner_id'
        );
    end;
$$ language plpgsql security definer;



