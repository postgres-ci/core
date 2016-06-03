drop index postgres_ci.find_user;

create unlogged table postgres_ci.notification(
    build_id   int         not null references postgres_ci.builds(build_id) primary key,
    created_at timestamptz not null default current_timestamp
);

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

insert into postgres_ci.user_notification_method (user_id, method, text_id)
	select user_id, 'email', user_email from postgres_ci.users;


create table postgres_ci.settings (
    smtp_host      text not null,
    smtp_port      int  not null,
    smtp_username  text not null,
    smtp_password  text not null,
    telegram_token text not null
);

insert into postgres_ci.settings values('', 0, '', '', '');