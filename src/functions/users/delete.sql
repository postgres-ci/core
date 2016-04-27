create or replace function users.delete(_user_id int) returns void as $$
    begin 
    
        UPDATE postgres_ci.users 
            SET 
                is_deleted = true, 
                updated_at = CURRENT_TIMESTAMP
        WHERE user_id  = _user_id
        AND is_deleted = false;

        IF NOT FOUND THEN 
            
            SET log_min_messages to LOG;

            RAISE EXCEPTION 'NOT_FOUND' USING ERRCODE = 'no_data_found';
        END IF;
    end;
$$ language plpgsql security definer;