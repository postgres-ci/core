create or replace function users.get(
    _user_id int,
    out user_id      int,
    out user_name    text,
    out user_login   text,
    out user_email   text,
    out is_superuser boolean,
    out created_at   timestamptz,
    out updated_at   timestamptz
) returns record as $$
    begin 
        SELECT 
            U.user_id,
            U.user_name,
            U.user_login,
            U.user_email,
            U.is_superuser,
            U.created_at,
            U.updated_at    
            INTO 
                user_id,
                user_name,
                user_login,
                user_email,
                is_superuser,
                created_at,
                updated_at
        FROM postgres_ci.users AS U
        WHERE U.user_id    = _user_id
        AND   U.is_deleted = false;

        IF NOT FOUND THEN 
            RAISE EXCEPTION 'NOT_FOUND' USING ERRCODE = 'no_data_found';
        END IF;

    end;
$$ language plpgsql security definer;