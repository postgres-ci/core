create or replace function auth.test_logout() returns void as $$
    declare 
        _session_id text;
    begin 

        IF assert.not_null(users.add('login', 'password', 'Elephant Sam', 'samelephant82@gmail.com', true)) THEN 

            _session_id = auth.login('login', 'password');

            IF assert.not_null(_session_id) THEN 

                PERFORM assert.true(EXISTS(
                        SELECT null FROM postgres_ci.sessions WHERE session_id = _session_id
                    )
                );

                PERFORM auth.logout(_session_id);

                PERFORM assert.true(NOT EXISTS(
                        SELECT null FROM postgres_ci.sessions WHERE session_id = _session_id
                    )
                );

            END IF;

        END IF;

    end;
$$ language plpgsql security definer;