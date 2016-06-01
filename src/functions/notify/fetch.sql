create or replace function notify.fetch() returns table (
    build_id int,
    send_to  jsonb
) as $$
    declare 
        _build_id int;
    begin 

        SELECT N.build_id INTO _build_id FROM postgres_ci.notify AS N ORDER BY N.build_id FOR UPDATE SKIP LOCKED;

        IF NOT FOUND THEN 
            return;
        END IF;

        return query 
            SELECT 
                _build_id,
                (
                    SELECT 
                        COALESCE(array_to_json(array_agg(P.*)), '[]') 
                    FROM (
                        SELECT 
                            U.user_name,
                            U.user_email
                        FROM postgres_ci.users AS U 
                        WHERE U.user_id IN (
                            SELECT 
                                P.project_owner_id 
                            FROM postgres_ci.projects AS P  
                            JOIN postgres_ci.builds   AS B USING(project_id)
                            WHERE B.build_id = _build_id
                        UNION ALL
                            SELECT 
                                U.user_id 
                            FROM postgres_ci.users AS U 
                            WHERE U.user_email IN (
                                SELECT 
                                    author_email 
                                FROM postgres_ci.commits AS C 
                                JOIN postgres_ci.builds AS B USING(commit_id)
                                WHERE B.build_id = _build_id
                            )
                        ) 
                    ) AS P 
                )::jsonb
            ;

        DELETE FROM postgres_ci.notify AS N WHERE N.build_id = _build_id;
    end;
$$ language plpgsql security definer;

