# evidencer
Combines test scripts to be run on servergroups. Combine it with a remote execution tool like [Rundeer](https://github.com/FBnil/rundeer)/[ssh-batch](https://github.com/hans-vervaart/ssh-batch) or similar to produce results called "evidence".

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
| --config $configuration_file| Read alternative cfg file|
| --keep       |Do not cleanup temporal files created to accomodate the @hostnames list|
| --suit <suit> |search for scripts only from this suit|


- `./servers/` Define a list of server by function.
- `./scripts/` Define a list of tests, by function, to be run on those servers
- `./results/` Just an empty directory to store results in (from an external program)
- `./suits/`   Once you are done with your tests, move them away into a suit, still available


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
# ./evidencer -v -d test2=
```
It will verbosely say what it would do (dryrun). In this case show the commands for each test2=* on all it's matching servergroups
```sh
# ./evidencer test2=+ACCP  or ./evidencer test2=HTTPD-ACCP  or ./evidencer test2=APACHE-WEBSERVERS-ACCP
```
This will run test2 only on the ACCP machines
```sh
# ./evidencer test2=+ACCP@host00[1..5]
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

 For the servergroup, you can use a plus sign instead of an asterix, and these are the rules:
 + `+` expands to `*`
 + `++` expands to `*-*` unless sandwitched between words, and then it becomes `-*-`
 Here is a lookup table:
 ```
 +     ==>  *       ++    ==>  *-*     +-+-+ ==>  *-*-*
 +A    ==>  *A      A+    ==>  A*      ++B   ==>  *-B
 +-A   ==>  *-A     A-+   ==>  A-*     A++   ==>  A-*
 A++B  ==>  A-*-B   A-+B  ==>  A-*B    A+-B  ==>  A*-B
```
 So if you have a servergroup called `APACHE-PROD-DMZ`, then `=++DMZ` would match that group.
 And `++PROD++`  would match `*-PROD-*`. These are glob expansions, which means it would match
 exactly what ls would match if you run:  `ls ./servers/*-PROD-*`
 
 Thus, a `./scripts/test1=` or `./scripts/test1=+` will match any servergroup.
 A `./scripts/test1=+ET`will match `*-ET` (all servergroups ending with `-ET`)
 
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
|RUN_START|Run just before the first `RUN_PRE` is ran|
|RUN_FINISH|Runs at the very end of the evidencer script|
|ABORTMSG|The fatal errormessage will be available to `RUN_ABORT` to do something with it (for example:log it)|
|RUN_ABORT|Execute this string in the shell|

### TIME related variables
These are supposed to be read-only because evidencer makes them available. Handy for using in RUN scripts to log to a file with a timedate stamp. Note that you can alias these, so if you like, create something like:
```
ALIAS YMD=%{YEAR}-%{MONTH}-%{DAY}`
```
Which you can use in your RUN definition and it expands to an ISO datestring:
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
|DAY|day of the month|
|MONTH|01=jan ... 12=dec|
|YEAR|4 digits year|
|DS|daylightsaving|
|TOTALTIME|Total seconds running the evidencer script|



### Test case run (RUN_PRE, RUN, RUN_POST)
These run for each test (a valid script and server combination). RUN_PRE is the only one from this group that get's it's timedate variables updated, so you can re-use them in all the three and they will have the same values.

### Global run (RUN_START, RUN_FINISH, RUN_ABORT)
These are executed only at the absolute start, end, and when evidencer dies from a fatal error.
RUN_ABORT also gets to use the variable `%{ABORTMSG}`, for example:
`RUN_ABORT=echo "%{ABORTMSG}" >> /tmp/evidencer-crash.log`



