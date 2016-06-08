--create schema postgres_ci;

create or replace function postgres_ci.sha1(_value text) returns text as $$
    begin 
        return encode(digest(_value, 'sha1'), 'hex');
    end;
$$ language plpgsql;

create sequence postgres_ci.users_seq;
create table postgres_ci.users (
    user_id      int         not null default nextval('postgres_ci.users_seq') primary key,
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

create type postgres_ci.notification_method as enum (
    'none',
    'email',
    'telegram'
);

create table postgres_ci.user_notification_method(
    user_id int not null references postgres_ci.users(user_id) primary key,
    method  postgres_ci.notification_method not null default 'none',
    text_id text   not null,
    int_id  bigint not null default 0
);

create unique index unique_user_notification_method 
    on postgres_ci.user_notification_method (method, lower(text_id))
where method <> 'none' and text_id <> '';

create unlogged table postgres_ci.sessions(
    session_id text        not null default    postgres_ci.sha1(gen_salt('md5') || gen_salt('md5')) primary key,
    user_id    int         not null references postgres_ci.users(user_id),
    expires_at timestamptz not null default    current_timestamp
);

create index idx_sessions_expires_at on postgres_ci.sessions(expires_at);

create type postgres_ci.status as enum(
    'pending',
    'accepted',
    'running',
    'failed',
    'success'
);

create sequence postgres_ci.projects_seq;

create table postgres_ci.projects(
    project_id       int     not null default nextval('postgres_ci.projects_seq') primary key,
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

create sequence postgres_ci.branches_seq;

create table postgres_ci.branches(
    branch_id  int    not null default nextval('postgres_ci.branches_seq'),
    branch     text   not null,
    project_id int    not null references postgres_ci.projects(project_id),
    created_at timestamptz not null default current_timestamp,
    primary key (project_id, branch_id)
);

create index idx_branch on postgres_ci.branches (branch_id);

create sequence postgres_ci.commits_seq;

create table postgres_ci.commits(
    commit_id       int         not null default nextval('postgres_ci.commits_seq') primary key,
    project_id      int         not null,
    branch_id       int         not null,
    commit_sha      text        not null,
    commit_message  text        not null,
    committed_at    timestamptz not null,
    committer_name  text        not null,
    committer_email text        not null,
    author_name     text        not null,
    author_email    text        not null,
    created_at      timestamptz not null default current_timestamp,
    constraint check_commit_sha check(length(commit_sha) = 40),
    constraint uniq_commit unique(branch_id, commit_sha),
    foreign key (project_id, branch_id) references postgres_ci.branches(project_id, branch_id) match full
);

create sequence postgres_ci.builds_seq;

create table postgres_ci.builds(
    build_id    int       not null default nextval('postgres_ci.builds_seq') primary key,
    project_id  int       not null,
    branch_id   int       not null,
    commit_id   int       not null references postgres_ci.commits(commit_id),
    config      text      not null,
    status      postgres_ci.status not null,
    error       text not null default '',
    created_at  timestamptz not null default current_timestamp,
    started_at  timestamptz,
    finished_at timestamptz,
    foreign key (project_id, branch_id) references postgres_ci.branches(project_id, branch_id) match full
);

create index idx_new_build on postgres_ci.builds(status) where status in ('pending', 'accepted', 'running');
create index idx_p_b_build on postgres_ci.builds(project_id, branch_id);

alter table postgres_ci.projects add foreign key (last_build_id) references postgres_ci.builds(build_id);

create table postgres_ci.builds_counters(
    project_id  int    not null,
    branch_id   int    not null,
    counter     bigint not null,
    constraint unique_builds_counters unique(project_id, branch_id),
    foreign key (project_id, branch_id) references postgres_ci.branches(project_id, branch_id) match full
);

create unlogged table postgres_ci.notification(
    build_id   int         not null references postgres_ci.builds(build_id) primary key,
    created_at timestamptz not null default current_timestamp
);

create sequence postgres_ci.parts_seq;

create table postgres_ci.parts(
    part_id      int     not null default nextval('postgres_ci.parts_seq') primary key,
    build_id     int     not null references postgres_ci.builds(build_id),
    image        text    not null,
    container_id text    not null,
    version      text    not null,
    output       text    not null,
    success      boolean not null,
    started_at   timestamptz not null,
    finished_at  timestamptz not null
);

create index idx_parts_build on postgres_ci.parts(build_id);

create table postgres_ci.tests(
    part_id     int   not null references postgres_ci.parts(part_id),
    function    text  not null,
    errors      jsonb not null default '[]',
    duration    real  not null
);

create index idx_part_tests on postgres_ci.tests(part_id);

create table postgres_ci.settings (
    app_host       text not null,
    smtp_host      text not null,
    smtp_port      int  not null,
    smtp_username  text not null,
    smtp_password  text not null,
    telegram_token text not null
);

insert into postgres_ci.settings values('', '', 0, '', '', '');

/* select * from users.add('user', 'password', 'User', 'email@email.com', true); */

