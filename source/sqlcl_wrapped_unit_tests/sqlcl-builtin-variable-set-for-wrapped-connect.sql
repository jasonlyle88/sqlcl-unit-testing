-- Make sure _SQLPLUS_RELEASE exists.
-- If it already exists, don't do anything to it.
-- If it does not exist, then set it to null
column  _SQLPLUS_RELEASE    new_value   _SQLPLUS_RELEASE
select null "_SQLPLUS_RELEASE"
from sys.dual
where 1=2;

begin
    if '&&_SQLPLUS_RELEASE' is null then
        raise_application_error(-20001, '_SQLPLUS_RELEASE missing!');
    end if;
end;
/
