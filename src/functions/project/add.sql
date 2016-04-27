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
