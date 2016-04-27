create or replace function users.test_add() returns void as $$
    begin 

        IF assert.not_null(users.add('login', 'password', 'Elephant Sam', 'samelephant82@gmail.com', true)) THEN 

            PERFORM assert.exception(
                $sql$ SELECT users.add('login', 'password', 'Elephant Sam', 'samelephant83@gmail.com', true) $sql$, 
                exception_table      := 'users',
                exception_schema     := 'postgres_ci',
                exception_message    := 'LOGIN_ALREADY_EXISTS',
                exception_constraint := 'unique_user_login'
            );

            PERFORM assert.exception(
                $sql$ SELECT users.add('login2', 'password', 'Elephant Sam', 'samelephant82@gmail.com', true) $sql$, 
                exception_table      := 'users',
                exception_schema     := 'postgres_ci',
                exception_message    := 'EMAIL_ALREADY_EXISTS',
                exception_constraint := 'unique_user_email'
            );

            PERFORM assert.exception(
                $sql$ SELECT users.add('login2', 'password', 'Elephant Sam', 'samelephant82', true) $sql$, 
                exception_table      := 'users',
                exception_schema     := 'postgres_ci',
                exception_message    := 'INVALID_EMAIL',
                exception_constraint := 'check_user_email'
            );

        END IF;
    end;
$$ language plpgsql;