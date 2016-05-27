create or replace function auth.test_gc() returns void as $$
    declare 
        _session_id         text;
        _expired_session_id text;
    begin 

        IF assert.not_null(users.add('login', 'password', 'Elephant Sam', 'samelephant82@gmail.com', true)) THEN 

            _session_id         = auth.login('login', 'password');
            _expired_session_id = auth.login('login', 'password');

            IF assert.not_equal(_session_id, _expired_session_id) THEN 

                PERFORM auth.gc();

                IF assert.equal(2, (SELECT COUNT(*) FROM postgres_ci.sessions)::int) THEN 

                    UPDATE postgres_ci.sessions 
                        SET 
                            expires_at = current_timestamp - '1 second'::interval 
                    WHERE session_id = _expired_session_id;

                    PERFORM auth.gc();

                    PERFORM assert.equal(1, (SELECT COUNT(*) FROM postgres_ci.sessions)::int);

                END IF;

            END IF;
        END IF;

    end;
$$ language plpgsql;