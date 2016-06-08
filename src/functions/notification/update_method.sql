create or replace function notification.update_method(
    _user_id int,
    _method  postgres_ci.notification_method,
    _text_id text
) returns void as $$
    begin 

        CASE 
            WHEN _method = 'none' THEN 
                UPDATE postgres_ci.user_notification_method
                    SET 
                        method  = _method,
                        text_id = '',
                        int_id  = 0
                WHERE user_id = _user_id;
            ELSE 
                UPDATE postgres_ci.user_notification_method
                    SET 
                        method  = _method,
                        text_id = _text_id,
                        int_id  = 0
                WHERE user_id = _user_id AND NOT (
                    text_id = _text_id AND method = _method
                );
        END CASE;

    end;
$$ language plpgsql security definer;