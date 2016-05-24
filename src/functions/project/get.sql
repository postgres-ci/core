create or replace function project.get(
    _project_id int,
    out project_id        int,
    out project_name     text,
    out project_token    text,
    out repository_url   text,
    out project_owner_id int,
    out possible_owners  jsonb,
    out github_secret    text,
    out created_at       timestamptz,
    out updated_at       timestamptz
) returns record as $$
    begin 

        SELECT 
            P.project_id,
            P.project_name,
            P.project_token,
            P.repository_url,
            P.project_owner_id,
            (
                SELECT 
                    COALESCE(array_to_json(array_agg(U.*)), '[]') 
                FROM (
                    SELECT 
                        user_id,
                        user_name
                    FROM postgres_ci.users
                    WHERE is_deleted = false
                    ORDER BY user_id 
                ) U
            ),
            P.github_secret,
            P.created_at,
            P.updated_at

            INTO 
                project_id,
                project_name,
                project_token,
                repository_url,
                project_owner_id,
                possible_owners,
                github_secret,
                created_at,
                updated_at
        FROM postgres_ci.projects AS P
        WHERE P.project_id = _project_id
        AND   P.is_deleted = false;

        IF NOT FOUND THEN 
            RAISE EXCEPTION 'NOT_FOUND' USING ERRCODE = 'no_data_found';
        END IF;

    end;
$$ language plpgsql security definer;