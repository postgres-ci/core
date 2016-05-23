create or replace function auth.gc() returns void as $$
    begin 
        DELETE FROM postgres_ci.sessions WHERE expires_at < CURRENT_TIMESTAMP;
    end;
$$ language plpgsql security definer;