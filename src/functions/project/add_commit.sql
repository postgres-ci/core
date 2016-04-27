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
    begin 

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
            project.get_branch_id(_project_id, _branch),
            _commit_sha,
            _commit_message,
            _committed_at,
            _committer_name,
            _committer_email,
            _author_name,
            _author_email
        ) RETURNING commits.commit_id INTO commit_id;

        PERFORM task.new(commit_id);

    end;
$$ language plpgsql security definer;
