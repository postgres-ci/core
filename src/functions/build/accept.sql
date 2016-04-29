create or replace function build.accept(
    _build_id int
) returns void as $$
    begin 

        UPDATE postgres_ci.builds 
            SET status = 'accepted' 
        WHERE status   = 'pending' 
        AND   build_id = _build_id;

        IF NOT FOUND THEN 
        
            SET log_min_messages to LOG;

            RAISE EXCEPTION 'NOT_FOUND' USING ERRCODE = 'no_data_found';
        END IF;

    end;
$$ language plpgsql security definer;