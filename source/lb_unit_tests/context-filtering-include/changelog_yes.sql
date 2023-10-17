--liquibase formatted sql

--changeset jlyle:context-filtering-include stripComments:false runOnChange:true runAlways:true endDelimiter:/
begin
    null;
end;
/
--rollback not required