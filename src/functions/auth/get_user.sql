create or replace function auth.get_user(
    _session_id      text,
    out user_id      int,
    out user_name    text,
    out user_login   text,
    out user_email   text,
    out is_superuser boolean,
    out created_at   timestamptz
) returns record as $$
    begin 

        SELECT 
            U.user_id,
            U.user_name,
            U.user_login,
            U.user_email,
            U.is_superuser,
            U.created_at
                INTO 
                    user_id,
                    user_name,
                    user_login,
                    user_email,
                    is_superuser,
                    created_at
        FROM postgres_ci.users    AS U 
        JOIN postgres_ci.sessions AS S USING(user_id)
        WHERE U.is_deleted = false
        AND   S.session_id = _session_id
        AND   S.expires_at > CURRENT_TIMESTAMP;

        IF NOT FOUND THEN 
        
            SET log_min_messages to LOG;

            RAISE EXCEPTION 'NOT_FOUND' USING ERRCODE = 'no_data_found';
        END IF;

        UPDATE postgres_ci.sessions 
            SET 
                expires_at = CURRENT_TIMESTAMP + '1 hour'::interval 
        WHERE session_id   = _session_id;

    end;
$$ language plpgsql security definer;