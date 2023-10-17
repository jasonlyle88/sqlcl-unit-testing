# sqlcl-unit-testing

## Description

A bash script for unit testing SQLcl and SQLcl Liquibase features.

This script runs three different kinds of tests:
1. SQLcl (direct)
    - This test type invokes SQLcl and provides the connection information on command line, sets up the session for testing, and then calls the unit test SQL script.
2. SQLcl (wrapped)
    - This test type invokes SQLcl with `nolog` then issues a connect command from inside SQLcl, sets up the session for testing, and then calls the unit test SQL script.
3. SQLcl Liquibase
    - This test type ivokes SQLcl and provies the connection information on the command line, sets up the session for testing, and then calls liquibase update on the provided unit test changelog (using a unique changelog table name).

All tests are run in parallel to improve execution time. However, that means if you have 5 tests, 5 instances of SQLcl will run.

For execution specifics, you can run the command with the `-h` parameter.

## Writing Unit Tests

Unit tests are determined to be passing or failing based on the exit code of SQLcl. Because of this, it is the responsibility of the test writer to ensure that an error is thrown when a test does not meet expectations. The SQLcl session is set up for the user to already have `whenever sqlerror exit failure` set. See the `lb_unit_tests`, `sqlcl_direct_unit_tests`, and `sqlcl_wrapped_unit_tests` directories for examples of unit tests.

## Results

When the unit test script finishes executing, it will output a table summary of the results showing the test type, test name, and test result. There will also be a directory created at the location from which you executed the unit tests called `sqlclUnitTestResults_[YYYYMMDD_HH24MISS]` where the bracketed section is replaced with the timestamp of when the unit test was run. This folder will have a directory for each type of tests, and each of those folders will have a log file per test that contains all the output from SQLcl for that test.

## Example
```shell
> ./source/sqlclUnitTest.sh -u 'user' -c 'localhost' -b /opt/sqlcl/23.3.0.270.1251/bin/sql
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- SQLcl Liquibase Unit Testing
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Check database connection
--------------------------------------------------------------------------------
-- Username          : "user"
-- Connect Identifier: "localhost"
--------------------------------------------------------------------------------
No password was provided. Prompting for password...
Database password:
Database connection test successful!

--------------------------------------------------------------------------------
-- Run unit tests
--------------------------------------------------------------------------------

------------------------------------------------------------
-- SQLcl (direct) unit tests
------------------------------------------------------------
/Users/jlyle/Library/CloudStorage/Dropbox/personal/development/sqlcl-unit-testing/source/sqlcl_direct_unit_tests

Executing test in background: "sqlcl-liquibase-do-not-prompt-password"

------------------------------------------------------------
-- SQLcl (wrapped) unit tests
------------------------------------------------------------
/Users/jlyle/Library/CloudStorage/Dropbox/personal/development/sqlcl-unit-testing/source/sqlcl_wrapped_unit_tests

Executing test in background: "sqlcl-builtin-variable-set-for-wrapped-connect"

------------------------------------------------------------
-- SQLcl Liquibase unit tests
------------------------------------------------------------
/Users/jlyle/Library/CloudStorage/Dropbox/personal/development/sqlcl-unit-testing/source/lb_unit_tests

Executing test in background: "context-filtering-include"
Executing test in background: "context-filtering-includeAll"
Executing test in background: "context-filtering-property"
Executing test in background: "property-cannot-be-reset"
Executing test in background: "relative-to-changelog-works-for-runApexScript"
Executing test in background: "relative-to-changelog-works-for-runOracleScript"
Executing test in background: "sqlclversion-property-exists"

--------------------------------------------------------------------------------
-- Wait for unit test execution to finish
--------------------------------------------------------------------------------
Unit tests finished running.

--------------------------------------------------------------------------------
-- Gather unit test results
--------------------------------------------------------------------------------
Finished gathering unit test results.

--------------------------------------------------------------------------------
-- Unit test results
--------------------------------------------------------------------------------

----------------------------------------------------------------------------------
| Test Type       | Test Name                                       | Test Result
----------------------------------------------------------------------------------
| SQLcl (direct)  | sqlcl-liquibase-do-not-prompt-password          | Failed (2)
| SQLcl (wrapped) | sqlcl-builtin-variable-set-for-wrapped-connect  | Succeeded
| SQLcl Liquibase | context-filtering-include                       | Succeeded
| SQLcl Liquibase | context-filtering-includeAll                    | Succeeded
| SQLcl Liquibase | context-filtering-property                      | Failed (2)
| SQLcl Liquibase | property-cannot-be-reset                        | Succeeded
| SQLcl Liquibase | relative-to-changelog-works-for-runApexScript   | Failed (2)
| SQLcl Liquibase | relative-to-changelog-works-for-runOracleScript | Failed (2)
| SQLcl Liquibase | sqlclversion-property-exists                    | Succeeded
----------------------------------------------------------------------------------
```