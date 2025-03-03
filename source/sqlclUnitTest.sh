#!/usr/bin/env bash

function main() {
    ############################################################################
    #
    # Functions
    #
    ############################################################################
    function usage() {
        printf -- 'This script runs unit tests for SQLcl and SQLcl Liquibase\n'
        printf -- '\n'
        printf -- 'This script runs SQLcl and SQLcl Liquibase unit tests against\n'
        printf -- 'the given database user. There are 3 types of tests:\n'
        printf -- '     1)  SQLcl (direct):\n'
        printf -- '         SQLcl is run with the connect identifier and\n'
        printf -- '         the unit test script on the command line.\n'
        printf -- '     2)  SQLcl (wrapped):\n'
        printf -- '         SQLcl is run using the /nolog parameter. A wrapper\n'
        printf -- '         script file is then written that issues a connect\n'
        printf -- '         command and then calls the unit test script.\n'
        printf -- '     3)  SQLcl Liquibase:\n'
        printf -- '         SQLcl Liquibase is run  passing the unit test as\n'
        printf -- '         the changelog file.\n'
        printf -- 'All unit tests are only searched for at the first level of the\n'
        printf -- 'unit test directory. Directories with files can be put in the\n'
        printf -- 'unit test directories to provide additional files to be run\n'
        printf -- 'by a top level unit test file.\n'
        printf -- 'SQLcl direct and wrapped tests only look for files with a\n'
        printf -- '".sql" extension.\n'
        printf -- 'SQLcl Liquibase tests only look for files with ".xml", ".sql",\n'
        printf -- '".yml", and ".json" extensions.\n'
        printf -- '\n'
        printf -- 'The following arguments are recognized (* = required)\n'
        printf -- '\n'
        printf -- '  -b {SQLcl binary}  --  The SQLcl binary to test.\n'
        printf -- '                         If not provided, will default to "sql".\n'
        printf -- '* -u {username}      --  The username used to connect to the database\n'
        printf -- '  -p {password}      --  The password used to connect to the database\n'
        printf -- '                         If not provided, the user will be prompted for\n'
        printf -- '                         a password.\n'
        printf -- '* -c {connection}    --  The connect identifier used to connect to the database.\n'
        printf -- '  -C {wallet}        --  The cloud wallet used to connect to the database.\n'
        printf -- '  -d {directory}     --  The directory containing SQLcl (direct) tests to run.\n'
        printf -- '                         If not provided, will default to "sqlcl_direct_unit_tests"\n'
        printf -- '                         directory in the same directory as this script.\n'
        printf -- '  -w {directory}     --  The directory containing SQLcl (wrapped) tests to run.\n'
        printf -- '                         If not provided, will default to "sqlcl_wrapped_unit_tests"\n'
        printf -- '                         directory in the same directory as this script.\n'
        printf -- '  -l {directory}     --  The directory containing SQLcl Liquibase tests to run.\n'
        printf -- '                         If not provided, will default to "lb_unit_tests"\n'
        printf -- '                         directory in the same directory as this script.\n'
        printf -- '  -P {type}          --  The parallelization type to use for this execution.\n'
        printf -- '                         Accepts one of the following types:\n'
        printf -- '                             NONE - Execute all tests serially\n'
        printf -- '                             TYPE - Execute all tests for a each test type in parallel (default)\n'
        printf -- '                             TEST - Execute all tests in parallel\n'
        printf -- '  -h                 --  Show this help.\n'
        printf -- '\n'
        printf -- 'Example:\n'
        printf -- '  %s -u admin -c localhost\n' "${scriptName}"
        printf -- '\n'

        return 0
    } # usage

    function toUpperCase() {
        ########################################################################
        #   toUpperCase
        #
        #   Return a string with all upper case letters
        #
        #   All parameters are taken as a single string to get in all upper case
        #
        #   upperCaseVar="$(toUpperCase "${var}")"
        ########################################################################
        local string="$*"

        printf -- '%s' "${string}" | tr '[:lower:]' '[:upper:]'

        return 0
    } # toUpperCase

    function toLowerCase() {
        ########################################################################
        #   toLowerCase
        #
        #   Return a string with all lower case letters
        #
        #   All parameters are taken as a single string to get in all lower case
        #
        #   toLowerCase="$(toUpperCase "${var}")"
        ########################################################################
        local string="${*}"

        printf -- '%s' "${string}" | tr '[:upper:]' '[:lower:]'

        return 0
    } # toUpperCase

    function getCanonicalPath() {
        ########################################################################
        #   getCanonicalPath
        #
        #   Return a path that is both absolute and does not contain any
        #   symbolic links. Always returns without a trailing slash.
        #
        #   The first parameter is the path to canonicalize
        #
        #   canonicalPath="$(getCanonicalPath "${somePath}")"
        ########################################################################
        local target="${1}"

        if [ -d "${target}" ]; then
            # dir
            (cd "${target}" || exit; pwd -P)
        elif [ -f "${target}" ]; then
            # file
            if [[ "${target}" = /* ]]; then
                # Absolute file path
                (cd "$(dirname "${target}")" || exit; printf -- '%s/%s\n' "$(pwd -P)" "$(basename "${target}")")
            elif [[ "${target}" == */* ]]; then
                # Relative file with path
                printf -- '%s\n' "$(cd "${target%/*}" || exit; pwd -P)/${target##*/}"
            else
                # Relative file without path
                printf -- '%s\n' "$(pwd -P)/${target}"
            fi
        fi
    } # getCanonicalPath

    function getTestResultPlainString() {
        local testResultCode="${1}"
        local testResultString

        if [[ "${testResultCode}" -eq 0 ]]; then
            testResultString="${testSuccessText}"
        else
            testResultString="${textFailedText} (${testResultCode})"
        fi

        printf -- '%s' "${testResultString}"
    } # getTestResultPlainString

    function getTestResultColorizedString() {
        local testResultCode="${1}"
        local testResultString

        testResultString="$(getTestResultPlainString "${testResultCode}")"

        if [[ "${colorSupport}" -ge 8 ]]; then
            if [[ "${testResultString}" = "${testSuccessText}" ]]; then
                testResultString="${textBold}${textGreen}${testResultString}${textReset}"
            else
                testResultString="${textBold}${textRed}${testResultString}${textReset}"
            fi
        fi

        printf -- '%s' "${testResultString}"
    } # getTestResultColorizedString

    function convertToWindowsPath() {
        local originalUnixPath="$1"
        local unixPath="${originalUnixPath}"
        local windowsPath

        # Convert drive letter
        if [[ "${unixPath:0:1}" == '/' ]]; then
            windowsPath="${unixPath:1:1}:\\"

            # Ensure the drive letter is upper case
            windowsPath="$(toUpperCase "${windowsPath}")"

            unixPath="${unixPath:3}"
        fi

        windowsPath="${windowsPath}$(printf -- '%s' "${unixPath}" | sed 's|/|\\|g')"

        printf -- '%s\n' "${windowsPath}"
    } # convertToWindowsPath

    function executeUnitTest() {
        local testType="$1"
        local testFile="$2"

        local functionPid
        #shellcheck disable=2016
        functionPid="$($SHELL -c 'echo $PPID')"
        local functionUniqueIdentifier="${scriptUniqueIdentifier}_${functionPid}"
        local databaseChangelogTableName="${functionUniqueIdentifier}_changelog"
        local testDirectory
        local testFilename
        local testName
        local testResultCode
        local resultFile
        local logFile
        local wrapperFile
        local nologParam
        local testFileOS
        local testFilenameOS
        local testDirectoryOS

        testDirectory="$(dirname "${testFile}")"
        testFilename="$(basename "${testFile}")"
        testName="${testFilename%.*}"
        testResultCode=-1

        cd "${testDirectory}" || return 1

        # Determine cross-os specific variables needed for execute
        if [[ "${OSTYPE}" == "cygwin" || "${OSTYPE}" == "msys" || "${OSTYPE}" == "win32" ]]; then
            # Handle Windows systems
            nologParam="//nolog"

            testFileOS="$(convertToWindowsPath "${testFile}")"
            testDirectoryOS="$(convertToWindowsPath "${testDirectory}")"
            testFilenameOS="$(convertToWindowsPath "${testFilename}")"
        else
            # Handle linux/unix based systems
            nologParam="/nolog"

            testFileOS="${testFile}"
            testDirectoryOS="${testDirectory}"
            testFilenameOS="${testFilename}"
        fi

        # Make sure SQLPATH is not set for SQLcl execution so no login.sql
        # script is runs
        export SQLPATH=""

        if [[ "${testType}" = "${testTypeSqlclDirect}" ]]; then
            resultFile="${directTestResultFile}"
            logFile="${logDirectory}/direct/${testName}.log"

            mkdir -p "$(dirname "${logFile}")"
            touch "${logFile}"

            printf -- 'Execution unique Identifier: "%s"\n\n' "${functionUniqueIdentifier}" 1>>"${logFile}"

            "${sqlclBinary}" "${sqlParamsDirectConnect[@]}" "${sqlParamsWithoutPassword[@]}" 1>>"${logFile}" 2>&1 <<- EOF
				${databasePassword}
				whenever sqlerror exit failure
				set serveroutput on size unlimited
				set verify on
				set echo on
				show connection
				@ "${testFileOS}" "${functionUniqueIdentifier}" "${testDirectoryOS}"
				EOF
            testResultCode=$?

        elif [[ "${testType}" = "${testTypeSqlclWrapped}" ]]; then
            resultFile="${wrappedTestResultFile}"
            logFile="${logDirectory}/wrapped/${testName}.log"
            wrapperFile="${workingDirectory}/${functionUniqueIdentifier}-wrapper.sql"

            mkdir -p "$(dirname "${logFile}")"
            touch "${logFile}"

            printf -- 'Execution unique Identifier: "%s"\n\n' "${functionUniqueIdentifier}" 1>>"${logFile}"

            {
                printf -- 'whenever sqlerror exit failure\n'
                printf -- 'connect %s\n' "${sqlParamsWithPassword[*]}"
                printf -- 'set serveroutput on size unlimited\n'
                printf -- 'set verify on\n'
                printf -- 'set echo on\n'
                printf -- 'show connection\n'
                printf -- '@ "%s" "%s" "%s"' "${testFileOS}" "${functionUniqueIdentifier}" "${testDirectoryOS}"
            } > "${wrapperFile}"

            "${sqlclBinary}" -noupdates "${nologParam}" "@${wrapperFile}" 1>>"${logFile}" 2>&1
            testResultCode=$?

            rm "${wrapperFile}"
        elif [[ "${testType}" = "${testTypeSqlclLiquibaseCurrentDirectory}" ]]; then
            resultFile="${liquibaseCurrentDirectoryTestResultFile}"
            logFile="${logDirectory}/liquibase-current-directory/${testName}.log"

            mkdir -p "$(dirname "${logFile}")"
            touch "${logFile}"

            printf -- 'Execution unique Identifier: "%s"\n\n' "${functionUniqueIdentifier}" 1>>"${logFile}"

            cd "${testDirectory}" || return 1

            "${sqlclBinary}" "${sqlParamsDirectConnect[@]}" "${sqlParamsWithPassword[@]}" 1>>"${logFile}" 2>&1 <<- EOF
				whenever sqlerror exit failure
				set serveroutput on size unlimited
				set verify on
				set echo on
				show connection
				liquibase update -contexts test_context -database-changelog-table-name ${databaseChangelogTableName} -changelog-file ${testFilenameOS}
				EOF
            testResultCode=$?
        elif [[ "${testType}" = "${testTypeSqlclLiquibaseSearchPath}" ]]; then
            resultFile="${liquibaseSearchPathTestResultFile}"
            logFile="${logDirectory}/liquibase-search-path/${testName}.log"

            mkdir -p "$(dirname "${logFile}")"
            touch "${logFile}"

            printf -- 'Execution unique Identifier: "%s"\n\n' "${functionUniqueIdentifier}" 1>>"${logFile}"

            "${sqlclBinary}" "${sqlParamsDirectConnect[@]}" "${sqlParamsWithPassword[@]}" 1>>"${logFile}" 2>&1 <<- EOF
				whenever sqlerror exit failure
				set serveroutput on size unlimited
				set verify on
				set echo on
				show connection
                prompt "Provided search path: '${testDirectoryOS}'"
				liquibase update -contexts test_context -database-changelog-table-name ${databaseChangelogTableName} -search-path ${testDirectoryOS} -changelog-file ${testFilenameOS}
				EOF
            testResultCode=$?
        fi

        printf -- '%s:%s\n' "${testName}" "${testResultCode}" >> "${resultFile}"
    } # executeUnitTest

    ############################################################################
    #
    # Variables
    #
    ############################################################################

    ############################################################################
    ##  Configurable variables
    ############################################################################
    local testTypeSqlclDirect='SQLcl (direct)'
    local testTypeSqlclWrapped='SQLcl (wrapped)'
    local testTypeSqlclLiquibaseCurrentDirectory='SQLcl Liquibase (current directory)'
    local testTypeSqlclLiquibaseSearchPath='SQLcl Liquibase (search-path)'
    local testSuccessText='Succeeded'
    local textFailedText='Failed'
    local testTypeSummaryHeader='Test Type'
    local testNameSummaryHeader='Test Name'
    local testResultSummaryHeader='Test Result'

    ############################################################################
    ##  Script info
    ############################################################################
    local scriptName
    local scriptPath

    # shellcheck disable=SC2034
    scriptName="$(basename -- "${BASH_SOURCE[0]}")"
    # shellcheck disable=SC2034
    scriptPath="$(getCanonicalPath "$(dirname -- "${BASH_SOURCE[0]}")")"

    ############################################################################
    ##  Parameter variables
    ############################################################################
    local OPTIND
    local OPTARG
    local opt

    local bFlag='false'
    local uFlag='false'
    local pFlag='false'
    local cFlag='false'
    local CFlag='false'
    local dFlag='false'
    local wFlag='false'
    local lFlag='false'
    local PFlag='false'

    local sqlclBinary
    local databaseUsername
    local databasePassword
    local databaseConnectIdentifier
    local databaseCloudWallet
    local sqlclDirectTestsDirectory
    local sqlclWrappedTestsDirectory
    local liquibaseTestsDirectory
    local parallelizationType

    ############################################################################
    ##  Constants
    ############################################################################
    # shellcheck disable=SC2034,SC2155
    local h1="$(printf "%0.s-" {1..80})"
    # shellcheck disable=SC2034,SC2155
    local h2="$(printf "%0.s-" {1..60})"
    # shellcheck disable=SC2034,SC2155
    local h3="$(printf "%0.s-" {1..40})"
    # shellcheck disable=SC2034,SC2155
    local h4="$(printf "%0.s-" {1..20})"
    # shellcheck disable=SC2034,SC2155
    local hs="$(printf "%0.s-" {1..2})"
    # shellcheck disable=SC2034
    local originalPWD="${PWD}"
    # shellcheck disable=SC2034
    local originalIFS="${IFS}"
    # shellcheck disable=SC2034
    local scriptPid="${$}"
    # shellcheck disable=SC2034
    local scriptUniqueIdentifier="sqlcl_ut_${scriptPid}"

    ############################################################################
    ##  Procedural variables
    ############################################################################
    local workingDirectory
    local sqlWheneverErrorTest
    local liquibaseWehenverErrorTest
    local directTestResultFile
    local wrappedTestResultFile
    local liquibaseCurrentDirectoryTestResultFile
    local liquibaseSearchPathTestResultFile
    local logDirectory
    local logMainFile
    local -a sqlParamsDirectConnect=('-S' '-L' '-noupdates')
    local -a sqlParamsWithPassword
    local -a sqlParamsWithoutPassword
    local index
    local headerText
    local testsDirectory
    local testFile
    local testExtension
    local testFilename
    local testTypePrevious
    local testType
    local testName
    local testResultFile
    local testResultCode
    local testResultPlainString
    local testResultColorizedString
    local -a testTypes
    local -a testNames
    local -a testResultCodes
    local -a testResultPlainStrings
    local -a testResultColorizedStrings
    local longestTestTypeLength
    local longestTestNameLength
    local longestTestResultLength
    local tableWidth
    local tableFormat
    local resultSeparatorCount
    local overallTestResultCode

    local colorSupport
    local textReset
    local textBold
    local textRed
    local textGreen

    colorSupport="$(tput colors)"

    textReset="$(tput sgr0)"
    textBold="$(tput bold)"
    textRed="$(tput setaf 1)"
    textGreen="$(tput setaf 2)"

    ############################################################################
    #
    # Option parsing
    #
    ############################################################################
    while getopts ':b:u:p:c:C:d:w:l:P:h' opt
    do

        case "${opt}" in
        'b')
            bFlag='true'
            sqlclBinary="${OPTARG}"
            ;;
        'u')
            uFlag='true'
            databaseUsername="${OPTARG}"
            ;;
        'p')
            pFlag='true'
            databasePassword="${OPTARG}"
            ;;
        'c')
            cFlag='true'
            databaseConnectIdentifier="${OPTARG}"
            ;;
        'C')
            CFlag='true'
            databaseCloudWallet="${OPTARG}"
            ;;
        'd')
            dFlag='true'
            sqlclDirectTestsDirectory="${OPTARG}"
            ;;
        'w')
            wFlag='true'
            sqlclWrappedTestsDirectory="${OPTARG}"
            ;;
        'l')
            lFlag='true'
            liquibaseTestsDirectory="${OPTARG}"
            ;;
        'P')
            PFlag='true'
            parallelizationType="$(toUpperCase "${OPTARG}")"
            ;;
        'h')
            usage
            return $?
            ;;
        '?')
            printf -- 'ERROR: Invalid option -%s\n\n' "${OPTARG}" >&2
            usage >&2
            return 3
            ;;
        ':')
            printf -- 'ERROR: Option -%s requires an argument.\n' "${OPTARG}" >&2
            return 4
            ;;
        esac

    done

    ############################################################################
    #
    # Parameter handling
    #
    ############################################################################

    ##
    ##  Setup parameter defaults
    ##

    if [[ "${bFlag}" != 'true' ]]; then
        sqlclBinary='sql'
    fi

    if [[ "${dFlag}" != 'true' ]]; then
        sqlclDirectTestsDirectory="${scriptPath}/sqlcl_direct_unit_tests"
    fi

    if [[ "${wFlag}" != 'true' ]]; then
        sqlclWrappedTestsDirectory="${scriptPath}/sqlcl_wrapped_unit_tests"
    fi

    if [[ "${lFlag}" != 'true' ]]; then
        liquibaseTestsDirectory="${scriptPath}/lb_unit_tests"
    fi

    if [[ "${PFlag}" != 'true' ]]; then
        parallelizationType="TYPE"
    fi

    ############################################################################
    #
    # Function Logic
    #
    ############################################################################
    # Setup log directory
    logDirectory="${originalPWD}/sqlclUnitTestResults_$(date +%Y%m%d_%H%M%S)"
    logMainFile="${logDirectory}/execution.log"
    mkdir "${logDirectory}"
    touch "${logMainFile}"

    printf -- '%s\n' "${h1}" | tee "${logMainFile}"
    printf -- '%s\n' "${h1}" | tee -a "${logMainFile}"
    printf -- '%s %s\n' "${hs}" 'SQLcl Unit Testing' | tee -a "${logMainFile}"
    printf -- '%s\n' "${h1}" | tee -a "${logMainFile}"
    printf -- '%s\n' "${h1}" | tee -a "${logMainFile}"

    ##
    ##  Check for required parameters
    ##

    if [[ "${uFlag}" != 'true' ]]; then
        printf -- 'ERROR: Database username (-u) must be specified.\n' | tee -a "${logMainFile}" >&2
        return 11
    fi

    if [[ "${cFlag}" != 'true' ]]; then
        printf -- 'ERROR: Database connect identifier (-c) must be specified.\n' | tee -a "${logMainFile}" >&2
        return 12
    fi

    ##
    ##  Validate parameters
    ##

    if ! command -v "${sqlclBinary}" 1>/dev/null 2>&1; then
        printf -- 'ERROR: Invalid SQLcl binary: "%s"\n' "${sqlclBinary}" | tee -a "${logMainFile}" >&2
        return 13
    fi

    if [[ ! -d "${sqlclDirectTestsDirectory}" ]]; then
        printf -- 'ERROR: SQLcl (direct) unit testing directory is not a directory: "%s"\n' "${sqlclDirectTestsDirectory}" | tee -a "${logMainFile}" >&2
        return 14
    fi

    if [[ ! -d "${sqlclWrappedTestsDirectory}" ]]; then
        printf -- 'ERROR: SQLcl (wrapped) unit testing directory is not a directory: "%s"\n' "${sqlclWrappedTestsDirectory}" | tee -a "${logMainFile}" >&2
        return 15
    fi

    if [[ ! -d "${liquibaseTestsDirectory}" ]]; then
        printf -- 'ERROR: SQLcl Liquibase unit testing directory is not a directory: "%s"\n' "${liquibaseTestsDirectory}" | tee -a "${logMainFile}" >&2
        return 16
    fi

    if [[ "${CFlag}" == 'true' ]] && [[ ! -f "${databaseCloudWallet}" ]]; then
        printf -- 'ERROR: Cannot find specified cloud wallet: "%s"\n' "${databaseCloudWallet}" | tee -a "${logMainFile}" >&2
        return 17
    fi

    if [[ "${parallelizationType}" != 'NONE' ]] && [[ "${parallelizationType}" != 'TYPE' ]] && [[ "${parallelizationType}" != 'TEST' ]]; then
        printf -- 'ERROR: Invalid parallelization type (-P): "%s"\n' "${parallelizationType}" | tee -a "${logMainFile}" >&2
        return 18
    fi

    ##
    ## Manipulate parameters
    ##
    sqlclDirectTestsDirectory="$(getCanonicalPath "${sqlclDirectTestsDirectory}")"
    sqlclWrappedTestsDirectory="$(getCanonicalPath "${sqlclWrappedTestsDirectory}")"
    liquibaseTestsDirectory="$(getCanonicalPath "${liquibaseTestsDirectory}")"

    if [[ "${bFlag}" == 'true' ]]; then
        sqlclBinary="$(getCanonicalPath "${sqlclBinary}")"
    fi

    if [[ "${CFlag}" == 'true' ]]; then
        databaseCloudWallet="$(getCanonicalPath "${databaseCloudWallet}")"
    fi

    sqlParamsWithoutPassword=()
    if [[ "${CFlag}" == 'true' ]]; then
        sqlParamsWithoutPassword+=('-cloudconfig' "${databaseCloudWallet}")
    fi

    printf -- '\n' | tee -a "${logMainFile}"
    printf -- '%s\n' "${h1}" | tee -a "${logMainFile}"
    printf -- '%s %s\n' "${hs}" 'SQLcl Version' | tee -a "${logMainFile}"
    printf -- '%s\n' "${h1}" | tee -a "${logMainFile}"
    "${sqlclBinary}" -V | tee -a "${logMainFile}"

    printf -- '\n' | tee -a "${logMainFile}"
    printf -- '%s\n' "${h1}" | tee -a "${logMainFile}"
    printf -- '%s %s\n' "${hs}" 'Check database connection' | tee -a "${logMainFile}"
    printf -- '%s\n' "${h1}" | tee -a "${logMainFile}"
    printf -- '%s %s: "%s"\n' "${hs}" 'Username          ' "${databaseUsername}" | tee -a "${logMainFile}"
    printf -- '%s %s: "%s"\n' "${hs}" 'Connect Identifier' "${databaseConnectIdentifier}" | tee -a "${logMainFile}"
    printf -- '%s\n' "${h1}" | tee -a "${logMainFile}"

    # Prompt for database password
    if [[ "${pFlag}" != 'true' ]]; then
        printf -- 'No password was provided. Prompting for password...\n' | tee -a "${logMainFile}"
        printf -- 'Database password: ' | tee -a "${logMainFile}"
        read -rs databasePassword

        printf -- '\n' | tee -a "${logMainFile}"
    fi

    sqlParamsWithoutPassword+=("-user" "\"${databaseUsername}\"" "-url" "\"${databaseConnectIdentifier}\"")
    sqlParamsWithPassword+=("${sqlParamsWithoutPassword[@]}" "-password" "\"${databasePassword}\"")

    if ! "${sqlclBinary}" "${sqlParamsDirectConnect[@]}" "${sqlParamsWithPassword[@]}" 1>>"${logMainFile}" 2>&1 <<- EOF
		show connection
		exit
		EOF
    then
        printf -- 'ERROR: Could not connect to database\n' | tee -a "${logMainFile}" >&2
        return 25
    fi

    printf -- 'Database connection test successful!\n' | tee -a "${logMainFile}"

    # Setup temporary directory
    workingDirectory="$(mktemp -d)"

    printf -- '\n' | tee -a "${logMainFile}"
    printf -- '%s\n' "${h1}" | tee -a "${logMainFile}"
    printf -- '%s %s\n' "${hs}" 'Check SQL error exits SQLcl' | tee -a "${logMainFile}"
    printf -- '%s\n' "${h1}" | tee -a "${logMainFile}"

    # Setup testfiles to check `whenever sqlerror exit failure` and liquibase
    sqlWheneverErrorTest="${workingDirectory}/wheneverError.sql"
    liquibaseWehenverErrorTest="${workingDirectory}/wheneverError.xml"
    touch "${sqlWheneverErrorTest}"
    touch "${liquibaseWehenverErrorTest}"

    {
        printf -- 'whenever sqlerror exit failure\n'
		printf -- 'show connection\n'
        printf -- 'exec raise_application_error(-20001, '\''Cause exit'\'')\n'
        printf -- 'exit'
    } > "${sqlWheneverErrorTest}"

    if "${sqlclBinary}" "${sqlParamsDirectConnect[@]}" "${sqlParamsWithPassword[@]}" @"${sqlWheneverErrorTest}" 1>>"${logMainFile}" 2>&1; then
        printf -- 'ERROR: SQLcl not exiting appropriately on SQL error\n' | tee -a "${logMainFile}" >&2
        return 26
    fi

    printf -- 'SQL error exits SQLcl test successful!\n' | tee -a "${logMainFile}"

    printf -- '\n' | tee -a "${logMainFile}"
    printf -- '%s\n' "${h1}" | tee -a "${logMainFile}"
    printf -- '%s %s\n' "${hs}" 'Check Liquibase error exits SQLcl' | tee -a "${logMainFile}"
    printf -- '%s\n' "${h1}" | tee -a "${logMainFile}"

    {
        printf -- 'whenever sqlerror exit failure\n'
		printf -- 'show connection\n'
        printf -- 'liquibase update -database-changelog-table-name %s -changelog-file %s\n' "${scriptUniqueIdentifier}_changelog" "$(basename "${liquibaseWehenverErrorTest}")"
        printf -- 'exit'
    } > "${sqlWheneverErrorTest}"

    {
        printf -- '<?xml version="1.0" encoding="UTF-8"?>\n'
        printf -- '<databaseChangeLog\n'
        printf -- '    xmlns="http://www.liquibase.org/xml/ns/dbchangelog"\n'
        printf -- '    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"\n'
        printf -- '    xmlns:ora="http://www.oracle.com/xml/ns/dbchangelog-ext"\n'
        printf -- '    xsi:schemaLocation="http://www.liquibase.org/xml/ns/dbchangelog http://www.liquibase.org/xml/ns/dbchangelog/dbchangelog-4.17.xsd"\n'
        printf -- '>\n'
        printf -- '    <changeSet\n'
        printf -- '        id="throw_error"\n'
        printf -- '        author="jlyle"\n'
        printf -- '        runOnChange="true"\n'
        printf -- '        runAlways="true"\n'
        printf -- '    >\n'
        printf -- '        <sql endDelimiter="/">\n'
        printf -- '            begin\n'
        printf -- '                null;\n'
        printf -- '                raise_application_error(-20001, '\''Cause exit'\'');\n'
        printf -- '            end;\n'
        printf -- '            /\n'
        printf -- '        </sql>\n'
        printf -- '    </changeSet>\n'
        printf -- '</databaseChangeLog>\n'
    } > "${liquibaseWehenverErrorTest}"

    cd "${workingDirectory}" || return 1
    if "${sqlclBinary}" "${sqlParamsDirectConnect[@]}" "${sqlParamsWithPassword[@]}" @"${sqlWheneverErrorTest}" 1>>"${logMainFile}" 2>&1; then
        cd "${originalPWD}" || return 1
        printf -- 'ERROR: SQLcl not exiting appropriately on Liquibase error\n' | tee -a "${logMainFile}" >&2
        return 27
    fi
    cd "${originalPWD}" || return 1


    printf -- 'Liquibase error exits SQLcl test successful!\n' | tee -a "${logMainFile}"

    printf -- '\n' | tee -a "${logMainFile}"
    printf -- '%s\n' "${h1}" | tee -a "${logMainFile}"
    printf -- '%s %s\n' "${hs}" 'Run unit tests' | tee -a "${logMainFile}"
    printf -- '%s\n' "${h1}" | tee -a "${logMainFile}"

    # Setup unit test result files
    directTestResultFile="${workingDirectory}/directResults.txt"
    wrappedTestResultFile="${workingDirectory}/wrappedResults.txt"
    liquibaseCurrentDirectoryTestResultFile="${workingDirectory}/liquibaseCurrentDirectoryResults.txt"
    liquibaseSearchPathTestResultFile="${workingDirectory}/liquibaseSearchPathResults.txt"
    touch "${directTestResultFile}"
    touch "${wrappedTestResultFile}"
    touch "${liquibaseCurrentDirectoryTestResultFile}"
    touch "${liquibaseSearchPathTestResultFile}"

    for index in {1..4}; do
        if [[ "$index" -eq 1 ]]; then
            headerText='SQLcl (direct) unit tests'
            testType="${testTypeSqlclDirect}"
            testsDirectory="${sqlclDirectTestsDirectory}"
            testExtension='*.sql'
        elif [[ "$index" -eq 2 ]]; then
            headerText='SQLcl (wrapped) unit tests'
            testType="${testTypeSqlclWrapped}"
            testsDirectory="${sqlclWrappedTestsDirectory}"
            testExtension='*.sql'
        elif [[ "$index" -eq 3 ]]; then
            headerText='SQLcl Liquibase unit tests (current directory)'
            testType="${testTypeSqlclLiquibaseCurrentDirectory}"
            testsDirectory="${liquibaseTestsDirectory}"
            testExtension='*.xml'
        elif [[ "$index" -eq 4 ]]; then
            headerText='SQLcl Liquibase unit tests (-search-path)'
            testType="${testTypeSqlclLiquibaseSearchPath}"
            testsDirectory="${liquibaseTestsDirectory}"
            testExtension='*.xml'
        fi

        printf -- '\n' | tee -a "${logMainFile}"
        printf -- '%s\n' "${h2}" | tee -a "${logMainFile}"
        printf -- '%s %s\n' "${hs}" "${headerText}" | tee -a "${logMainFile}"
        printf -- '%s\n' "${h2}" | tee -a "${logMainFile}"
        printf -- '%s\n' "${testsDirectory}" | tee -a "${logMainFile}"
        printf -- '\n' | tee -a "${logMainFile}"

        while IFS= read -r testFile; do
            testFilename="$(basename "${testFile}")"
            testName="${testFilename%.*}"

            printf -- 'Executing test in background: "%s"\n' "${testName}" | tee -a "${logMainFile}"

            executeUnitTest "${testType}" "${testFile}" &

            # Wait for test to finish if no parallel execution was requested
            if [[ "${parallelizationType}" == 'NONE' ]]; then
                wait
            fi
        done < <( find "${testsDirectory}" -mindepth '1' -maxdepth '1' -type 'f' -iname "${testExtension}" | sort )

        ##
        ## Wait for unit test execution to finish if TYPE parallelization type was requested
        ##
        if [[ "${parallelizationType}" == 'TYPE' ]]; then
            printf -- '\n' | tee -a "${logMainFile}"
            printf -- '%s\n' "${h1}" | tee -a "${logMainFile}"
            printf -- '%s %s\n' "${hs}" 'Wait for unit test execution to finish' | tee -a "${logMainFile}"
            printf -- '%s\n' "${h1}" | tee -a "${logMainFile}"

            wait

            printf -- 'Unit tests finished running.\n' | tee -a "${logMainFile}"
        fi

    done

    ##
    ## Wait for unit test execution to finish if TEST parallelization type was requested
    ##
    if [[ "${parallelizationType}" == 'TEST' ]]; then
        printf -- '\n' | tee -a "${logMainFile}"
        printf -- '%s\n' "${h1}" | tee -a "${logMainFile}"
        printf -- '%s %s\n' "${hs}" 'Wait for unit test execution to finish' | tee -a "${logMainFile}"
        printf -- '%s\n' "${h1}" | tee -a "${logMainFile}"

        wait

        printf -- 'Unit tests finished running.\n' | tee -a "${logMainFile}"
    fi

    ##
    ## Cleanup liquibase error log files
    ##

    printf -- '\n' | tee -a "${logMainFile}"
    printf -- '%s\n' "${h1}" | tee -a "${logMainFile}"
    printf -- '%s %s\n' "${hs}" 'Cleanup liquibase error log files' | tee -a "${logMainFile}"
    printf -- '%s\n' "${h1}" | tee -a "${logMainFile}"

    find "${liquibaseTestsDirectory}" -iname 'sqlcl-lb-error*.log' -delete

    printf -- 'Completed.\n' | tee -a "${logMainFile}"

    ##
    ## Cleanup testing objects in database
    ##

    printf -- '\n' | tee -a "${logMainFile}"
    printf -- '%s\n' "${h1}" | tee -a "${logMainFile}"
    printf -- '%s %s\n' "${hs}" 'Cleanup unit test database objects' | tee -a "${logMainFile}"
    printf -- '%s\n' "${h1}" | tee -a "${logMainFile}"

    SQLPATH="" "${sqlclBinary}" "${sqlParamsDirectConnect[@]}" "${sqlParamsWithPassword[@]}" 1>>"${logMainFile}" 2>&1 <<- EOF
		declare
			c_unique_identifier constant    varchar2(255 char)  := upper('${scriptUniqueIdentifier}');
		begin
			for obj in (
				select table_name
				from user_tables
				where table_name like c_unique_identifier || '%'
			)
			loop
				execute immediate 'drop table ' || obj.table_name || ' cascade constraints purge';
			end loop;

			for obj in (
				select view_name
				from user_views
				where view_name like c_unique_identifier || '%'
			)
			loop
				execute immediate 'drop view ' || obj.view_name;
			end loop;
		end;
		/
		EOF

    printf -- 'Completed.\n' | tee -a "${logMainFile}"

    ##
    ## Gather unit test results
    ##

    printf -- '\n' | tee -a "${logMainFile}"
    printf -- '%s\n' "${h1}" | tee -a "${logMainFile}"
    printf -- '%s %s\n' "${hs}" 'Gather unit test results' | tee -a "${logMainFile}"
    printf -- '%s\n' "${h1}" | tee -a "${logMainFile}"

    for index in {1..4}; do
        if [[ "$index" -eq 1 ]]; then
            testType="${testTypeSqlclDirect}"
            testResultFile="${directTestResultFile}"
        elif [[ "$index" -eq 2 ]]; then
            testType="${testTypeSqlclLiquibaseCurrentDirectory}"
            testResultFile="${liquibaseCurrentDirectoryTestResultFile}"
        elif [[ "$index" -eq 3 ]]; then
            testType="${testTypeSqlclLiquibaseSearchPath}"
            testResultFile="${liquibaseSearchPathTestResultFile}"
        elif [[ "$index" -eq 4 ]]; then
            testType="${testTypeSqlclWrapped}"
            testResultFile="${wrappedTestResultFile}"
        fi

        while IFS= read -r readLine; do
            resultSeparatorCount="$(printf -- '%s' "${readLine}" | grep -o ':' | wc -l | xargs)"
            testName="$(printf '%s' "${readLine}" | cut -d ':' -f "1-${resultSeparatorCount}")"
            testResultCode="$(printf '%s' "${readLine}" | cut -d ':' -f "$((resultSeparatorCount+1))")"

            testResultPlainString="$(getTestResultPlainString "${testResultCode}")"
            testResultColorizedString="$(getTestResultColorizedString "${testResultCode}")"

            testTypes+=("${testType}")
            testNames+=("${testName}")
            testResultCodes+=("${testResultCode}")
            testResultPlainStrings+=("${testResultPlainString}")
            testResultColorizedStrings+=("${testResultColorizedString}")
        done < <( sort < "${testResultFile}" )
    done

    # Remove all working files
    rm -rf "${workingDirectory}"

    printf -- 'Finished gathering unit test results.\n' | tee -a "${logMainFile}"

    printf -- '\n' | tee -a "${logMainFile}"
    printf -- '%s\n' "${h1}" | tee -a "${logMainFile}"
    printf -- '%s %s\n' "${hs}" 'Unit test results' | tee -a "${logMainFile}"
    printf -- '%s\n' "${h1}" | tee -a "${logMainFile}"

    # Calculate longest test type length
    longestTestTypeLength=${#testTypeSummaryHeader}
    for testType in "${testTypes[@]}"; do
        if [[ ${#testType} -gt ${longestTestTypeLength} ]]; then
            longestTestTypeLength=${#testType}
        fi
    done

    # Calculate longest test name length
    longestTestNameLength=${#testNameSummaryHeader}
    for testName in "${testNames[@]}"; do
        if [[ ${#testName} -gt ${longestTestNameLength} ]]; then
            longestTestNameLength=${#testName}
        fi
    done

    longestTestResultLength=${#testResultSummaryHeader}
    for testResultPlainString in "${testResultPlainStrings[@]}"; do
        if [[ ${#testResultPlainString} -gt ${longestTestResultLength} ]]; then
            longestTestResultLength=${#testResultPlainString}
        fi
    done

    tableWidth=$((longestTestTypeLength + longestTestNameLength + longestTestResultLength + 9))

    tableFormat="| %-${longestTestTypeLength}s | %-${longestTestNameLength}s | %s\n"

    overallTestResultCode=0

    # Print out the results table
    function printResultsTableHeader() {
        printf -- "%0.s-" $(seq 1 "${tableWidth}") | tee -a "${logMainFile}"
        printf -- '\n' | tee -a "${logMainFile}"
        # shellcheck disable=2059
        printf -- \
            "${tableFormat}" \
            "${testTypeSummaryHeader}" \
            "${testNameSummaryHeader}" \
            "${testResultSummaryHeader}"  | tee -a "${logMainFile}"
        printf -- "%0.s-" $(seq 1 "${tableWidth}") | tee -a "${logMainFile}"
        printf -- '\n' | tee -a "${logMainFile}"
    } # printResultsTableHeader

    printf -- '\n' | tee -a "${logMainFile}"
    for index in "${!testNames[@]}"; do
        testType="${testTypes[${index}]}"
        testName="${testNames[${index}]}"
        testResultCode="${testResultCodes[${index}]}"
        testResultPlainString="${testResultPlainStrings[${index}]}"
        testResultColorizedString="${testResultColorizedStrings[${index}]}"

        if [[ "${testTypePrevious}" != "${testType}" ]]; then
            testTypePrevious="${testType}"
            printResultsTableHeader
        fi

        if [[ "${testResultCode}" -gt 0 ]]; then
            overallTestResultCode=1
        fi

        # shellcheck disable=2059
        printf -- \
            "${tableFormat}" \
            "${testType}" \
            "${testName}" \
            "${testResultColorizedString}"
        # shellcheck disable=2059
        printf -- \
            "${tableFormat}" \
            "${testType}" \
            "${testName}" \
            "${testResultPlainString}" >> "${logMainFile}"
    done
    printf -- "%0.s-" $(seq 1 ${tableWidth}) | tee -a "${logMainFile}"
    printf -- '\n' | tee -a "${logMainFile}"

    return "${overallTestResultCode}"
} # main

main "$@"
