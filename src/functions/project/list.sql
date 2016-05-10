create or replace function project.list() returns table (
    project_id       int,
    project_name     text,
    project_token    uuid,
    project_owner_id int,
    user_email       text,
    user_name        text,
    status           text,
    error            text,
    started_at       timestamptz
) as $$
    begin
        return query  
        SELECT 
            P.project_id,
            P.project_name,
            P.project_token,
            P.project_owner_id, 
            U.user_email,
            U.user_name,
            COALESCE(B.status::text, 'n/a') AS status,
            COALESCE(B.error, '')           AS error, 
            B.started_at 
        FROM postgres_ci.projects    AS P 
        JOIN postgres_ci.users       AS U ON U.user_id = P.project_owner_id
        LEFT JOIN postgres_ci.builds AS B ON B.build_id = P.last_build_id 
        WHERE P.is_deleted = false
        ORDER BY P.project_name;

    end;
$$ language plpgsql security definer;