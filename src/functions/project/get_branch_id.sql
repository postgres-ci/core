create or replace function project.get_branch_id(_project_id int, _branch text, out branch_id int) returns int as $$
    begin 

        SELECT 
            B.branch_id INTO branch_id 
        FROM postgres_ci.branches AS B
        WHERE B.project_id = _project_id
        AND   B.branch     = _branch;

        IF NOT FOUND THEN

            INSERT INTO postgres_ci.branches (
                project_id,
                branch
            ) VALUES (
                _project_id,
                _branch
            ) RETURNING branches.branch_id INTO branch_id; 
            
        END IF;
    end;
$$ language plpgsql security definer;