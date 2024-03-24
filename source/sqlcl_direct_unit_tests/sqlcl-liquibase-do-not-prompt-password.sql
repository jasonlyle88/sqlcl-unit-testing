liquibase update -database-changelog-table-name &1._changelog -search-path &2/sqlcl-liquibase-do-not-prompt-password -changelog-file changelog.xml

select 'test'
from sys.dual;
