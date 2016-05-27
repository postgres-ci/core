create or replace function project.test_get_github_secret() returns void as $$
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
                'GitHub Secret'
            );

            IF assert.not_null(_project_id) THEN 

                PERFORM   
                    assert.equal('GitHub Secret', secret)
                FROM project.get_github_secret('postgres-ci/core');
  
            END IF;
        END IF;

    end;
$$ language plpgsql security definer;