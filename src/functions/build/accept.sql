create or replace function build.accept(
    _build_id int,
    out accept boolean
) returns boolean as $$
    begin 

        UPDATE postgres_ci.builds 
            SET status = 'accepted' 
        WHERE status   = 'pending' 
        AND   build_id = _build_id;

        IF NOT FOUND THEN 
            accept = false;
            return;
        END IF;

        accept = true;
    end;
$$ language plpgsql security definer;