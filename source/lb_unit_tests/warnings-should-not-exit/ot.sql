--liquibase formatted sql

--changeset jlyle:object_type_create stripComments:false endDelimiter:/ runOnChange:true
create or replace type jml_test_ot
    force
    authid definer
    is object(
        seq             number,
        key_string      varchar2(32767),
        value_string    varchar2(32767)
    );
/
--rollback drop type jml_test_ot force;
