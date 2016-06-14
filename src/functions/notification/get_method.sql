create or replace function notification.get_method(
    _user_id    int,
    out method  text,
    out text_id text,
    out int_id  bigint
) returns record as $$
    begin 

        SELECT 
            M.method,
            M.text_id,
            M.int_id
                INTO
                    method,
                    text_id,
                    int_id
        FROM postgres_ci.user_notification_method AS M
        WHERE M.user_id = _user_id;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'NOT_FOUND' USING ERRCODE = 'no_data_found';
        END IF;
    end;
$$ language plpgsql security definer;