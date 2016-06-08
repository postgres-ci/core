create or replace function users.test_add() returns void as $$
    declare 
        _user_id int;
    begin 

        _user_id = users.add('login', 'password', 'Elephant Sam', 'samelephant82@gmail.com', true);

        IF assert.not_null(_user_id) THEN 

            IF assert.true((SELECT is_superuser FROM postgres_ci.users WHERE user_id = _user_id)) THEN 

                PERFORM 
                    assert.equal('login', user_login), 
                    assert.equal('Elephant Sam', user_name), 
                    assert.equal('samelephant82@gmail.com', user_email)
                FROM postgres_ci.users WHERE user_id = _user_id;

                PERFORM 
                    assert.equal('email', method),
                    assert.equal('samelephant82@gmail.com', text_id),
                    assert.equal(0::bigint, int_id) 
                FROM postgres_ci.user_notification_method WHERE user_id = _user_id;

            END IF;
            
            IF assert.not_null(auth.login('login', 'password')) THEN 

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

        END IF;
    end;
$$ language plpgsql security definer;