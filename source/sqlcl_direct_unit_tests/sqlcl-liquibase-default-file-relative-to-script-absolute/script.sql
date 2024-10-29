-- Make sure the liquibase changelog table exists
prompt "Run liquibase validate"
liquibase validate -database-changelog-table-name &1._changelog -changelog-file changelog.xml

-- Call to see if functionality works
prompt "Run liquibase update"
liquibase update -database-changelog-table-name &1._changelog -changelog-file changelog.xml -defaults-file liquibase.properties

-- See if any changesets were run
prompt "Check changesets ran"
declare
    c_table_name    constant    varchar2(255 char)  :=  '&1._changelog';
    l_count                     number;
begin
    execute immediate 'select count(1) from ' || c_table_name
    into l_count;

    if l_count = 0 then
        raise_application_error(-20001, 'Liquibase update did not run');
    end if;
end;
/
