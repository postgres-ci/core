create or replace function users.test_update() returns void as $$
    declare 
        _user_id int;
    begin 

        _user_id = users.add('login', 'password', 'Elephant Sam', 'samelephant82@gmail.com', true);

        IF assert.not_null(_user_id) THEN 

            PERFORM users.update(
                _user_id,
                'Up_Elephant Sam', 
                'Up_samelephant82@gmail.com',
                false
            );

            IF assert.false((SELECT is_superuser FROM postgres_ci.users WHERE user_id = _user_id)) THEN 

                PERFORM 
                    assert.equal('login', user_login), 
                    assert.equal('Up_Elephant Sam', user_name), 
                    assert.equal('Up_samelephant82@gmail.com', user_email)
                FROM postgres_ci.users WHERE user_id = _user_id;

            END IF;

        END IF;
    end;
$$ language plpgsql security definer;