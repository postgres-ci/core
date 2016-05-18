
\echo Use "CREATE EXTENSION postgres_ci" to load this file. \quit

set statement_timeout     = 0;
set client_encoding       = 'UTF8';
set client_min_messages   = warning;
set escape_string_warning = off;
set standard_conforming_strings = on;




/* source file: src/schema.sql */

--create schema postgres_ci;

create or replace function postgres_ci.sha1(_value text) returns text as $$
    begin 
        return encode(digest(_value, 'sha1'), 'hex');
    end;
$$ language plpgsql;

create table postgres_ci.users (
    user_id      serial      primary key,
    user_name    text        not null,
    user_login   text        not null,
    user_email   text        not null,
    hash         text        not null,
    salt         text        not null,
    is_superuser boolean     not null default false,
    is_deleted   boolean     not null default false,
    created_at   timestamptz not null default current_timestamp,
    updated_at   timestamptz not null default current_timestamp,
    constraint check_user_hash  check(length(hash) = 40),
    constraint check_user_salt  check(length(salt) = 40),
    constraint check_user_email check(strpos(user_email, '@') > 0)
);

create unique index unique_user_login on postgres_ci.users (lower(user_login));
create unique index unique_user_email on postgres_ci.users (lower(user_email));
create index        find_user         on postgres_ci.users using gin(lower(user_name || user_login || user_email) gin_trgm_ops);

create unlogged table postgres_ci.sessions(
    session_id text        not null default    postgres_ci.sha1(gen_salt('md5') || gen_salt('md5')) primary key,
    user_id    int         not null references postgres_ci.users(user_id),
    expires_at timestamptz not null default current_timestamp
);

create index idx_sessions_expires_at on postgres_ci.sessions(expires_at);

create type postgres_ci.status as enum(
    'pending',
    'accepted',
    'running',
    'failed',
    'success'
);

create table postgres_ci.projects(
    project_id       serial  primary key,
    project_name     text    not null,
    project_token    uuid    not null default gen_random_uuid(),  
    project_owner_id int     not null,    
    repository_url   text    not null,
    github_name      text    not null,
    github_secret    text    not null,
    last_build_id    int,
    is_deleted       boolean not null default false,
    created_at       timestamptz not null default current_timestamp,
    updated_at       timestamptz not null default current_timestamp,
    unique(project_token)
);

create unique index udx_is_github_repo on postgres_ci.projects (github_name) where github_name <> '';
alter table postgres_ci.projects add constraint fk_project_owner_id foreign key  (project_owner_id) references postgres_ci.users(user_id);


create table postgres_ci.branches(
    branch_id  serial primary key,
    branch     text   not null,
    project_id int    not null references postgres_ci.projects(project_id),
    created_at timestamptz not null default current_timestamp
);

create index idx_branch_project on postgres_ci.branches (project_id);

create table postgres_ci.commits(
    commit_id       serial      primary key,
    branch_id       int         not null references postgres_ci.branches(branch_id),
    commit_sha      text        not null,
    commit_message  text        not null,
    committed_at    timestamptz not null,
    committer_name  text        not null,
    committer_email text        not null,
    author_name     text        not null,
    author_email    text        not null,
    created_at      timestamptz not null default current_timestamp,
    constraint check_commit_sha check(length(commit_sha) = 40),
    constraint uniq_commit unique(branch_id, commit_sha)
);

create table postgres_ci.builds(
    build_id    serial    primary key,
    project_id  int       not null references postgres_ci.projects(project_id),
    branch_id   int       not null references postgres_ci.branches(branch_id),
    commit_id   int       not null references postgres_ci.commits(commit_id),
    config      text      not null,
    status      postgres_ci.status not null,
    error       text not null default '',
    created_at  timestamptz not null default current_timestamp,
    started_at  timestamptz,
    finished_at timestamptz
);

create index idx_new_build on postgres_ci.builds(status) where status in ('pending');
create index idx_p_b_build on postgres_ci.builds(project_id, branch_id);

alter table postgres_ci.projects add foreign key (last_build_id) references postgres_ci.builds(build_id);

create table postgres_ci.builds_counters(
    project_id  int    not null references postgres_ci.projects(project_id),
    branch_id   int    not null references postgres_ci.branches(branch_id),
    counter     bigint not null,
    constraint unique_builds_counters unique(project_id, branch_id)
);


create table postgres_ci.parts(
    part_id             serial  primary key,
    build_id            int     not null references postgres_ci.builds(build_id),
    docker_image        text    not null,
    docker_container_id text not null,
    server_version      text    not null,
    output              text    not null,
    success             boolean not null,
    started_at          timestamptz not null,
    finished_at         timestamptz not null
);

create table postgres_ci.tests(
    part_id     int not null references postgres_ci.parts(part_id),
    namespace   name   not null,
    procedure   name   not null,
    errors      jsonb not null default '[]',
    started_at  timestamptz not null,
    finished_at timestamptz not null
);

create index idx_part_tests on postgres_ci.tests(part_id);


/*

select * from users.add('user', 'password', 'User', 'email@email.com', false);
select * from project.add('Postgres-CI Core', 1, '/home/kshvakov/gosrc/src/github.com/postgres-ci/core', '');
select * from project.add('Postgres-CI Core (github)', 1, '/https://github.com/postgres-ci/core', '');

SELECT * FROM project.add_commit(1, 'master', 'be60d1fbf2f6d18f9963e263ad8284217a8fcded', 'Test', now(), 'kshvakov', 'shvakov@gmail.com', 'kshvakov', 'shvakov@gmail.com');

select build.new(1,1,1);

insert into postgres_ci.users (user_name, user_login, user_email, hash, salt)
    select 'user_name' || g, 'user_login' || g, 'user@email' || g, 'af80e91bde00a80b2c4a98e48b8716a6c06ab391', 'af80e91bde00a80b2c4a98e48b8716a6c06ab391' 
        from generate_series(1, 1000000) g;

*/



/* source file: src/packages.sql */

create schema auth;
create schema hook;
create schema users;
create schema build;
create schema project;
create schema password;
	
grant usage on schema auth    to public;
grant usage on schema hook    to public;
grant usage on schema users   to public;
grant usage on schema build   to public;
grant usage on schema project to public;
grant usage on schema password to public;
grant usage on schema postgres_ci to public;
grant execute on all functions in schema auth    to public;
grant execute on all functions in schema hook    to public;
grant execute on all functions in schema users   to public;
grant execute on all functions in schema build   to public;
grant execute on all functions in schema project to public;
grant execute on all functions in schema password to public;
grant execute on all functions in schema postgres_ci to public;

/* source file: src/functions/auth/get_user.sql */

create or replace function auth.get_user(
    _session_id      text,
    out user_id      int,
    out user_name    text,
    out user_login   text,
    out user_email   text,
    out is_superuser boolean,
    out created_at   timestamptz
) returns record as $$
    begin 

        SELECT 
            U.user_id,
            U.user_name,
            U.user_login,
            U.user_email,
            U.is_superuser,
            U.created_at
                INTO 
                    user_id,
                    user_name,
                    user_login,
                    user_email,
                    is_superuser,
                    created_at
        FROM postgres_ci.users    AS U 
        JOIN postgres_ci.sessions AS S USING(user_id)
        WHERE U.is_deleted = false
        AND   S.session_id = _session_id
        AND   S.expires_at > CURRENT_TIMESTAMP;

        IF NOT FOUND THEN 
        
            SET log_min_messages to LOG;

            RAISE EXCEPTION 'NOT_FOUND' USING ERRCODE = 'no_data_found';
        END IF;

        UPDATE postgres_ci.sessions 
            SET 
                expires_at = CURRENT_TIMESTAMP + '1 hour'::interval 
        WHERE session_id   = _session_id;

    end;
$$ language plpgsql security definer;

/* source file: src/functions/auth/login.sql */

create or replace function auth.login(
    _login         text, 
    _password      text, 
    out session_id text
) returns text as $$
    declare
        _user_id          int;
        _invalid_password boolean;
    begin 

        SELECT
            U.user_id,
            encode(digest(U.salt || _password, 'sha1'), 'hex') != U.hash
            INTO
                _user_id,
                _invalid_password
        FROM  postgres_ci.users AS U
        WHERE lower(U.user_login) = lower(_login)
        AND   is_deleted          = false;

        CASE 
            WHEN NOT FOUND THEN

                SET log_min_messages to LOG;

                RAISE EXCEPTION 'NOT_FOUND' USING ERRCODE = 'no_data_found';

            WHEN _invalid_password THEN 

                SET log_min_messages to LOG;

                RAISE EXCEPTION 'INVALID_PASSWORD' USING ERRCODE = 'invalid_password';
                
            ELSE 
                INSERT INTO postgres_ci.sessions (
                    user_id,
                    expires_at
                ) VALUES (
                    _user_id,
                    CURRENT_TIMESTAMP + '1 hour'::interval
                ) RETURNING sessions.session_id INTO session_id;
        END CASE;
    end;
$$ language plpgsql security definer;

/* source file: src/functions/auth/logout.sql */

create or replace function auth.logout(_session_id text) returns void as $$
    begin 
        DELETE FROM postgres_ci.sessions WHERE session_id = _session_id;
    end;
$$ language plpgsql security definer;

/* source file: src/functions/build/accept.sql */

create or replace function build.accept(
    _build_id int
) returns void as $$
    begin 

        UPDATE postgres_ci.builds 
            SET status = 'accepted' 
        WHERE status   = 'pending' 
        AND   build_id = _build_id;

        IF NOT FOUND THEN 
        
            SET log_min_messages to LOG;

            RAISE EXCEPTION 'NOT_FOUND' USING ERRCODE = 'no_data_found';
        END IF;

    end;
$$ language plpgsql security definer;

/* source file: src/functions/build/add_part.sql */

create or replace function build.add_part(
    _build_id       int,
    _server_version text,
    _docker_image   text,
    _docker_container_id text,
    _output         text,
    _started_at     timestamptz,
    _tests          jsonb,
    out part_id     int
) returns int as $$
    declare 
        _test postgres_ci.tests;
    begin 

        INSERT INTO postgres_ci.parts (
            build_id,
            server_version,
            docker_image,
            docker_container_id,
            output,
            success,
            started_at,
            finished_at
        ) VALUES (
            _build_id,
            _server_version,
            _docker_image,
            _docker_container_id,
            _output,
            true,
            _started_at,
            CURRENT_TIMESTAMP
        ) RETURNING parts.part_id INTO add_part.part_id;

        INSERT INTO postgres_ci.tests (
            part_id,
            namespace,
            procedure,
            errors,
            started_at,
            finished_at
        )
        SELECT 
            add_part.part_id, 
            E.namespace, 
            E.procedure,
            E.errors, 
            E.started_at, 
            E.finished_at 
        FROM jsonb_populate_recordset(null::postgres_ci.tests, _tests) AS E;

        IF EXISTS(
            SELECT 
            FROM postgres_ci.tests 
            WHERE tests.part_id = add_part.part_id 
            AND jsonb_array_length(errors) > 0 
            LIMIT 1
        ) THEN 
            UPDATE postgres_ci.parts SET success = false WHERE parts.part_id = add_part.part_id;
        END IF;

    end;
$$ language plpgsql security definer;


/* source file: src/functions/build/fetch.sql */

create or replace function build.fetch(
    out build_id   int,
    out created_at timestamptz
) returns record as $$
    begin 

        SELECT 
            B.build_id,
            B.created_at
                INTO 
                    build_id,
                    created_at
        FROM postgres_ci.builds AS B
        WHERE B.status = 'pending' 
        LIMIT 1
        FOR UPDATE SKIP LOCKED;

        IF NOT FOUND THEN 
        
            SET log_min_messages to LOG;

            RAISE EXCEPTION 'NO_NEW_TASKS' USING ERRCODE = 'no_data_found';
        END IF;

        UPDATE postgres_ci.builds AS B SET status = 'accepted' WHERE B.build_id = "fetch".build_id;

    end;
$$ language plpgsql security definer;

/* source file: src/functions/build/list.sql */

create or replace function build.list(
    _project_id  int,
    _branch_id   int,
    _limit       int,
    _offset      int,
    out total    bigint,
    out branches jsonb,
    out items    jsonb
) returns record as $$
    begin 

        SELECT 
            (
                SELECT 
                    COALESCE(SUM(counter), 0) 
                FROM postgres_ci.builds_counters
                WHERE project_id = _project_id
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
                        branch_id,
                        branch
                    FROM postgres_ci.branches 
                    WHERE 
                        project_id = _project_id
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
        INTO total, branches, items;

    end;
$$ language plpgsql security definer;



/* source file: src/functions/build/new.sql */

create or replace function build.new(
    _project_id int, 
    _branch_id  int,
    _commit_id  int,
    out build_id int
) returns int as $$
    begin 

        INSERT INTO postgres_ci.builds (
            project_id, 
            branch_id,
            commit_id,
            config,
            status
        ) VALUES (
            _project_id, 
            _branch_id,
            _commit_id,
            '',
            'pending'
        ) RETURNING builds.build_id INTO build_id;

        INSERT INTO postgres_ci.builds_counters AS C (
            project_id, 
            branch_id,
            counter
        ) VALUES (
            _project_id, 
            _branch_id,
            1
        ) ON CONFLICT 
            ON CONSTRAINT unique_builds_counters DO UPDATE 
                SET counter = C.counter + 1;

        PERFORM pg_notify('postgres-ci::tasks', (
                SELECT to_json(T.*) FROM (
                    SELECT 
                        new.build_id      AS build_id,
                        CURRENT_TIMESTAMP AS created_at
                ) T
            )::text
        );

    end;
$$ language plpgsql security definer;

/* source file: src/functions/build/start.sql */

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
        RETURNING B.commit_id INTO _commit_id;

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

/* source file: src/functions/build/stop.sql */

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
        WHERE build_id = _build_id;

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


/* source file: src/functions/build/view.sql */

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
            (
                SELECT 
                    COALESCE(array_to_json(array_agg(P.*)), '[]') 
                FROM (
                    SELECT 
                        part_id,
                        docker_image,
                        server_version,
                        output,
                        success,
                        started_at,
                        finished_at,
                        (
                            SELECT 
                                COALESCE(array_to_json(array_agg(T.*)), '[]') 
                            FROM (
                                SELECT 
                                    namespace,
                                    procedure,
                                    errors,
                                    started_at,
                                    finished_at
                                FROM postgres_ci.tests 
                                WHERE part_id = parts.part_id
                                ORDER BY started_at
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
                parts
        FROM postgres_ci.builds AS B 
            JOIN postgres_ci.projects AS P USING(project_id)
            JOIN postgres_ci.branches AS BR ON BR.branch_id = B.branch_id
            JOIN postgres_ci.commits  AS C  ON C.commit_id  = B.commit_id
        WHERE B.build_id = _build_id;

        IF NOT FOUND THEN 
            SET log_min_messages to LOG;

            RAISE EXCEPTION 'NOT_FOUND' USING ERRCODE = 'no_data_found';
        END IF;
    end;
$$ language plpgsql security definer;



/* source file: src/functions/project/add_commit.sql */

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
                branch_id,
                commit_sha,
                commit_message,
                committed_at,
                committer_name,
                committer_email,
                author_name,
                author_email
            ) VALUES (
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


/* source file: src/functions/project/add.sql */

create or replace function project.add(
    _project_name     text,
    _project_owner_id int,
    _repository_url   text,
    _github_secret    text,
    out project_id    int
) returns int as $$
    begin 

        INSERT INTO postgres_ci.projects (
            project_name,
            project_owner_id,
            repository_url,
            github_name,
            github_secret
        ) VALUES (
            _project_name,
            _project_owner_id,
            _repository_url,
            project.github_name(_repository_url),
            _github_secret
        ) RETURNING projects.project_id INTO project_id;

    end;
$$ language plpgsql security definer;


/* source file: src/functions/project/get_branch_id.sql */

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

/* source file: src/functions/project/github_name.sql */

create or replace function project.github_name(_repository_url text) returns text as $$
    begin 
        CASE  
            WHEN _repository_url LIKE 'https://github\.com%' THEN 
                return replace((string_to_array(_repository_url, 'github.com/'))[2], '.git', '');
            WHEN _repository_url LIKE '%@github\.com:%' THEN 
                return replace((string_to_array(_repository_url, 'github.com:'))[2], '.git', '');
            ELSE 
                return '';
        END CASE;
    end;
$$ language plpgsql security definer;

/* source file: src/functions/project/list.sql */

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

/* source file: src/functions/project/update.sql */

create or replace function project.update(
    _project_id       int,
    _project_name     text,
    _project_owner_id int,
    _repository_url   text,
    _github_secret    text
) returns void as $$
    begin 

        UPDATE postgres_ci.projects 
            SET
                project_name     = _project_name,
                project_owner_id = _project_owner_id,
                repository_url   = _repository_url,
                github_name      = project.github_name(_repository_url),
                github_secret    = _github_secret
        WHERE project_id = _project_id;

        IF NOT FOUND THEN 
            SET log_min_messages to LOG;
            RAISE EXCEPTION 'NOT_FOUND' USING ERRCODE = 'no_data_found';
        END IF;
    end;
$$ language plpgsql security definer;


/* source file: src/functions/hook/commit.sql */

create or replace function hook.commit(
    _token           uuid,
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
        _project_id int;
    begin 

        SELECT project_id INTO _project_id FROM postgres_ci.projects WHERE project_token = _token AND is_deleted = false;
        
        IF NOT FOUND THEN 
        
            SET log_min_messages to LOG;

            RAISE EXCEPTION 'NOT_FOUND' USING ERRCODE = 'no_data_found';
        END IF;

        SELECT project.add_commit(
            _project_id,
            _branch,
            _commit_sha,
            _commit_message,
            _committed_at,
            _committer_name,
            _committer_email,
            _author_name,
            _author_email
        ) INTO commit_id;

    end;
$$ language plpgsql security definer;

/* source file: src/functions/hook/push.sql */

create or replace function hook.push(
    _token   uuid,
    _branch  text,
    _commits jsonb
) returns table (
    commit_id int
) as $$
    declare
        _project_id int;
    begin 

        SELECT project_id INTO _project_id FROM postgres_ci.projects WHERE project_token = _token AND is_deleted = false;
        
        IF NOT FOUND THEN 
        
            SET log_min_messages to LOG;

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

/*

select 
* 
from hook.push('d9a21e59-926d-4083-89b0-463650476eb8', 'master', '[{"commit_sha":"fa7e3d5fc6b69309e2e8eb9e2af82da3cd96f383","commit_message":"Test","committed_at":"2016-05-05T17:40:59.431696+03:00","committer_name":"kshvakov","committer_email":"shvakov@gmail.com","author_name":"kshvakov","author_email":"shvakov@gmail.com","created_at":"2016-05-05T17:40:59.431696+03:00"},{"commit_sha":"654fe21cd1874d3028bfbc84e1ff4b6245cfac9b","commit_message":"add list builds fn\n","committed_at":"2016-05-05T17:53:55+03:00","committer_name":"kshvakov","committer_email":"shvakov@gmail.com","author_name":"kshvakov","author_email":"shvakov@gmail.com","created_at":"2016-05-05T17:53:55.860997+03:00"},{"commit_sha":"ac4c4a78e4f0321d273c0502165c98f8b71d2eb0","commit_message":"misc\n","committed_at":"2016-05-06T11:45:03+03:00","committer_name":"kshvakov","committer_email":"shvakov@gmail.com","author_name":"kshvakov","author_email":"shvakov@gmail.com","created_at":"2016-05-06T11:45:03.421098+03:00"}]');

*/

/* source file: src/functions/password/change.sql */

create or replace function password.change(
    _user_id          int, 
    _current_password text,
    _new_password     text
) returns boolean as $$
    declare
         _salt text;
    begin 

        IF password.check(_user_id, _current_password) THEN 

            _salt = postgres_ci.sha1(gen_salt('md5') || current_timestamp);

            UPDATE postgres_ci.users 
                SET
                    hash  = encode(digest(_salt || _new_password, 'sha1'), 'hex'),
                    salt  = _salt
            WHERE user_id = _user_id; 

        END IF;

        return true;
    end;
$$ language plpgsql security definer;

/* source file: src/functions/password/check.sql */

create or replace function password.check(_user_id int, _password text) returns boolean as $$ 
    declare
        _invalid_password boolean;
    begin 

        SELECT
            encode(digest(U.salt || _password, 'sha1'), 'hex') != U.hash
            INTO
                _invalid_password
        FROM  postgres_ci.users AS U
        WHERE user_id    = _user_id
        AND   is_deleted = false;

        CASE 
            WHEN NOT FOUND THEN

                SET log_min_messages to LOG;

                RAISE EXCEPTION 'NOT_FOUND' USING ERRCODE = 'no_data_found';

            WHEN _invalid_password THEN 

                SET log_min_messages to LOG;

                RAISE EXCEPTION 'INVALID_PASSWORD' USING ERRCODE = 'invalid_password';
            ELSE 
                return true;
        END CASE;
        
    end;
$$ language plpgsql security definer;

/* source file: src/functions/users/add.sql */

create or replace function users.add(
    _user_login   text,
    _password     text,
    _user_name    text,
    _user_email   text,
    _is_superuser boolean,
    out user_id   int
) returns int as $$
    declare
        _salt            text;
        _message         text;
        _column_name     text;
        _constraint_name text;
        _datatype_name   text;
        _table_name      text;
        _schema_name     text;
    begin 

        _salt = postgres_ci.sha1(gen_salt('md5') || current_timestamp);

        BEGIN 

            INSERT INTO postgres_ci.users (
                user_login,
                user_name,
                user_email,
                is_superuser,
                hash,
                salt
            ) VALUES (
                _user_login,
                _user_name,
                _user_email,
                _is_superuser,
                encode(digest(_salt || _password, 'sha1'), 'hex'),
                _salt
            ) RETURNING users.user_id INTO user_id;

        EXCEPTION WHEN OTHERS THEN
        
            GET STACKED DIAGNOSTICS 
                _column_name     = column_name,
                _constraint_name = constraint_name,
                _datatype_name   = pg_datatype_name,
                _table_name      = table_name,
                _schema_name     = schema_name;

            CASE 
                WHEN _constraint_name = 'unique_user_login' THEN
                    _message = 'LOGIN_ALREADY_EXISTS';
                WHEN _constraint_name = 'unique_user_email' THEN 
                    _message = 'EMAIL_ALREADY_EXISTS';
                WHEN _constraint_name = 'check_user_email' THEN 
                    _message = 'INVALID_EMAIL';
                ELSE 
                    _message = SQLERRM;
            END CASE;

            IF _message != SQLERRM THEN 
                SET log_min_messages to LOG;
            END IF;

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




/* source file: src/functions/users/delete.sql */

create or replace function users.delete(_user_id int) returns void as $$
    begin 
    
        UPDATE postgres_ci.users 
            SET 
                is_deleted = true, 
                updated_at = CURRENT_TIMESTAMP
        WHERE user_id  = _user_id
        AND is_deleted = false;

        IF NOT FOUND THEN 
            
            SET log_min_messages to LOG;

            RAISE EXCEPTION 'NOT_FOUND' USING ERRCODE = 'no_data_found';
        END IF;
    end;
$$ language plpgsql security definer;

/* source file: src/functions/users/list.sql */

create or replace function users.list(
    _limit  int,
    _offset int,
    _query  text,

    out total bigint,
    out users jsonb
) returns record as $$ 
    declare
        _pattern text;
    begin 

        IF _query <> '' THEN 
            _pattern = '%' || array_to_string(string_to_array(lower(_query), ' '), '%') || '%';
        END IF;

        SELECT 
            (
                SELECT 
                    COUNT(*) 
                FROM postgres_ci.users
                WHERE is_deleted = false
                AND (
                    CASE WHEN _pattern IS NOT NULL 
                        THEN lower(user_name || user_login || user_email) LIKE _pattern
                        ELSE true
                    END
                )
            ),
            (
                SELECT 
                    COALESCE(array_to_json(array_agg(U.*)), '[]') 
                FROM (
                    SELECT 
                        user_id,
                        user_name,
                        user_login,
                        user_email,
                        is_superuser,
                        created_at,
                        updated_at
                    FROM postgres_ci.users
                    WHERE is_deleted = false
                    AND (
                        CASE WHEN _pattern IS NOT NULL 
                            THEN lower(user_name || user_login || user_email) LIKE _pattern
                            ELSE true
                        END
                    )
                    ORDER BY user_id 
                    LIMIT  _limit
                    OFFSET _offset
                ) U
            )
        INTO total, users;
    end;
$$ language plpgsql security definer;

/* source file: src/functions/users/update.sql */

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
                    is_superuser = _is_superuser
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

            IF _message != SQLERRM THEN 
                SET log_min_messages to LOG;
            END IF;

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


