create or replace fuction auth.gc() returns void as $$
    begin 
        DELETE FROM postgres_ci.sessions WHERE expires_at < CURRENT_TIMESTAMP + '1 hour'::interval;
    end;
$$ language plpgsql security definer;