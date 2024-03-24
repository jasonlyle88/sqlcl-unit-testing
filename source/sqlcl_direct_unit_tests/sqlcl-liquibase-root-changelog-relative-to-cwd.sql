cd "sqlcl-liquibase-root-changelog-relative-to-cwd"

liquibase update -database-changelog-table-name &1._changelog -changelog-file sqlcl-liquibase-root-changelog-relative-to-cwd-changelog.xml
