create or replace function notification.find_user_by_telegram_username(_telegram_username text) returns table (
    user_id    int,
    telegram_id bigint
) as $$
    begin 

        return query 
            SELECT 
                N.user_id, 
                N.int_id 
            FROM postgres_ci.user_notification_method AS N
            WHERE N.method  = 'telegram'
            AND   N.text_id = _telegram_username;

    end;
$$ language plpgsql security definer rows 1;