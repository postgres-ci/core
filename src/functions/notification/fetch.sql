create or replace function notification.fetch() returns table (
    build_id            int,
    build_status        postgres_ci.status,
    project_id          int,
    project_name        text,
    branch              text,
    build_error         text,
    build_created_at    timestamptz,
    build_started_at    timestamptz,
    build_finished_at   timestamptz,
    commit_sha          text,
    commit_message      text,
    committed_at        timestamptz,
    committer_name      text,
    committer_email     text,
    commit_author_name  text,
    commit_author_email text,
    send_to             jsonb
) as $$
    declare 
        _build_id int;
    begin 

        SELECT 
            N.build_id INTO _build_id 
        FROM postgres_ci.notification AS N 
        ORDER BY N.build_id 
        LIMIT 1
        FOR UPDATE SKIP LOCKED;

        IF NOT FOUND THEN 
            return;
        END IF;

        return query 
            SELECT 
                B.build_id,
                B.status,
                P.project_id,
                P.project_name,
                BR.branch,
                B.error,
                B.created_at,
                B.started_at,
                B.finished_at,
                C.commit_sha,
                C.commit_message,
                C.committed_at,
                C.committer_name,
                C.committer_email,
                C.author_name,
                C.author_email,
                (
                    SELECT 
                        COALESCE(array_to_json(array_agg(P.*)), '[]') 
                    FROM (
                        SELECT 
                            U.user_name,
                            M.method   AS notify_method,
                            M.text_id  AS notify_text_id,
                            M.int_id   AS notify_int_id
                        FROM postgres_ci.users AS U 
                        JOIN postgres_ci.user_notification_method AS M ON U.user_id = M.user_id
                        WHERE U.user_id IN (
                            SELECT 
                                P.project_owner_id 
                        UNION ALL
                            SELECT 
                                U.user_id 
                            FROM postgres_ci.users AS U 
                            WHERE U.user_email IN (lower(C.author_email), lower(C.committer_email))
                        ) AND M.method <> 'none'
                    ) AS P 
                )::jsonb
            FROM postgres_ci.builds   AS B 
            JOIN postgres_ci.projects AS P  ON P.project_id = B.project_id
            JOIN postgres_ci.commits  AS C  ON C.commit_id  = B.commit_id
            JOIN postgres_ci.branches AS BR ON BR.branch_id = B.branch_id
            WHERE B.build_id = _build_id;

        DELETE FROM postgres_ci.notification AS N WHERE N.build_id = _build_id;
    end;
$$ language plpgsql security definer rows 1;
