create or replace function password.test_check() returns void as $$
    declare
        _user_id int;
    begin 

        _user_id = users.add('login', 'password', 'Elephant Sam', 'samelephant82@gmail.com', true);

        IF assert.not_null(_user_id) THEN 

            PERFORM assert.true(password.check(_user_id, 'password'));
        END IF;

        PERFORM assert.exception(
            $sql$ SELECT password.check(-1, 'password') $sql$, 
            exception_message  := 'NOT_FOUND',
            exception_sqlstate := 'P0002'
        );

        PERFORM assert.exception(
            $sql$ SELECT password.check($sql$ || _user_id || $sql$, 'password2') $sql$, 
            exception_message  := 'INVALID_PASSWORD',
            exception_sqlstate := '28P01'
        );

    end;
$$ language plpgsql;