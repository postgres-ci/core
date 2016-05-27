create or replace function users.test_get() returns void as $$
    declare 
        _user_id int;
    begin 

        _user_id = users.add('login', 'password', 'Elephant Sam', 'samelephant82@gmail.com', false);

        IF assert.not_null(_user_id) THEN 

            PERFORM 
                assert.equal('login', user_login), 
                assert.equal('Elephant Sam', user_name), 
                assert.equal('samelephant82@gmail.com', user_email),
                assert.false(is_superuser)
            FROM users.get(_user_id);

            PERFORM users.delete(_user_id);

            PERFORM assert.exception(
                $sql$ SELECT users.get($sql$ || _user_id || $sql$) $sql$, 
                exception_message  := 'NOT_FOUND',
                exception_sqlstate := 'P0002'
            );

        END IF;
    end;
$$ language plpgsql security definer;