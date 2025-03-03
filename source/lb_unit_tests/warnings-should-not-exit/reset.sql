--liquibase formatted sql

--changeset jlyle:object_type_drop stripComments:false endDelimiter:/ runOnChange:true
begin

    begin
        execute immediate 'drop type jml_test_ct';
    exception when others then
        null;
    end;

    begin
        execute immediate 'drop type jml_test_ot';
    exception when others then
        null;
    end;

end;
/
--rollback not required
