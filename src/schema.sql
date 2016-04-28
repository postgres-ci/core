--create schema postgres_ci;
grant execute on all functions in schema postgres_ci to public;

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
    commit_id   int       not null references postgres_ci.commits(commit_id),
    config      text      not null,
    status      postgres_ci.status not null,
    error       text not null default '',
    started_at  timestamptz not null default current_timestamp,
    finished_at timestamptz
);

alter table postgres_ci.projects add foreign key (last_build_id) references postgres_ci.builds(build_id);

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

create unlogged table postgres_ci.tasks(
    task_id    serial      primary key,
    commit_id  int         not null references postgres_ci.commits(commit_id),
    build_id   int         references postgres_ci.builds(build_id),
    status     postgres_ci.status not null default 'pending',
    created_at timestamptz not null default current_timestamp,
    updated_at timestamptz not null default current_timestamp
);

create index idx_task_status on postgres_ci.tasks(status) where status in ('pending', 'accepted');
create index idx_task_build  on postgres_ci.tasks(build_id) where build_id is not null;






/*

select * from users.add('user', 'password', 'User', 'email@email.com', false);
select * from project.add('Postgres-CI Core', 1, '/home/kshvakov/gosrc/src/github.com/postgres-ci/core', '');

SELECT * FROM project.add_commit(1, 'master', 'sha', 'Test', now(), 'kshvakov', 'shvakov@gmail.com', 'kshvakov', 'shvakov@gmail.com');

select task.new(1);
*/