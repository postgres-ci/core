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