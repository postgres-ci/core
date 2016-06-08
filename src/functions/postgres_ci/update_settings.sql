create or replace function postgres_ci.update_settings(
    _app_host       text,
    _smtp_host      text,
    _smtp_port      int,
    _smtp_username  text,
    _smtp_password  text,
    _telegram_token text
) returns void as $$
    begin
        UPDATE postgres_ci.settings
            SET 
                app_host       = _app_host,
                smtp_host      = _smtp_host,
                smtp_port      = _smtp_port,
                smtp_username  = _smtp_username,
                smtp_password  = _smtp_password,
                telegram_token = _telegram_token;
    end;
$$ language plpgsql security definer;

