create or replace function project.test_get() returns void as $$
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

                PERFORM users.add('possible', 'owner', '-', 'possible@owner.com', true);

                PERFORM   
                    assert.equal(_project_name,      project_name),
                    assert.equal('Ho-Ho-Ho',         github_secret),
                    assert.equal(_project_owner_id,  project_owner_id),
                    assert.equal(2, jsonb_array_length(possible_owners))
                FROM project.get(_project_id);
  
            END IF;
        END IF;

        PERFORM assert.exception(
            $sql$ SELECT project.get(-1) $sql$, 
            exception_message  := 'NOT_FOUND',
            exception_sqlstate := 'P0002'
        );

    end;
$$ language plpgsql security definer;



