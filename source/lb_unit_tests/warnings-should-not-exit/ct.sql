--liquibase formatted sql

--changeset jlyle:collection_type_create stripComments:false endDelimiter:/ runOnChange:true
create or replace type jml_test_ct
    force
    is table
    of jml_test_ot;
/
--rollback drop type jml_test_ct force;
