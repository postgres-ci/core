create or replace function users.test_delete() returns void as $$
    declare 
        _user_id int;
    begin 

        _user_id = users.add('login', 'password', 'Elephant Sam', 'samelephant82@gmail.com', false);

        IF assert.not_null(_user_id) THEN

            PERFORM users.delete(_user_id);

            IF assert.true((SELECT is_deleted FROM postgres_ci.users WHERE user_id = _user_id)) THEN 
                
                PERFORM assert.exception(
                    $sql$ SELECT auth.login('login', 'password') $sql$, 
                    exception_message  := 'NOT_FOUND',
                    exception_sqlstate := 'P0002'
                );

            END IF;

        END IF;

        PERFORM assert.exception(
            $sql$ SELECT users.delete(-1) $sql$, 
            exception_message  := 'NOT_FOUND',
            exception_sqlstate := 'P0002'
        );

        _user_id = users.add('login2', 'password2', 'Elephant Sam2', '2samelephant82@gmail.com', true);

        IF assert.not_null(_user_id) THEN

            PERFORM assert.exception(
                $sql$ SELECT users.delete($sql$ || _user_id || $sql$) $sql$, 
                exception_message  := 'IS_SUPERUSER',
                exception_sqlstate := '23514'
            );

        END IF;

    end;
$$ language plpgsql security definer;