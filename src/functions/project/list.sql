create or replace function project.list() returns table (
    project_id       int,
    project_name     text,
    project_token    uuid,
    project_owner_id int,
    user_email       text,
    user_name        text,
    status           postgres_ci.status,
    commit_sha       text,
    last_build_id    int,
    started_at       timestamptz,
    finished_at      timestamptz
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
            B.status,
            C.commit_sha,
            P.last_build_id,
            B.started_at,
            B.finished_at
        FROM postgres_ci.projects     AS P 
        JOIN postgres_ci.users        AS U ON U.user_id   = P.project_owner_id
        LEFT JOIN postgres_ci.builds  AS B ON B.build_id  = P.last_build_id 
        LEFT JOIN postgres_ci.commits AS C ON C.commit_id = B.commit_id
        WHERE P.is_deleted = false
        ORDER BY P.project_name;

    end;
$$ language plpgsql security definer;