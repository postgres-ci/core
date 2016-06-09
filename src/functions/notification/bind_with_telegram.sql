create or replace function notification.bind_with_telegram(
    _user_id           int, 
    _telegram_username text, 
    _telegram_id       bigint
) returns void as $$
    begin 

        UPDATE postgres_ci.user_notification_method 
            SET
                int_id = _telegram_id
        WHERE user_id = _user_id
        AND   method  = 'telegram'
        AND   text_id = _telegram_username;

        IF NOT FOUND THEN 
            RAISE EXCEPTION 'NOT_FOUND' USING ERRCODE = 'no_data_found';
        END IF;
    end;
$$ language plpgsql security definer; 