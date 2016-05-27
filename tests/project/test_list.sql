create or replace function project.test_list() returns void as $$
    declare 
        i int;
        _project_owner_id int;
    begin 

        _project_owner_id = users.add('login', 'password', 'Elephant Sam', 'samelephant82@gmail.com', true);

        IF assert.not_null(_project_owner_id) THEN 

            FOR i IN 1..100 LOOP 
                PERFORM assert.not_null(project.add('P' || i, _project_owner_id, 'repo' || i, ''));
            END LOOP;
        END IF;

        IF assert.equal(100, (SELECT COUNT(*) FROM (SELECT project_id FROM project.list()) _ )::int) THEN 

            PERFORM project.delete(project_id) FROM postgres_ci.projects ORDER BY project_id LIMIT 50;

            PERFORM assert.equal(50, (SELECT COUNT(*) FROM (SELECT project_id FROM project.list()) _ )::int);
        END IF;

    end;
$$ language plpgsql security definer;