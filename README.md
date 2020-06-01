# evidencer
Say you have script files in one directory, and lists of files with servernames in the other, and you want to combine those to run certain scripts on certain servergroups. Combine it with a remote execution tool like [Rundeer](https://github.com/FBnil/rundeer)/[ssh-batch](https://github.com/hans-vervaart/ssh-batch) or similar to produce results called "evidence".

## Usage
```
 evidencer [-s <suit>] [suit:][script]=[servergroup][@<hostnames_regexp,...>] [--help]
```
### OPTIONS

 | OPT | DESCRIPTION |
| ------ | ------ |
| --help       | Print Options and Arguments.|
| --man        |Print complete man page.|
| --verbose    |Log more to the screen|
| --DEBUG      |Log a bit more to the screen|
| --dryrun     |Do not execute, but show all that would have been run|
| --UTC        |timestrings are in UTC instead of localtime |
| --createdirs | Create directories if they do not exist |
| --config <cfg_file>| Read alternative cfg file|
| --keep       |Do not cleanup temporal files created to accomodate the @hostnames list|
| --noautofix  |Do not skip running tests on servergroups that match multiple tests|
| --unfold     |If you have files in your servergroups, recursively read the servers.|
| --fold       |Group by Scripts|
| --group      |Group by Servergroups|
| --SEPARATOR  |The separation characters between folded and group items. (default is double space)|
| --suit <suit> |search for scripts only from this suit|


## Directories

- `./servers/` Define a list of server by function.
- `./scripts/` Define a list of tests, by function, to be run on those servers
- `./results/` Just an empty directory to store results in (from an external program)
- `./suits/`   Once you are done with your tests, move them into a suit, still available, but tucked away
- `./temp/`    Directory used when you use `@hostnames_regexp`

## Example
Say you have the following servergroups (files that contain servernames/ipadresses on each line)
```sh
$ find servers/ -type f |sort
servers/APACHE-WEBSERVERS-ACCP
servers/APACHE-WEBSERVERS-PROD
servers/APACHE-WEBSERVERS-PROD-DMZ
servers/NGINX-WEBSERVERS-PROD-DMZ
```
You write scripts that target each one of them. For example, `test1=+` will match all the `APACHE-WEBSERVERS-*` servergroups
But `test2=APACHE-WEBSERVERS-ACCP` will only match the servergroup `APACHE-WEBSERVERS-ACCP`.
```sh
$ find scripts/ -type f |sort
scripts/header=
scripts/test1=APACHE-WEBSERVERS++
scripts/test2=APACHE-WEBSERVERS-ACCP
scripts/test2=APACHE-WEBSERVERS-PROD
scripts/test2=APACHE-WEBSERVERS-PROD-DMZ
scripts/test3=++WEBSERVERS++DMZ
```

Then you create `evidencer.cfg`, with the following content:
```sh
#SERVERS=servers
#Change the scripts directory name into tests
#SCRIPTS=tests
#RESULTS=results
#Because typing HTTP is much shorter!
ALIAS HTTPD=APACHE-WEBSERVERS
_LOGFILE=/tmp/rundeer.%{YEAR}.%{MONTH}.%{DAY}_%{HH}%{MM}.log
RUNSTART=echo "=====START====="
RUNFINISH=echo "=====END====="
RUNABORT=echo "=====FATAL ERROR====="
RUN_PRE=RUN_PRE=echo "%{PID} %{RUNSCRIPTSDIR} %{RUNSERVERSDIR}%{NEWLINE} %{RUNSUIT}  %{RUNSCRIPT}  %{RUNSERVER}"
RUN=./bin/rundeer -m ./%{SCRIPTS}/%{RUNSCRIPT} -f ./%{SERVERS}/%{RUNSERVER} >> %{_LOGFILE} |tee -a %{RUNRESULTSDIR}/%{RUNNAME}
#RUN_POST
```

Now, from the commandline, you can run:
```sh
./evidencer -v -d test2=
```
It will verbosely say what it would do (dryrun). In this case show the commands for each test2=* on all it's matching servergroups
```sh
./evidencer test2=+ACCP  or ./evidencer test2=HTTPD-ACCP  or ./evidencer test2=APACHE-WEBSERVERS-ACCP
```
This will run test2 only on the ACCP machines
```sh
./evidencer test2=+ACCP@host00[1..5]
```
This will run test2 only on the machines host001 to host005 machines but only if they are found in `./servers/*ACCP`
The `@hostnames` regexp's are not un-ALIAS-ed. Don't forget to escape or quote.
```sh
# ./evidencer test3
```
This will match `++WEBSERVERS++DMZ`, which is `*-WEBSERVERS-*-DMZ` thus matches: `NGINX-WEBSERVERS-PROD-DMZ` and `APACHE-WEBSERVERS-PROD-DMZ`
```sh
# ./evidencer =
```
Just run everything... from ./scripts/ on ./servers/

## SUITS
once you are done with the tests, or you have multiple tests, and do not want to overlap things, move your `./servers/*` and `./scripts/*` into a subdirectory
called `./suit/TEST_SUIT_NAME/servers/`  and `./suit/TEST_SUIT_NAME/scripts/`

To create a suits directory structure:
```sh
./evidencer -C -s TEST_SUIT_NAME
```
After moving your files you can run all tests from the `TEST_SUIT_NAME` like this:
```sh
# ./evidencer -s TEST_SUIT_NAME =
```

Optionally, you can add a `./suits/TEST_SUIT_NAME/evidencer.cfg` configuration file, and override settings only for that suit. Very handy for ALIAS entries to not polute other SUIT's.


### more examples

Say we want to run, from the suit `JAVATRANSACTIONS` the test `JAVASERVER-SERVICES=` for servers in the `JAVA-ET` servergroup that match the perl regexp `javaserver00[1..5]` or the substring `javaserver0100`
 ```sh
 ./evidencer JAVATRANSACTIONS:JAVASERVER-SERVICES=JAVA-ET@javaserver00[1..5],javaserver0100
 ```
 
 show (dryrun) what would run from the suit `JAVATRANSACTIONS` the test 
 `JAVASERVER-SERVICES=` for any matching servers AND the test `JAVASERVER-PORTS` for any of it's matching servers
 ```sh
 ./evidencer -s JAVATRANSACTIONS JAVASERVER-SERVICES=* JAVASERVER-PORTS -d
 ```

 `JAVASERVER-SERVICES=*` can be written as:
   `JAVASERVER-SERVICES=`  or as  `JAVASERVER-SERVICES=+`  or even as  `JAVASERVER-SERVICES`
 


## File naming

 For the servergroup search argument, and the scriptnames after the `=` (but not the servergroup filename itself), you can use a plus sign instead of an asterix, and these are the rules:
 + `+` expands to `*`
 + `++` expands to `*-*` unless sandwitched between words, and then it becomes `-*-`
 Here is a lookup table:
 ```
 +     ==>  *       ++    ==>  *-*     +-+-+ ==>  *-*-*
 +A    ==>  *A      A+    ==>  A*      ++B   ==>  *-B
 +-A   ==>  *-A     A-+   ==>  A-*     A++   ==>  A-*
 A++B  ==>  A-*-B   A-+B  ==>  A-*B    A+-B  ==>  A*-B
```
 So if you have a servergroup file called `APACHE-PROD-DMZ`, then `=++DMZ` would match that group. As would `=+DMZ` but with the danger that you match `ALL-TESTDMZ` because that matches `*DMZ`, but not `*-DMZ`.
 And `++PROD++`  would match `*-PROD-*`. These are glob expansions, which means it would match
 exactly what ls would match if you run:  `ls ./servers/*-PROD-*`
 So in this case, naming your test `dmztest4apache=APACHE++DMZ` (matches `APACHE-*-DMZ`), would match `APACHE-PROD-DMZ` better.
 
 Thus, a `./scripts/test1=` or `./scripts/test1=+` will match any servergroup.
 A `./scripts/test1=+ET`will match `*ET` (all servergroups ending with `ET`)
 A `./scripts/test1=++ET`will match `*-ET` (all servergroups ending with `-ET`)
 
 
### Scripts file naming
For scripts, you can use labels that are unique until the `=` divider. Then you can add a search string that matches potential servergroup files.
For example:
`QA_TEST-10=MARIADB++` 
This would mean that there is a test script called `QA_TEST-10`, which can be run on `MARIADB-*` servergroups, like `MARIADB-PROD-TEAM1`

You can run all QA_TEST's with: `./evidencer QA_TEST-*=`

#### example

Say you have a test (let's call it "test1"), and you have two files for that test, because the latter should run on the DMZ (so the test has to be scripted differently).
```
./scripts/test1=APACHE++      (matches APACHE-*)
./scripts/test1=APACHE++DMZ   (matches APACHE-*-DMZ)
```
And your servergroups are:
```
./servers/APACHE-PROD-DMZ
./servers/APACHE-PROD
./servers/APACHE-QA
```
Then `APACHE-QA` and `APACHE-PROD` can only run on `test1=APACHE++`, but `APACHE-PROD-DMZ` actually matches both `test1=APACHE++` and `APACHE++DMZ`.
In this case, because the string "APACHE++DMZ" is longer, it would run on `test1=APACHE++DMZ`, and will not run on `test1=APACHE++`
(if you still want to run it on both, use the `--noautofix` commandline parameter)
caveat: Unfortunately, it does not look inside servergroups to make the server lists inside it unique. You must take care of that yourself. (there is no recursive expansion)
 
## evidencer.cfg
The configuration file contains many variables you can set. You can also define your own (Just stick to what perl calls "word characters" letters, numbers and underscore)
| CFG Variable | What it does|
|----|---|
|TEMP| The directory where temporal files are created. Temporal files are needed when you use @hostnames_regexp, because we need a subset of servers from the content of the servergroup file. The default is a `./temp/` subdirectory where the evidencer script is located.
|SUITDIR|The directory where are the suit directories are in. The default is a `./suit/` subdirectory where the evidencer script is located.|
|SUIT|Defaults to `..` this way, you do not need to worry about having a suit directory, you'll have `./servers/` and `./scripts/`here in the same directory evidencer resides|
|SERVERS|If for some reason, you want the `./servers/` directory name to be different, you can override this name. The default is `SERVERS=servers`|
|SCRIPTS|If for some reason, you want the `./scripts/` directory name to be different, you can override this name. For example, to use ssh-batch. That program uses `inline` as the directory name. The default is `SCRIPTS=scripts`
|RESULTS|Just a directory where the results are to be kept. The default is `RESULTS=results`|
|ALIAS| You can define multiple aliases. The `suit` and the `script` in the commandline parameters are un-aliased. The `hostnames_regexp` is not. Example: `ALIAS ES=ELASTICSEARCH`|

### RUN variables
All variables that have to do with running found combinations of servers and scripts

| RUN Variable | What it does|
|----|---|
|PID|The process ID of the currently running evidencer use it as: `%{PID}`. Combine with `%{N}` for unique filenames|
|N|A number that increases just before you use the: `RUN_PRE`, `RUN` and `RUN_POST`. Use it like: `%{N}`|
|RUNSCRIPTSDIR|The directory where the scripts are located, basically: `%{SUITDIR}`/`%{SUIT}`/`%{SCRIPTS}`|
|RUNSERVERSDIR|The directory where the servergroups are located, basically: `%{SUITDIR}`/`%{SUIT}`/`%{SERVERS}`|
|RUNSUIT|The currently running suit|
|RUNSCRIPT|The name of the scripts file being processed|
|RUNSERVER|The name of the servers file being processed|
|RUNSCRIPTFQ|Fully Qualified name for the scripts file, basically: `%{RUNSCRIPTSDIR}`/`%{RUNSCRIPT}`|
|RUNSERVERFQ|Fully Qualified name for the servers file, basically: `%{RUNSERVERSDIR}`/`%{RUNSERVER}`|
|RUNNAME|The name of the scripts file being processed %{RUNSCRIPT}, but stripped of the `=` and everything to the right|
|RUN_PRE|Execute this string in the shell. Runs before `RUN`. Time date strings are set before RUN_PRE and are the same for RUN and RUN_POST even if they take time to execute.|
|RUN|Execute this string in the shell|
|RUN_POST|Execute this string in the shell. Runs after `RUN`|
|KEEP|Set to true(1) to keep temporal files created when @hostnames is used|
|RUN_START|Run just before the first `RUN_PRE` is ran. If no scripts+servers is matched, then this does not trigger either|
|RUN_FINISH|Runs at the very end of the evidencer script, only if `RUN_START` ran|
|RUN_BEGIN|This always runs at the beginning|
|RUN_END|This always runs at the end. It has access to a number `%{N}` if it is zero, nothing actually ran|
|ABORTMSG|The fatal errormessage will be available to `RUN_ABORT` to do something with it (for example:log it)|
|RUN_ABORT|Execute this string in the shell when a fatal error occurred: When evidencer could not read or create a file it needs to run|

### TIME related variables
These are supposed to be read-only because evidencer makes them available. Handy for using in RUN scripts to log to a file with a timedate stamp. Note that you can alias these, so if you like, create something like:
```
YMD=%{YEAR}-%{MONTH}-%{DAY}
YMDHM=%{YMD}_%{HH}%{MM}
```
Which you can use in your RUN definition and it expands to an ISO datestring but only just before running (before RUN_START, RUN_PRE (even when undefined) and RUN_FINISH):
```
RUN=./bin/ssh-batch %{RUNSERVERFQ} -- %{RUNSCRIPTSDIR}/HEADER.sh %{RUNSCRIPTFQ}|tee -a %{RUNRESULTSDIR}/%{RUNNAME}-%{YMD}.log
```
| TIME Variable | What it does|
|----|---|
|EPOCH|Time in epoch time (seconds sinds 1970)|
|HH|Time hour (00..23)|
|MM|Time minutes (00..59)|
|SS|Time seconds (00..23)|
|WD|Weekday 1=Monday ... 6=Saturday, 7=Sunday|
|YD|Yearday. Day of the year, in the range 001..365 (or 001..366 if leap year)|
|DAY|day of the month (01..)|
|MONTH|01=jan ... 12=dec|
|YEAR|4 digits year|
|DS|daylightsaving|
|TOTALTIME|Total seconds running the evidencer script|

The time is localtime by default, but it can be `UTC` if you define it like true-ish in your evidencer.cfg file:
`UTC=1`

### Test case run (RUN_PRE, RUN, RUN_POST)
These run for each test (a valid script and server combination). Everthing written will be executed by the shell. You can use `%{ }` variables to be expanded just before it runs.
RUN_PRE is the only one from this group that get's it's timedate variables updated, so you can re-use them in all the three (`RUN_PRE`, `RUN` and `RUN_POST`) and they will have the same values.

#### example
```
RUN=echo "I would run %{RUNSCRIPTFQ} on %{RUNSERVERFQ}"
```

### Global run (RUN_START, RUN_FINISH, RUN_ABORT)
These are executed only once, before the first script (`RUN_PRE`, `RUN` and `RUN_POST`) is run. And if there is no scripts + servers combination found that is to run, the `RUN_START` and `RUN_END` is not run. 
The `RUN_FINISH` runs after the last script has run.
When evidencer dies from a fatal erro `RUN_ABORT` is run. It also gets to use the variable `%{ABORTMSG}`, for example:
```
RUN_ABORT=echo "%{ABORTMSG}" >> /tmp/evidencer-crash.log
```

### Global run (RUN_BEGIN, RUN_END)

`RUN_BEGIN` runs at the beginning of ./evidencer (before `RUN_START`), `RUN_END` at the end, (after `RUN_FINISH`).

### FOLD and GROUP
Sometimes, you need to group the servers or the scripts to reduce the amount of calls you make to ssh. The separator used by default is "  " (two spaces), but you can override it by setting `--SEPARATOR` to another character(s).

To see what it would do with your scripts and servers, use `--dryrun` and `--verbose` in combination with `--fold` and `--group`. and grep on the word 'RUN'

```sh
./evidencer [-s TEST_SUIT_NAME] = -d -v [-f] [-g] |grep RUN
```
Note that the line starting with `# RUN(` removes the paths for readability, but `%{RUNSCRIPTFQ}` and `%{RUNSERVERFQ}` contain the paths for each.

Let's explain it visually. For this example, we have the following scripts and servers:
|scripts|
|----|
|test1=VM+|
|test2=VM-ET|
|test3=VM+|

|servers|
|----|
|VM-ET|
|VM-PR|

Normally, if we run `"="` (all scripts) this would iterate and run the following:
|run script|on servergroup|
|---|---|
|test1=VM+|VM-ET|
|test1=VM+|VM-PR|
|test2=VM-ET|VM-ET|
|test3=VM+|VM-ET|
|test3=VM+|VM-PR|

#### fold
Using `-f` or `--fold` would fold the scripts like so:

|run script|on servergroup|
|---|---|
|test1=VM+ test2=VM-ET test3=VM+|VM-ET|
|test1=VM+ test3=VM+|VM-PR|


#### group
Using `-g` or `--group` would group the servergroups like so:

|run script|on servergroup|
|---|---|
|test1=VM+|VM-ET VM-PR|
|test2=VM-ET|VM-ET|
|test3=VM+|VM-ET VM-PR|

#### group and fold
You can combine `--fold` and `--group` on the commandline, and that would RUN like so:

|run script|on servergroup|
|---|---|
|test1=VM+ test3=VM+|VM-ET VM-PR|
|test2=VM-ET |VM-ET|
