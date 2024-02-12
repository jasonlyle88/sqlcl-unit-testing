begin
    for x in (
        select *
        from user_tables
        where table_name = 'DATABASECHANGELOG'
    )
    loop
        execute immediate 'trucate table databasechangelog';
    end loop;
end;
/

liquibase update -search-path &1/sqlcl-liquibase-search-path -changelog-file changelog.xml

declare
    l_count number;
begin
    select count(1)
    into l_count
    from databasechangelog
    where id = 'sqlcl-liquibase-search-path';

    if l_count = 0 then
        raise_application_error(-20001, 'Search path not working');
    end if;
end;
/
