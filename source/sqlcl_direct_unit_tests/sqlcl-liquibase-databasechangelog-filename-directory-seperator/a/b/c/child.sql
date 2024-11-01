--liquibase formatted sql

--changeset jlyle:opensouce_liquibase_change stripComments:false runOnChange:true runAlways:false
select 1 from sys.dual;
--rollback not required
