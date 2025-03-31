-- Set sqlblanklines parameter before calling liquibase
-- Because this is set before liquibase is called, each sql change should use
-- the parameter values from the time liquibase is launched as the default
-- values for the sqlcl executor.
-- So set sqlblanklines to on and run a sqlstatement with blanklines to see
-- if it breaks to see if this parameter makes it through to the executor
set sqlblanklines on

liquibase update -database-changelog-table-name &1._changelog -search-path &2/sqlcl-liquibase-set-parameter-becomes-sqlcl-executor-defaults -changelog-file changelog.xml
