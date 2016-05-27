create or replace function users.test_list() returns void as $$
    declare 
        i int;
        q text;
    begin 

        FOR i IN 1..99 LOOP 
            PERFORM assert.not_null(users.add('login' || i, 'password' || i, 'Elephant Sam', 'samelephant82@gmail.com' || i, false));
        END LOOP;

        PERFORM assert.not_null(users.add('UserForSearchTest', 'password', 'Search', 'test@gmail.com', false));

        PERFORM 
            assert.equal(100, total::int),
            assert.equal(15, jsonb_array_length(users))
        FROM users.list(15, 0, '');

        FOREACH q IN ARRAY ARRAY['Search', 'sear', 'test', 'search mail'] LOOP
            PERFORM 
                assert.equal(1, total::int),
                assert.equal(1, jsonb_array_length(users))
            FROM users.list(15, 0, q);
        END LOOP;
    end;
$$ language plpgsql;