create or replace function project.test_get_possible_owners() returns void as $$
    declare 
        i int;
    begin 
        FOR i IN 1..100 LOOP 
            PERFORM assert.not_null(users.add('login' || i, 'password' || i, 'Elephant Sam', 'samelephant82@gmail.com' || i, false));
        END LOOP;

        PERFORM users.delete(user_id) FROM postgres_ci.users ORDER BY user_id LIMIT 50;

        PERFORM assert.equal(50, (
                SELECT COUNT(*) FROM (SELECT user_id FROM project.get_possible_owners()) _
            )::int
        );

    end;
$$ language plpgsql security definer;