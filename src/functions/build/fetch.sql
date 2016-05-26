create or replace function build.fetch() returns table (
    build_id   int,
    created_at timestamptz
) as $$
    declare 
        _build_id   int;
        _created_at timestamptz;
    begin 

        SELECT 
            B.build_id,
            B.created_at
                INTO 
                    _build_id,
                    _created_at
        FROM postgres_ci.builds AS B
        WHERE B.status = 'pending'
        ORDER BY B.build_id 
        LIMIT 1
        FOR UPDATE SKIP LOCKED;

        IF NOT FOUND THEN
            return;
        END IF;

        UPDATE postgres_ci.builds AS B SET status = 'accepted' WHERE B.build_id = _build_id;

        return query 
            SELECT _build_id, _created_at;
    end;
$$ language plpgsql security definer rows 1;