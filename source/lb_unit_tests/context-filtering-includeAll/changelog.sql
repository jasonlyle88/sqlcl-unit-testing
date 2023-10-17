--liquibase formatted sql

--changeset jlyle:context-filtering-includeAll stripComments:false runOnChange:true runAlways:true endDelimiter:/
begin
    raise_application_error(-20001, 'Should be filtered out by the context')
end;
/
--rollback not required