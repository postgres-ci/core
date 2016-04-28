create or replace function auth.test_login() returns void as $$
    begin 

        IF assert.not_null(users.add('login', 'password', 'Elephant Sam', 'samelephant82@gmail.com', true)) THEN 

            PERFORM assert.not_null(auth.login('login', 'password'));
        END IF;

        PERFORM assert.exception(
            $sql$ SELECT auth.login('login2', 'password') $sql$, 
            exception_message  := 'NOT_FOUND',
            exception_sqlstate := 'P0002'
        );

        PERFORM assert.exception(
            $sql$ SELECT auth.login('login', 'password2') $sql$, 
            exception_message  := 'INVALID_PASSWORD',
            exception_sqlstate := '28P01'
        );

    end;
$$ language plpgsql;