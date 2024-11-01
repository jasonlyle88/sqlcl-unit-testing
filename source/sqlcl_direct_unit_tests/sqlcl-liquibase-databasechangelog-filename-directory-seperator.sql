-- Make sure the liquibase changelog table exists
prompt "Run liquibase validate"
liquibase validate -database-changelog-table-name &1._changelog -changelog-file sqlcl-liquibase-databasechangelog-filename-directory-seperator/changelog.xml

-- Call to see if functionality works
prompt "Run liquibase update"
liquibase update -database-changelog-table-name &1._changelog -changelog-file sqlcl-liquibase-databasechangelog-filename-directory-seperator/changelog.xml

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

-- Check filename directory separator directions
prompt "Check changesets ran"
declare
    c_root          constant    varchar2(255 char)  :=  'sqlcl-liquibase-databasechangelog-filename-directory-seperator';
    c_table_name    constant    varchar2(255 char)  :=  '&1._changelog';
    l_id                        varchar2(255 char);
    l_filename                  varchar2(255 char);
begin
    l_id := 'opensouce_liquibase_change';
    execute immediate 'select filename from ' || c_table_name || ' where id = :1'
    into l_filename
    using in l_id;

    if l_filename != c_root || '/a/b/c/child.sql' then
        raise_application_error(-20002, 'Open source liquibase change did not match expected filename ("' || l_filename || '"")');
    end if;

    l_id := 'sqlcl_liquibase_runoraclescript_change';
    execute immediate 'select filename from ' || c_table_name || ' where id = :1'
    into l_filename
    using in l_id;

    if l_filename != c_root || '/a/b/c/child.xml' then
        raise_application_error(-20003, 'runOracleScript change did not match expected filename ("' || l_filename || '"")');
    end if;

    l_id := 'sqlcl_liquibase_runapexscript_change';
    execute immediate 'select filename from ' || c_table_name || ' where id = :1'
    into l_filename
    using in l_id;

    if l_filename != c_root || '/a/b/c/child.xml' then
        raise_application_error(-20004, 'runApexScript change did not match expected filename ("' || l_filename || '"")');
    end if;
end;
/
