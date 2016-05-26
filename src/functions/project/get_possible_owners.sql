create or replace function project.get_possible_owners() returns table (
    user_id int,
    user_name text
) as $$
    begin 

        return query
            SELECT 
                U.user_id,
                U.user_name
            FROM postgres_ci.users AS U
            WHERE U.is_deleted = false
            ORDER BY U.user_id; 

    end;
$$ language plpgsql security definer;