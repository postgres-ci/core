create or replace function auth.get_user(
    _session_id text
) returns table(
    user_id      int,
    user_name    text,
    user_login   text,
    user_email   text,
    is_superuser boolean,
    created_at   timestamptz
) as $$
    begin 

        return query 
        SELECT 
            U.user_id,
            U.user_name,
            U.user_login,
            U.user_email,
            U.is_superuser,
            U.created_at
        FROM postgres_ci.users    AS U 
        JOIN postgres_ci.sessions AS S USING(user_id)
        WHERE U.is_deleted = false
        AND   S.session_id = _session_id
        AND   S.expires_at > CURRENT_TIMESTAMP;

        IF FOUND THEN 
            UPDATE postgres_ci.sessions 
                SET 
                    expires_at = CURRENT_TIMESTAMP + '1 hour'::interval 
            WHERE session_id   = _session_id;
        END IF;
    end;
$$ language plpgsql security definer rows 1;