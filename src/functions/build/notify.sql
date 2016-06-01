create or replace function build.notify(_build_id int) returns boolean as $$
    begin 

        INSERT INTO postgres_ci.notify (build_id) VALUES (_build_id);

        PERFORM pg_notify('postgres-ci::notify', (
                SELECT to_json(T.*) FROM (
                    SELECT 
                        _build_id         AS build_id,
                        CURRENT_TIMESTAMP AS created_at
                ) T
            )::text
        );

        return true;
        
    end;
$$ language plpgsql security definer;