create or replace function auth.login(
    _login         text, 
    _password      text, 
    out session_id text
) returns text as $$
    declare
        _user_id          int;
        _invalid_password boolean;
    begin 

        SELECT
            U.user_id,
            encode(digest(U.salt || _password, 'sha1'), 'hex') != U.hash
            INTO
                _user_id,
                _invalid_password
        FROM  postgres_ci.users AS U
        WHERE lower(U.user_login) = lower(_login)
        AND   is_deleted          = false;

        CASE 
            WHEN NOT FOUND THEN

                SET log_min_messages to LOG;

                RAISE EXCEPTION 'NOT_FOUND' USING ERRCODE = 'no_data_found';

            WHEN _invalid_password THEN 

                SET log_min_messages to LOG;

                RAISE EXCEPTION 'INVALID_PASSWORD' USING ERRCODE = 'invalid_password';
                
            ELSE 
                INSERT INTO postgres_ci.sessions (
                    user_id,
                    expires_at
                ) VALUES (
                    _user_id,
                    CURRENT_TIMESTAMP + '1 hour'::interval
                ) RETURNING sessions.session_id INTO session_id;
        END CASE;
    end;
$$ language plpgsql security definer;