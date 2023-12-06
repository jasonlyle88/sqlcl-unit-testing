set define &

column ut_test_var new_value ut_test_var
select
    sys_context('userenv', 'db_name') ut_test_var
from sys.dual;

declare
    l_db_name constant varchar2(4000) := sys_context('userenv', 'db_name');
begin
    if l_db_name != '&ut_test_var' then
        raise_application_error(-20001, 'Single character substitution variable not working');
    end if;


    if l_db_name != '&&ut_test_var' then
        raise_application_error(-20001, 'Double character substitution variable not working');
    end if;
end;
/
