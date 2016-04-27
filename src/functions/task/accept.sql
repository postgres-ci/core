create or replace function task.accept(
    _task_id int
) returns void as $$
    begin 

        UPDATE postgres_ci.tasks SET status = 'accepted' WHERE status = 'pending' AND task_id = _task_id;

        IF NOT FOUND THEN 
        
            SET log_min_messages to LOG;

            RAISE EXCEPTION 'NOT_FOUND' USING ERRCODE = 'no_data_found';
        END IF;

    end;
$$ language plpgsql security definer;