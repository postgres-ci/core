create or replace function project.github_secret(_github_name text) returns table(
    secret text
) as $$
    begin 
        return query 
            SELECT 
                github_secret 
            FROM postgres_ci.projects 
            WHERE github_name = _github_name 
            AND   is_deleted = false;
    end
$$ language plpgsql security definer rows 1;