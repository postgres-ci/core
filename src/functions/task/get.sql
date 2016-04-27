create or replace function task.get(
    out task_id    int,
    out created_at timestamptz
) returns record as $$
    begin 
    
        SELECT 
            T.task_id,
            T.created_at
                INTO 
                    task_id,
                    created_at
        FROM postgres_ci.tasks AS T
        WHERE T.status = 'pending' 
        LIMIT 1
        FOR UPDATE SKIP LOCKED;

        IF NOT FOUND THEN 
        
            SET log_min_messages to LOG;

            RAISE EXCEPTION 'NO_NEW_TASKS' USING ERRCODE = 'no_data_found';
        END IF;

        UPDATE postgres_ci.tasks SET status = 'accepted' WHERE tasks.task_id = get.task_id;

    end;
$$ language plpgsql security definer;