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
