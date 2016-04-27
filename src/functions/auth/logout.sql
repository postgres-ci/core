create or replace function auth.logout(_session_id text) returns void as $$
    begin 
        DELETE FROM postgres_ci.sessions WHERE session_id = _session_id;
    end;
$$ language plpgsql security definer;