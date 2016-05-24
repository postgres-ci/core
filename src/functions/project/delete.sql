create or replace function project.delete(_project_id int) returns void as $$
    begin 
        UPDATE postgres_ci.projects 
            SET 
                is_deleted = true,
                updated_at = current_timestamp 
        WHERE project_id = _project_id;
    end;
$$ language plpgsql security definer;