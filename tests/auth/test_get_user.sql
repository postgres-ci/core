create or replace function auth.test_get_user() returns void as $$
    declare 
        _user       record;
        _session_id text;
    begin 

        IF assert.not_null(users.add('login', 'password', 'Elephant Sam', 'samelephant82@gmail.com', true)) THEN 

            _session_id = auth.login('login', 'password');

            IF assert.not_null(_session_id) THEN 

                _user = auth.get_user(_session_id);
            
                IF assert.true(_user.is_superuser) THEN 

                    PERFORM assert.equal('Elephant Sam', _user.user_name);
                    PERFORM assert.equal('samelephant82@gmail.com', _user.user_email);
                END IF;
                
            END IF;

        END IF;

        PERFORM assert.exception(
            $sql$ SELECT auth.get_user('no_data_found') $sql$, 
            exception_message  := 'NOT_FOUND',
            exception_sqlstate := 'P0002'
        );

    end;
$$ language plpgsql;