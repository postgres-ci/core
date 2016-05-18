create or replace function password.test_change() returns void as $$
    declare
        _user_id int;
    begin 

        _user_id = users.add('login', 'password', 'Elephant Sam', 'samelephant82@gmail.com', true);

        IF assert.not_null(_user_id) AND assert.true(password.check(_user_id, 'password')) THEN 

            if assert.true(password.change(_user_id, 'password', 'password2')) THEN 

                PERFORM assert.true(password.check(_user_id, 'password2'));
            END IF;

            PERFORM assert.exception(
                $sql$ SELECT password.check($sql$ || _user_id || $sql$, 'password') $sql$, 
                exception_message  := 'INVALID_PASSWORD',
                exception_sqlstate := '28P01'
            );

        END IF;

    end;
$$ language plpgsql;