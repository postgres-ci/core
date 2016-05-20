create or replace function users.delete(_user_id int) returns void as $$
    begin 

        IF EXISTS(
            SELECT 
                null 
            FROM postgres_ci.users 
            WHERE is_deleted = false 
            AND is_superuser = true 
            AND user_id      = _user_id
        ) THEN 
            RAISE EXCEPTION 'IS_SUPERUSER' USING ERRCODE = 'check_violation';
        END IF;
    
        UPDATE postgres_ci.users 
            SET 
                is_deleted = true, 
                updated_at = CURRENT_TIMESTAMP
        WHERE user_id  = _user_id
        AND is_deleted = false;

        IF NOT FOUND THEN 
            RAISE EXCEPTION 'NOT_FOUND' USING ERRCODE = 'no_data_found';
        END IF;
    end;
$$ language plpgsql security definer;