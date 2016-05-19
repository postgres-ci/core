create or replace function build.fetch(
    out build_id   int,
    out created_at timestamptz
) returns record as $$
    begin 

        SELECT 
            B.build_id,
            B.created_at
                INTO 
                    build_id,
                    created_at
        FROM postgres_ci.builds AS B
        WHERE B.status = 'pending' 
        LIMIT 1
        FOR UPDATE SKIP LOCKED;

        IF NOT FOUND THEN -- @todo: don't use exception this
            RAISE EXCEPTION 'NO_NEW_TASKS' USING ERRCODE = 'no_data_found';
        END IF;

        UPDATE postgres_ci.builds AS B SET status = 'accepted' WHERE B.build_id = "fetch".build_id;

    end;
$$ language plpgsql security definer;