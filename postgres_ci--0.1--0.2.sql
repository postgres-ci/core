alter table postgres_ci.commits add column project_id int not null default 0;

update postgres_ci.commits c set project_id = (select project_id from postgres_ci.branches where branch_id = c.branch_id limit 1);

alter table postgres_ci.commits alter column project_id drop default;

drop index postgres_ci.idx_branch_project;
create index idx_branch on postgres_ci.branches (branch_id);
drop index postgres_ci.idx_new_build;
create index idx_new_build on postgres_ci.builds(status) where status in ('pending', 'accepted', 'running');
    
alter table postgres_ci.branches drop constraint branches_pkey cascade;
alter table postgres_ci.branches add primary key (project_id, branch_id);
alter table postgres_ci.builds          drop constraint builds_project_id_fkey;
alter table postgres_ci.builds_counters drop constraint builds_counters_project_id_fkey;


alter table postgres_ci.commits add foreign key (project_id, branch_id) references postgres_ci.branches(project_id, branch_id) match full;
alter table postgres_ci.builds  add foreign key (project_id, branch_id) references postgres_ci.branches(project_id, branch_id) match full;
alter table postgres_ci.builds_counters add foreign key (project_id, branch_id) references postgres_ci.branches(project_id, branch_id) match full;

create index idx_parts_build on postgres_ci.parts(build_id);

alter extension postgres_ci drop function build.view(int);
drop function build.view(int);

create or replace function build.view(
    _build_id int, 

    out project_id      int,
    out project_name    text,
    out branch_id       int,
    out branch_name     text,
    out config          text, 
    out error           text,
    out status          postgres_ci.status,
    out commit_sha      text,
    out commit_message  text,
    out committed_at    timestamptz,
    out committer_name  text,
    out committer_email text,
    out author_name     text,
    out author_email    text,
    out created_at      timestamptz,
    out parts           jsonb
) returns record as $$
    begin 

        SELECT
            B.project_id,
            P.project_name, 
            B.branch_id, 
            BR.branch,
            B.config,
            B.error,
            B.status,
            C.commit_sha,
            C.commit_message,
            C.committed_at,
            C.committer_name,
            C.committer_email,
            C.author_name,
            C.author_email,
            B.created_at,
            (
                SELECT 
                    COALESCE(array_to_json(array_agg(P.*)), '[]') 
                FROM (
                    SELECT 
                        part_id,
                        image,
                        version,
                        output,
                        success,
                        started_at,
                        finished_at,
                        (
                            SELECT 
                                COALESCE(array_to_json(array_agg(T.*)), '[]') 
                            FROM (
                                SELECT 
                                    function,
                                    errors,
                                    duration
                                FROM postgres_ci.tests 
                                WHERE part_id = parts.part_id
                                ORDER BY 
                                    jsonb_array_length(errors) DESC, 
                                    function
                            ) AS T
                        ) AS tests
                    FROM postgres_ci.parts 
                    WHERE build_id = B.build_id
                    ORDER BY part_id
                ) AS P 
            )
            INTO 
                project_id,
                project_name,
                branch_id,
                branch_name,
                config, 
                error,
                status,
                commit_sha,
                commit_message,
                committed_at,
                committer_name,
                committer_email,
                author_name,
                author_email,
                created_at,
                parts
        FROM postgres_ci.builds AS B 
            JOIN postgres_ci.projects AS P USING(project_id)
            JOIN postgres_ci.branches AS BR ON BR.branch_id = B.branch_id
            JOIN postgres_ci.commits  AS C  ON C.commit_id  = B.commit_id
        WHERE B.build_id = _build_id;

        IF NOT FOUND THEN 
            RAISE EXCEPTION 'NOT_FOUND' USING ERRCODE = 'no_data_found';
        END IF;
    end;
$$ language plpgsql security definer;

alter extension postgres_ci drop function build.list(int,int,int,int);
drop function build.list(int,int,int,int);

create or replace function build.list(
    _project_id  int,
    _branch_id   int,
    _limit       int,
    _offset      int,
    out project_id   int,
    out project_name text,
    out total        bigint,
    out branches     jsonb,
    out items        jsonb
) returns record as $$
    begin 

        SELECT 
            P.project_id,
            P.project_name,
            (
                SELECT 
                    COALESCE(SUM(C.counter), 0) 
                FROM postgres_ci.builds_counters AS C
                WHERE C.project_id = _project_id
                AND (
                    CASE WHEN _branch_id <> 0 
                        THEN branch_id  = _branch_id
                        ELSE true 
                    END
                )
            ),
            (
                SELECT 
                    COALESCE(array_to_json(array_agg(R.*)), '[]') 
                FROM (
                    SELECT 
                        B.branch_id,
                        B.branch
                    FROM postgres_ci.branches AS B
                    WHERE 
                        B.project_id = _project_id
                    ORDER BY branch
                ) AS R
            ),
            (
                SELECT 
                    COALESCE(array_to_json(array_agg(R.*)), '[]') 
                FROM (
                    SELECT 
                        BD.build_id,
                        BD.project_id,
                        BD.status,
                        BD.error,
                        BD.created_at,
                        BD.started_at,
                        BD.finished_at,
                        C.commit_sha,
                        C.commit_message,
                        B.branch,
                        B.branch_id
                    FROM postgres_ci.builds   AS BD
                    JOIN postgres_ci.commits  AS C USING(commit_id) 
                    JOIN postgres_ci.branches AS B ON B.branch_id  = C.branch_id
                    WHERE 
                        BD.project_id = _project_id
                    AND (
                        CASE WHEN _branch_id <> 0 
                            THEN BD.branch_id  = _branch_id
                            ELSE true
                        END
                    )
                    ORDER BY build_id DESC
                    LIMIT  _limit
                    OFFSET _offset
                ) AS R
            )
            FROM postgres_ci.projects AS P
            WHERE P.project_id = _project_id 
            AND   P.is_deleted = false
        INTO project_id, project_name, total, branches, items;

    end;
$$ language plpgsql security definer;


create or replace function hook.github_push(
    _github_name text,
    _branch      text,
    _commits     jsonb
) returns table (
    commit_id int
) as $$
    declare
        _project_id int;
    begin 

        SELECT project_id INTO _project_id FROM postgres_ci.projects WHERE github_name = _github_name AND is_deleted = false;
        
        IF NOT FOUND THEN 
            RAISE EXCEPTION 'NOT_FOUND' USING ERRCODE = 'no_data_found';
        END IF;

        return query 

            SELECT 
                project.add_commit(
                    _project_id,
                    _branch,
                    C.commit_sha,
                    C.commit_message,
                    C.committed_at,
                    C.committer_name,
                    C.committer_email,
                    C.author_name,
                    C.author_email
                ) 
            FROM jsonb_populate_recordset(null::postgres_ci.commits, _commits) AS C;
    end;
$$ language plpgsql security definer;


create or replace function project.add_commit(
    _project_id      int,
    _branch          text,
    _commit_sha      text,
    _commit_message  text,
    _committed_at    timestamptz,
    _committer_name  text,
    _committer_email text,
    _author_name     text,
    _author_email    text,
    out commit_id    int
) returns int as $$
    declare 
        _branch_id int;
    begin 
        
        _branch_id = project.get_branch_id(_project_id, _branch);

        BEGIN 
        
            INSERT INTO postgres_ci.commits (
                project_id,
                branch_id,
                commit_sha,
                commit_message,
                committed_at,
                committer_name,
                committer_email,
                author_name,
                author_email
            ) VALUES (
                _project_id,
                _branch_id,
                _commit_sha,
                _commit_message,
                _committed_at,
                _committer_name,
                _committer_email,
                _author_name,
                _author_email
            ) RETURNING commits.commit_id INTO commit_id;

            PERFORM build.new(_project_id, _branch_id, commit_id);

        EXCEPTION WHEN unique_violation THEN

            SELECT 
                C.commit_id INTO commit_id 
            FROM postgres_ci.commits C
            WHERE C.branch_id = _branch_id 
            AND  C.commit_sha = _commit_sha;
        END;

    end;
$$ language plpgsql security definer;

create or replace function build.fetch() returns table (
    build_id   int,
    created_at timestamptz
) as $$
    declare 
        _build_id   int;
        _created_at timestamptz;
    begin 

        SELECT 
            B.build_id,
            B.created_at
                INTO 
                    _build_id,
                    _created_at
        FROM postgres_ci.builds AS B
        WHERE B.status = 'pending'
        ORDER BY B.build_id 
        LIMIT 1
        FOR UPDATE SKIP LOCKED;

        IF NOT FOUND THEN
            return;
        END IF;

        UPDATE postgres_ci.builds AS B SET status = 'accepted' WHERE B.build_id = _build_id;

        return query 
            SELECT _build_id, _created_at;
    end;
$$ language plpgsql security definer rows 1;


create or replace function build.gc() returns void as $$
    begin 
    
        WITH builds AS (
            SELECT 
                build_id 
            FROM postgres_ci.builds
            WHERE status IN ('accepted', 'running')
            AND created_at < (current_timestamp - '1 hour'::interval)
            ORDER BY build_id
        ),
        stop_containers AS (
            SELECT 
                pg_notify('postgres-ci::stop_container', (
                        SELECT to_json(T.*) FROM (
                            SELECT 
                                P.container_id,
                                current_timestamp AS created_at
                        ) T
                    )::text
                )
            FROM postgres_ci.parts AS P
            JOIN builds AS B ON P.build_id = B.build_id
        )
        UPDATE postgres_ci.builds AS B
            SET
                status      = 'failed',
                error       = 'Execution timeout',
                finished_at = current_timestamp
        WHERE B.build_id IN (SELECT build_id FROM builds);

    end;
$$ language plpgsql security definer;

create or replace function build.stop(_build_id int, _config text, _error text) returns void as $$
    begin 

        UPDATE postgres_ci.builds
            SET 
                config      = _config,
                error       = _error,
                status      = (
                    CASE 
                        WHEN _error = '' THEN 'success' 
                        ELSE 'failed' 
                    END
                )::postgres_ci.status,
                finished_at = current_timestamp
        WHERE build_id = _build_id
        AND   status   = 'running';
        
        IF NOT FOUND THEN 
            RAISE EXCEPTION 'NOT_FOUND' USING ERRCODE = 'no_data_found';
        END IF;

        IF EXISTS(
            SELECT 
            FROM postgres_ci.parts 
            WHERE build_id = _build_id 
            AND success IS False
            LIMIT 1
        ) THEN 
            UPDATE postgres_ci.builds SET status = 'failed'::postgres_ci.status WHERE build_id = _build_id;
        END IF;

    end;
$$ language plpgsql security definer;


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

create or replace function users.update(
    _user_id      int,
    _user_name    text,
    _user_email   text,
    _is_superuser boolean 
) returns void as $$
    declare
        _message         text;
        _column_name     text;
        _constraint_name text;
        _datatype_name   text;
        _table_name      text;
        _schema_name     text;
    begin 

        BEGIN 
            UPDATE postgres_ci.users 
                SET 
                    user_name    = _user_name,
                    user_email   = _user_email,
                    is_superuser = _is_superuser,
                    updated_at   = current_timestamp
            WHERE user_id = _user_id;

        EXCEPTION WHEN OTHERS THEN
        
            GET STACKED DIAGNOSTICS 
                _column_name     = column_name,
                _constraint_name = constraint_name,
                _datatype_name   = pg_datatype_name,
                _table_name      = table_name,
                _schema_name     = schema_name;

            CASE 
                WHEN _constraint_name = 'unique_user_email' THEN 
                    _message = 'EMAIL_ALREADY_EXISTS';
                WHEN _constraint_name = 'check_user_email' THEN 
                    _message = 'INVALID_EMAIL';
                ELSE 
                    _message = SQLERRM;
            END CASE;

            RAISE EXCEPTION USING 
                MESSAGE    = _message,
                ERRCODE    = SQLSTATE,
                COLUMN     = _column_name,
                CONSTRAINT = _constraint_name,
                DATATYPE   = _datatype_name,
                TABLE      = _table_name,
                SCHEMA     = _schema_name;
        END;

    end;
$$ language plpgsql security definer;


create or replace function password.reset(_user_id int, _password text) returns void as $$
    declare 
        _salt text;
    begin 
        _salt = postgres_ci.sha1(gen_salt('md5') || current_timestamp);
        UPDATE postgres_ci.users 
            SET
                hash       = encode(digest(_salt || _password, 'sha1'), 'hex'),
                salt       = _salt,
                updated_at = current_timestamp
        WHERE user_id = _user_id; 
    end;
$$ language plpgsql security definer;


create or replace function project.get_github_secret(_github_name text) returns table(
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


create or replace function build.start(
    _build_id          int,
    out repository_url text,
    out branch         text,
    out revision       text
) returns record as $$
    declare 
        _commit_id  int;
        _project_id int;
    begin

        UPDATE postgres_ci.builds AS B
            SET 
                status     = 'running',
                started_at = current_timestamp
        WHERE B.build_id = _build_id 
        AND   B.status   = 'accepted'
        RETURNING B.commit_id INTO _commit_id;
        
        IF NOT FOUND THEN 
            RAISE EXCEPTION 'NOT_FOUND' USING ERRCODE = 'no_data_found';
        END IF;

        SELECT 
            P.project_id,
            P.repository_url,
            B.branch,
            C.commit_sha 
                INTO 
                    _project_id,
                    repository_url,
                    branch,
                    revision
        FROM postgres_ci.projects AS P 
        JOIN postgres_ci.branches AS B USING(project_id)
        JOIN postgres_ci.commits  AS C ON C.branch_id = B.branch_id
        WHERE C.commit_id = _commit_id;

        UPDATE postgres_ci.projects SET last_build_id = _build_id  WHERE project_id = _project_id;
    end;
$$ language plpgsql security definer;