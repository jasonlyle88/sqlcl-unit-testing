liquibase update -database-changelog-table-name &1._changelog -search-path &2/sqlcl-liquibase-search-path -changelog-file changelog.xml

declare
    l_count number;
begin
    execute immediate
        q'[select count(1)]' || ' ' ||
        q'[from &1._changelog]' || ' ' ||
        q'[where id = 'sqlcl-liquibase-search-path']'
    into l_count;

    if l_count = 0 then
        raise_application_error(-20001, 'Search path not working');
    end if;
end;
/
