# evidencer

<div align="right"><img align="right" src="extra/images/text5051.png" /><sub><sup>Grudge-2-BRK Font courtesy of Brian Kent</sup></sub></div>

Say you have script files in one directory, and lists of files with servernames in the other, and you want to combine those to run certain scripts on certain servergroups. By cleverly naming the scripts and the servergroup files, you restrict what can run where. Add a few filters to select which scripts, and on which servers you want to run these scripts and you get evidencer.
Combine it with a remote execution tool like [Rundeer](https://github.com/FBnil/rundeer)/[ssh-batch](https://github.com/hans-vervaart/ssh-batch) or similar to produce output (results) you can store on the machine you are running from. Store the output with timedate stamps, and the results become historical "evidence".

## Usage
```
 evidencer [-s <suit>] [suit:][script]=[servergroup][@<hostnames_regexp,...>] [--help]
```
### OPTIONS


| OPT | DESCRIPTION |
| ------ | ------ |
| `-h` \| `--help`       | Print Options and Arguments.|
| `--man`              |Print complete man page.|
|`--complete` | Prints the code to activate tab completion (also used in the internal completion) |
| `-v` \| `--verbose`    |Log more to the screen|
| `-D` \| `--DEBUG`      |Log a bit more to the screen|
| `-d` \| `--dryrun`     |Do not execute, but show all that would have been run|
| `-U` \| `--UTC`        |timestrings are in UTC instead of localtime |
| `-C` \| `--createdirs` | Create directories if they do not exist |
| `-c` \| `--config` `<cfg>`| Read alternative cfg file|
| `-k` \| `--keep`  |Do not cleanup temporal files created to accomodate the @hostnames list|
| `-n` \| `--noautofix` |Do not skip running scripts on servergroups that match multiple scripts|
| `-u` \| `--unfold` |If you have files in your servergroups, recursively read the servers.|
| `-f` \| `--fold` |Group by Scripts|
| `-g` \| `--group` |Group by Servergroups|
| `-b` \| `--bundle` |Concatenate all scripts/servers if they are folded or grouped|
| `-r` \| `--redefine` `<var=val>`|Override a variable from evidencer.cfg (can be used multiple times)|
| `-a` \| `--argument` `<arg>`|Quick redefine that sets `%{ARG}` for use in `RUN*_ARG` scripts (if defined) |
| `-q` \| `--quote`       |Quote all scripts and servers files|
| `-S` \| `--separator` `<str>` |The separation characters between folded and grouped items. (default is double space)|
| `-t` \| `--test` `<arg>` | Final test before a RUN_PRE, RUN and RUN_POST, to validate the combination. You will need RUN*_TEST defined. And if any of those exit with nonzero exitcode, running the rest is aborted.|
| `-s` \| `--suit` `<suit>` |search for scripts only from this suit. You can also use the environment variable SUIT|
| `-w` \| `--warnings` |Enable warnings when your script=server combination does not match anything. Set WARNINGS=1 in the configuration file to enable it by default|
| `-o` \| `--on` `<host>` |Comma separated list of hosts (will create a serverfile for you) for `=#` |
| `-l` \| `--loop` `<$>` |Loop on comma separated list of serverfiles for `=#` |
| `-Q` \| `--query` `<var>` |Prints the value of a variable defined in your evidencer.cfg and exits |
| `-V` \| `--version` | Prints the real file location and version and exits |
| `-e` \| `--export` | Name of the variables to export to processes using the `RUN*` |
| `-E` \| `--extra` | USR Modifier (string). Use inside your .cfg as: `"${EXTRA}"` |
| `-F` \| `--force` | USR Modifier (boolean). Use inside your .cfg as: `${FORCE}`. Pre set `FORCE=0` in cfg so you get a consistent number: `0` or `1` when set |

options can be anywhere in the commandline (but not after the `--` parameter). Options can be shortened (1st letter) and can be bundled.

## QUERY

Query allows you to query any variable defined in the evidencer.cfg (or any cfg if you preload it with `-c`)
You can also query ALIASes. Like many of the variables that accept multiple parameters, you can comma separate or issue multiple queries:

`./evidencer -Q TIME -r 'TIME="%{YEAR}-%{MONTH}-%{DAY} %{HH}:%{MM} %{WD}/7 %{YD}/365 %{WN}/52"'`

TIME="2021-07-17 23:56 6/7 198/365 29/52"


`./evidencer -Q SCRIPTS,/q -Q NOW`

NOW=${YEAR}-${MONTH}-${DAY}_${HH}:${MM}:${SS}

SCRIPTS=scripts

/q=&SILENCE=--quiet


Additionally, if you add a test, it will fill in the variables:

`./evidencer -s DEMO -Q RUN`

RUN=/home/FBnil/evidencer/bin/ssh-batch ${SILENCE} --no-info --bg-log-dir "%{RUNRESULTSDIR}/${RUNNAMES}" %{RUNSERVERFQ} -- %{RUNSCRIPTFQ} > "%{RUNRESULTSDIR}/${RUNNAMES}-2021-07-23_1143.log"

`./evidencer -s DEMO os.show.mem=# -Q RUN`

RUN=/home/FBnil/evidencer/bin/ssh-batch ${SILENCE} --no-info --bg-log-dir "/home/FBnil/evidencer/suits/DEMO/results/${RUNNAMES}" /home/FBnil/evidencer/suits/DEMO/servers/localhost -- /home/FBnil/evidencer/suits/DEMO/scripts/os.show.mem=+ > "/home/FBnil/evidencer/suits/DEMO/results/${RUNNAMES}-2021-07-23_1142.log"


## ON

By itself, the `#` means the newest ./servers/ file. But combined with a `--on`, then the meaning changes to: Create a new file with the default name `tmp.lst` (which name you can override by defining `TMPFILE`), put all servernames there, and (because it is now the latest file), run the script(s) on that serversfile.

`./evidencer test=\# -o host1,host2 -o host3`

## LOOP

The behavior is similar to `--on`, but the given parameters are serversfiles inside ./servers/

`./evidencer test=\# -l serverlist1,serverlist2 -o serverlist3`


## Directories

- `./servers/` Define a list of server by function.
- `./scripts/` Define a list of scripts, by function, to be run on those servers
- `./results/` Just an empty directory to store results in (from an external program)
- `./suits/`   Once you are done building your scripts, move them into a suit, still available, but tucked away
- `./temp/`    Directory used when you use `@hostnames_regexp` (and temporal files need to be created to filter and merge)

Tip: to create the top-level directories (except ./temp/ which you might want to redefine in a configuration first) use the following command:
`./evidencer -s .. -C` (or `./evidencer -Cs ..`)

If you have `SUIT_LINK=1` and/or `SUIT_CFG=1` in your configuration file, then evidencer will be symlinked into that directory and/or the evidencer.cfg file will be copied into the new suit.


## Example
Say you have the following servergroups (files that contain servernames/ipadresses on each line)
```sh
$ find servers/ -type f |sort
servers/APACHE-WEBSERVERS-ACCP
servers/APACHE-WEBSERVERS-PROD
servers/APACHE-WEBSERVERS-PROD-DMZ
servers/NGINX-WEBSERVERS-PROD-DMZ
```
You write scripts that target each one of them. For example, `test1=APACHE-WEBSERVERS++` will match all the `APACHE-WEBSERVERS-*` servergroups
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
RUN_START=echo "=====START====="
RUN_FINISH=echo "=====END====="
RUN_ABORT=echo "=====FATAL ERROR====="
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
This will run `test2` only on the machines host001 to host005 machines but only if they are found in `./servers/*ACCP`
The `@hostnames` regexp's are not un-ALIAS-ed. Don't forget to escape or quote.
```sh
./evidencer test2=HTTPD-ACCP@#1,#2
```
Run the `test2` only the first and second server from the `HTTPD-ACCP` list
```sh
./evidencer test3
```
This will match all test3 scripts, and because we only have one script `test3=++WEBSERVERS++DMZ`, it would match the servers that match `++WEBSERVERS++DMZ`, which is `*-WEBSERVERS-*-DMZ` thus matches: `NGINX-WEBSERVERS-PROD-DMZ` and `APACHE-WEBSERVERS-PROD-DMZ`
```sh
./evidencer =
```
Just run everything... from ./scripts/ on ./servers/

```sh
./evidencer @host001
```
Find all that is runnable for host001, and run it.

```sh
./evidencer test2@host001
```
Run `test2` on host001 (only if any test2=* matches a servergroup that contains that server)

### ALIAS

Aliases have 3 usages. The first is to help expanding shortcuts inside a `scripts=server` argument, on both sides of the `=`, as seen in the `ALIAS HTTPD=APACHE-WEBSERVERS` example above. 
The second is to expand a complete evidencing set. For example, with this cfg file:
```
ALIAS SetTestA=test1=VM-PR test2=VM-ET
```
We can run:
```
./evidencer SetTestA
```
and it will expand to:
```
./evidencer ..:test1=VM-PR ..:test2=VM-ET
```
(The `..` as suit means that it's not in a suit, but at the top level)
which would be the same as running it from the commandline:
```
./evidencer test1=VM-PR test2=VM-ET
```
Note: ALIASes are case sensitive. Consider using `%`, `~` or `/` as the first character of these type of aliases to prevent naming clashes.

And the third usage of `ALIAS` is for `--redefine`, which has it's own chapter on how to use it.

## SUITS
once you are done with the tests, or you have multiple tests, and do not want to overlap things, move your `./servers/*` and `./scripts/*` into a subdirectory
called `./suits/TEST_SUIT_NAME/servers/`  and `./suits/TEST_SUIT_NAME/scripts/`

To create a suits directory structure:
```sh
./evidencer -C -s TEST_SUIT_NAME
```
After moving your files you can run all tests from the `TEST_SUIT_NAME` like this:
```sh
./evidencer -s TEST_SUIT_NAME =
```

Optionally, you can add a `./suits/TEST_SUIT_NAME/evidencer.cfg` configuration file, and override settings only for that suit. Very handy for ALIAS entries to not polute other SUIT's.
And you can create a `./suits/TEST_SUIT_NAME/TEST_NAME.cfg` to even override parts of that configuration. It will not always be activated, to activate it, use this syntax:
```sh
./evidencer TEST_SUIT_NAME:TESTNAME=
./evidencer -s TEST_SUIT_NAME  TEST_SUIT_NAME:TESTNAME=  OTHER_TEST_IN_SAME_SUIT=
```
Because it will use the `./suits/TEST_SUIT_NAME/evidencer.cfg` or `/dir/otherconfig.cfg` you use:
```sh
./evidencer -s TEST_SUIT_NAME TESTNAME=
./evidencer -c /dir/otherconfig.cfg -s TEST_SUIT_NAME TESTNAME=
```

Instead of using the suit name, you can also change into your suit directory and there, create a symlink for the evidencer and run like so:

```sh
cd suits/TEST_SUIT_NAME
ln -s ../../evidencer
./evidencer TESTNAME=
```


### more examples

Say we want to run, from the suit `JAVATRANSACTIONS` the test `JAVASERVER-SERVICES=` for servers in the `JAVA-ET` servergroup that match the perl regexp `javaserver00[1..5]` or the substring `javaserver0100`
 ```sh
 ./evidencer JAVATRANSACTIONS:JAVASERVER-SERVICES=JAVA-ET@javaserver00[1..5],javaserver0100
 ```
 
 show (--dryrun) what would run from the suit `JAVATRANSACTIONS` the test (dryrun is not that useful without --verbose)
 `JAVASERVER-SERVICES=` for any matching servers AND the test `JAVASERVER-PORTS` for any of it's matching servers
 ```sh
 ./evidencer -s JAVATRANSACTIONS JAVASERVER-SERVICES=* JAVASERVER-PORTS -dv
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


Tip: the newest servergroup file in ./servers/ is aliased to #, so to run a script on all the server in that latest file:

./evidencer os.show.boottime=#

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
Then `APACHE-QA` and `APACHE-PROD` can only run on `test1=APACHE++`, but `APACHE-PROD-DMZ` actually matches both `test1=APACHE++` and `test1=APACHE++DMZ`.
In this case, because the string "APACHE++DMZ" is longer, it would run on `test1=APACHE++DMZ`, and will not run on `test1=APACHE++`
(if you still want to run it on both, use the `--noautofix` commandline parameter)
caveat: Unfortunately, it does not look inside servergroups to make the server lists inside it unique. You must take care of that yourself. (there is no recursive expansion)

## evidencer.cfg
The configuration file contains many variables you can set. You can also define your own (Just stick to what perl calls "word characters" letters, numbers and underscore)
| CFG Variable | What it does|
|----|---|
|BASEDIR| The directory where the `evidencer` binary is located|
|CFGDIR| Configuration directory Defaults to `cfg`. Can only be defined in the toplevel configuration file (not inside suits). Can place your cfg files in a subdirectory of the SUIT, if you prefer that.|
|TEMP| The directory where temporal files are created. Temporal files are needed when you use @hostnames_regexp, because we need a subset of servers from the content of the servergroup file. The default is a `./temp/` subdirectory where the evidencer script is located.
|SUITSDIR|The directory where are the suit directories are in. The default is a `./suits/` subdirectory where the evidencer script is located.|
|SUIT|Defaults to `..` this way, you do not need to worry about having a suit directory, you'll have `./servers/` and `./scripts/`here in the same directory evidencer resides|
|SERVERS|If for some reason, you want the `./servers/` directory name to be different, you can override this name. The default is `SERVERS=servers`|
|SCRIPTS|If for some reason, you want the `./scripts/` directory name to be different, you can override this name. For example, to use ssh-batch. That program uses `inline` as the directory name. The default is `SCRIPTS=scripts`
|RESULTS|Just a directory where the results are to be kept. The default is `RESULTS=results`|
|ALIAS| You can define multiple aliases. The `suit` and the `script` in the commandline parameters are un-aliased. The `hostnames_regexp` is not. Example: `ALIAS ES=ELASTICSEARCH`|

### Levels of evidencer.cfg
There are 3 levels of evidencer: In the top directory, next to evidencer itself you have evidencer.cfg. This is the master configuration. Then, if you have an evidencer.cfg inside a suit, and you are running tests in that suit, the master configuration becomes that file. And then, also inside the suit, if you have a .cfg with the exact testname, that configuration will be merged with one of the previous two.

so you can have:
| File | function it provides |
|----|---|
|`./evidencer`| |
|`./evidencer.cfg`| default toplevel configuration|
|`./suits/mysuit/evidencer.cfg`| if this exists, and you are using this suit, then this becomes the toplevel configuration|
|`./suits/mysuit/scripts/mytest=+`||
|`./suits/mysuit/mytest.cfg`| overrides the toplevel configuration with anything in this file, if it exists|

### RUN variables
All variables that have to do with running found combinations of servers and scripts

| RUN Variable | What it does|
|----|---|
|PID|The process ID of the currently running evidencer use it as: `%{PID}`. Combine with `%{N}` for unique filenames|
|ARGV|The script+server combination we are running|
|ARG|Contains the string with the argument(s) passed with `--` or a single argument passed with `-a`|
|N|A number that increases just before you use the: `RUN_PRE`, `RUN` and `RUN_POST`. Use it like: `%{N}`|
|RUNSCRIPTSDIR|The directory where the scripts are located, basically: `%{SUITSDIR}`/`%{SUIT}`/`%{SCRIPTS}`|
|RUNSERVERSDIR|The directory where the servergroups are located, basically: `%{SUITSDIR}`/`%{SUIT}`/`%{SERVERS}`|
|RUNSUIT|The currently running suit|
|RUNSCRIPT|The name of the scripts file being processed|
|RUNSERVER|The name of the servers file being processed|
|RUNSCRIPTFQ|Fully Qualified name for the scripts file, basically: `%{RUNSCRIPTSDIR}`/`%{RUNSCRIPT}`|
|RUNSERVERFQ|Fully Qualified name for the servers file, basically: `%{RUNSERVERSDIR}`/`%{RUNSERVER}`|
|RUNNAME|The name of the scripts file being processed %{RUNSCRIPT}, but stripped of the `=` and everything to the right|
|RUNNAMES|If you `--bundle` or `--fold` you might want to use the `+` concated scripts names, instead of `RUNNAME` which will contain only the last one|
|TEST|Argument string given with --test on the commandline (available as `%{TEST}`). It can be used in your `RUN_PRE_TEST` or `RUN_TEST` (and `RUN_POST_TEST`), which only activate when `--test` is used. If tests fail by returning a non-zero exitcode, everything halts|
|RUN_PRE_TEST|Execute this string in the shell to test the validity of the script+server combination. As with all `*_TEST`, Exit nonzero to skip execution of `RUN_PRE` and all after |
|RUN_PRE|Execute this string in the shell. Runs before `RUN`. Time date strings are set before `RUN_PRE` and are the same for `RUN` and `RUN_POST` even if they take time to execute. Exit nonzero to skip.|
|RUN_TEST|Execute this string in the shell to test the validity of the script+server combination. Exit nonzero to skip `RUN` (but `RUN_PRE` already ran if it was defined)|
|RUN|Execute this string in the shell|
|RUN_POST|Execute this string in the shell. Runs after `RUN`|
|KEEP|Set to true(1) to keep temporal files created when `@hostnames` is used, like so: `./evidencer -r KEEP=1 script=servers`|
|RUN_START|Run just before the first `RUN_PRE` is ran. If no scripts+servers is matched, then this does not trigger either|
|RUN_FINISH|Runs at the very end of the evidencer script, only if `RUN_START` ran|
|RUN_BEGIN|This always runs at the beginning|
|RUN_END|This always runs at the end. It has access to a number `%{N}` if it is zero, nothing actually ran|
|ABORTMSG|The fatal errormessage will be available to `RUN_ABORT` to do something with it (for example:log it)|
|RUN_ABORT|Execute this string in the shell when a fatal error occurred: When evidencer could not read or create a file it needs to run|

All `RUN*` commands have a `*_FAIL` counterpart. If the exitcode of the command is nonzero, then the `*_FAIL` will be run.
The `RUN_PRE` is a special case: when RUN_PRE returns with a nonzero exitcode, then `RUN_PRE_FAIL` will also run, but then the rest, like `RUN` and `RUN_POST` will be skipped. To override this, end your `RUN_PRE` command with `;true`.

If you use arguments (either by adding a single argument with `-a` or using `--` at the end of the parameters, and adding your parameter(s) after it; then, if you have defined:
`RUN_PRE_TEST_ARG`, `RUN_PRE_ARG`, `RUN_TEST_ARG`, `RUN_ARG`, `RUN_POST_TEST_ARG`, `RUN_POST_ARG` Then those commands will be used instead. In both cases, `%{ARG}` will be available to be used. 

So the order is: RUN_BEGIN, RUN_START, RUN_PRE_TEST, RUN_PRE, RUN_TEST, RUN, RUN_POST_TEST, RUN_POST, RUN_FINISH,  RUN_END. and a *_FAIL for each of these and a RUN_ABORT when file IO fails.


#### example

```sh
RUN_PRE=ls /tmp/fobaar ; true
RUN_PRE_FAIL=echo "I will never run because RUN_PRE returns always zero/true"
RUN=%{BASEDIR}/bin/ssh-batch %{RUNSERVERFQ} -- %{RUNSCRIPTFQ} > %{RUNRESULTSDIR}/%{RUNNAME}.log
RUN_FAIL=echo "B0RKEN %{RUNNAME} %{ERRORCODE}" >> %{RUNRESULTSDIR}/%{RUNNAME}.err
RUN_POST=ls /tmp/pqowieur | tee -a /tmp/log.log ; . ./bin/ec.1
RUN_POST_FAIL=echo "I will run if the file /tmp/pqowieur does not exist"
```
Interesting case is the one presented with `RUN_POST`. The tee is handy, because you get output while it runs, however, it always returns true if itself is able to store/append to the logfile. It does not propagate the error from the previous command. To do this, we use `test ${PIPESTATUS[0]} -eq 0`, however, evidencer interpolates `${}` as a variable, so you need to wrap it in a script, and then source it.

The content of `./bin/ec.1` is:
```
test ${PIPESTATUS[0]} -eq 0

```
##### Read more about pipes
https://unix.stackexchange.com/questions/14270/get-exit-status-of-process-thats-piped-to-another

### TIME related variables
These are supposed to be read-only because evidencer makes them available. Handy for using in RUN scripts to log to a file with a timedate stamp. Note that you can alias these, so inside evidencer.cfg, add something like:
```
YMD=%{YEAR}-%{MONTH}-%{DAY}
YMDHM=%{YMD}_%{HH}%{MM}
```
Which you can use in your RUN definition and it expands to an ISO datestring but only just before running (before RUN_START, RUN_PRE (even when undefined) and RUN_FINISH):
```
RUN=%{BASEDIR}/bin/ssh-batch %{RUNSERVERFQ} -- %{RUNSCRIPTSDIR}/HEADER.sh %{RUNSCRIPTFQ}|tee -a %{RUNRESULTSDIR}/%{RUNNAME}-%{YMD}.log
```
| TIME Variable | What it does|
|----|---|
|EPOCH|Time in epoch time (seconds sinds 1970)|
|HH|Time hour (00..23)|
|MM|Time minutes (00..59)|
|SS|Time seconds (00..23)|
|WD|Weekday 1=Monday ... 6=Saturday, 7=Sunday|
|YD|Yearday. Day of the year, in the range 001..365 (or 001..366 if leap year)|
|WN|WeekNumber. Week of the year, in the range 01..52 (or 01..53 on some years)|
|DAY|day of the month (01..31)|
|MONTH|01=jan ... 12=dec|
|YEAR|4 digits year|
|DS|daylightsaving|
|TOTALTIME|Total seconds running the evidencer script|

The time is localtime by default, but it can be `UTC` if you define it like true-ish in your evidencer.cfg file:
`UTC=1` you can also use the `--UTC` commandline parameter

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

### UNFOLD

Sometimes, the servergroup files may contain nested files to other servergroups. If needed, then using this option, will detect such files and un-nest them to a temporal file. And this temporal file is used.
Sometimes, the servergroups contain not only the servername/ipaddress on a line, but a space and some comment, or alias (you can @grep on). by using UNFOLD, it will also reduce the lines to only the hostname/ipaddress and use a temporal file.


### FOLD and GROUP
Sometimes, you need to group the servers or the scripts to reduce the amount of calls you make to ssh. The separator used by default is "  " (two spaces), but you can override it by setting `--SEPARATOR` or the shorter `-S` to another character(s). You can also set it in the configuration file as `SEPARATOR=,`
Caveat: If you use this functionality, please stick to a single suit (you can address multiple scripts/servers in the commandline, as long as their directories are the same).

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

### BUNDLE
Now you have bundled or folded and will run less `RUN=` commands, but you still have the same amount of files to process. You can additionally `--bundle` (`-b`) these into a single file. Bundling will only be done if there are multiple files.


### REDEFINE

If you have an evidencer.cfg that looks like this:
```sh
ALIAS PARALLEL=RUN=%{PARALLEL_RUN}
PARALLEL_RUN=%{BASEDIR}/bin/ssh-batch --bg-log-dir %{RUNRESULTSDIR} %{RUNSERVERFQ} -- %{RUNSCRIPTFQ} > %{RUNRESULTSDIR}/%{RUNNAME}-parallel.log
RUN=%{BASEDIR}/bin/ssh-batch %{RUNSERVERFQ} -- %{RUNSCRIPTFQ} > %{RUNRESULTSDIR}/%{RUNNAME}.log
```

We can replace the `RUN` variable with another value:
```./evidencer test1 -r 'RUN=%{PARALLEL_RUN}'```
or we can make use of an ALIAS to do the same:
```./evidencer test1 -r PARALLEL```

and the normal RUN parameter will be replaced by the parallel form of `ssh-batch`.
While only using aliases (no `=` sign in the `-r`), you can use a comma to add more expressions.

Keep it mind to not clash with substrings with boundaries in your script names. So do not create a script called `PARALLEL=+`, nor `PARALLEL-CHECK=+`, but `parallel=+` and `PARALLELS=+` are ok.

For anything more complex, consider using a separate configuration file and calling it with `--config` (or the shorter `-c`)

You can also disable/enable settings, for example if folding is enabled in the CFG `FOLD=1`, then you can disabled it from the commandline:
```
./evidencer -r FOLD=0 ...
```



### QUOTE
If you have a path with spaces, it is useful to quote them before using them, to do this, use `--quote` The default is a single quote. You can override this by setting `QUOTESTR`. Note that setting the `QUOTESTR` by itself will not automatically enabled quoting. 
You can override it in the CFG:
```
QUOTESTR='
```
or through the commandline:
```
./evidencer -q -r QUOTESTR="'" ...
```

To permanently activate quoting, use the CFG:
```
QUOTE=1
```
Or set to zero if you do not want quoting (the default, but it could be enabled if you inherit the setting).

## I don't like perl

We have a script: evidencer.sh that does the basics, and might be just enough. Create a subdirectory `scripts` and a subdirectory `servers`:

```sh
cfg=evidencer.cfg
if [ -r "$cfg" ];then
	source "$cfg"
fi
SCRIPT=$1
IFS='=' read -ra ARR <<< "$SCRIPT"
SERVERGROUP=$(echo "${ARR[1]}"|sed 's/++/*-*/g'|tr '+' '*')
echo "# ($SCRIPT) -> ${ARR[0]}=$SERVERGROUP "
ls ./scripts/${ARR[0]}=$SERVERGROUP | while read script;do
    IFS='=' read -ra ARR <<< "$script"
    SERVERGROUP=$(echo "${ARR[1]}"|sed 's/++/*-*/g'|tr '+' '*')
    echo "# ($SCRIPT)->$script ($SERVERGROUP) "
    ls ./servers/$SERVERGROUP | while read servers;do
        echo "#ACTION: run $script on $servers"
    done
done
```
make sure to test it out, and then modify the line with `#ACTION` to run what you need.

### usage example
```
./evidencer.sh test*=++ET
./evidencer.sh *=*
```

## Parameter completion (TAB EXPANSION)
Evidencer has rudimentary tab-completion:
Add the following into your bashrc script and source it, or open a new terminal:
```
function _getopt_complete () {
 COMPREPLY=($( COMP_CWORD=$COMP_CWORD perl `which ${COMP_WORDS[0]}` --complete ${COMP_WORDS[@]:0} ));
}
complete -F _getopt_complete evidencer
```

you can also run the following:

`./evidencer --complete >> ~/.bashrc`

If you do not want to change your .bashrc, then run this to get tab expansion in your current terminal:

`eval $(./evidencer --complete)`

Sometimes expansion does not work, check that there is no other expansion for the binary defined:

`complete |grep evidencer` and delete it with `complete -r evidencer` then try again.

tip: Make sure your ./scripts/ are executable (chmod +x) and have a '=' sign in their name.

Tab-completion starts from the beginning of each ./scripts/ file, if you know what you are looking for, append a `+`, and it will match the expression at any position. So if you have `get.the.spoon=+` then `spo+` finds the spoon with tab, and if it's the only suggestion, then that is expanded in one go. The `+` also works as an AND. So if you have found multiple scripts, add some other subtring that distinctly defines the test that you want after `+`, then press tab again. So if you have `get.a.spoon=+` and `os.show.boottime=+`, then `oo+` would find them both, and `oo+b` would only find the latter, and expand to that full script name. When you add an equal sign, then it starts searching for serversfiles that match your expression before the equals sign. So `+1=` would match servers for `TEST1=`

If you run `justinstallademo.sh`, it will create a small suit called DEMO and fill the toplevel with some test script. You can play with test1, which matches only 1 serversscript, test2, which matches 2 and test3 which matches all three.

You can also let evidencer expand things, for example: This expands to test3=VM-PR-DMZ

./evidencer t+=+Z -dv |grep -e SCRIPT= -e SERVER=

and this expands to: test1=VM-ET test2=VM-ET test3=VM-ET

./evidencer t+=++ET -dv |grep -e SCRIPT= -e SERVER=


Note: Tab Expansion is still a bit wonky here and there. (for example, if you go back to left with the cursor, or if you used parameters)

## Build in Help

You can add help comments in all scripts in ./scripts/, then, when you have a substring of a script, you can use `-h` to show only the help. Use `-hv` for extended help. To acomplish this you need to have lines that start with `#:` and the extended help lines need to start with `#+:`
To show all help available, use a dot: `./evidencer . -hv` 
(you can switch the order of the parameters). Note that you NEED to add any expression (like a dot) or it will default to the internal usage help.

If you do not want colors, use NOCOLORS, like so:

`./evidencer . -hv -r NOCOLORS=2`

You can put this variable also in your evidencer.cfg file:

`# NOCOLORS=`     # default. Display help with colors

`NOCOLORS=1`    # Only headers are bold, the rest is monochromatic

`NOCOLORS=2`    # fully monochromatic, useful for storing in a text file.

### SCRIPTS HELP

You can look up also only one script's help, for example, if we have `get.a.spoon=+`, we can get it's help using a substring that matches its name, for example:
`./evidencer spoon -hv`

If you are making your own help text inside scripts, then you can add colors with `<C>`, 
where C is a character, or a number. The available characters are viewable with:
`grep C: evidencer |grep 033 |grep =`

#### You can use the following text accents
|code|color/effect|
|---|---|
| `<B>` | BOLD |
| `<I>` | ITALIC |
| `<N>` | Normal |
| `<U>` | UNDERLINE |
| `<R>` | RED |
| `<G>` | GREEN |
| `<Y>` | YELLOW |
| `<L>` | BLUE |
| `<P>` | PURPLE |
| `<C>` | CYAN |
| `<Z>` | INVERT |
| `<A>` | GRAY |
| `<O>` | ORANGE|
| `<165>` | Magenta2 |
| `<140>` | MediumPurple2 |
| `<99>`  | SlateBlue1 |
| `<236>` | Grey19 |
| `<070>` | Chartreuse3 |

Look up colorscodes by name on the web: https://jonasjacek.github.io/colors/

Look up colorcodes on the terminal https://www.perturb.org/code/term-colors.pl

To mark multiple words in a span, use a colon, like so: `<B:>`with the end tag `<:>`

for background colors use `<n.>` and end with `<:>` (where n is a number)

The featured colors are high intensity, for low intensity use `<1>`..`<8>`

Additionally to the extended help `#+:`, there is also `#=:`  It means it starts a new paragraph (adds a newline above).
And `#!:`  It means the line is separated by a newline above and below.

Note that <0> is not a color but the name of the script for which the help is being shown. And that <.> is the evidencer executable name. This way you can write a usage example that stays current, even if you happen to change your script's name, or renamed evidencer to something else.

`#+: <Y>Example: <L:> ./<.> <0>=# <:>`



Note: `ssh-batch` skips all comments, so you are not increasing IO by adding good documentation.


## Focus on one suit
You can go into a suit, pull evidencer your way by using a symlink, and symlink that suit directory to your home for quick access, like so:
```
cd suits/mysuit
ln -s ../../evidencer
ln -s `pwd` ~/quick
cd ~/quick
./evidencer
```
Tip: When working from within a suit, you do not need to add the "-s suit" or mention the "suit:", it is implied.

Tip: the newest file in `./servers/` is aliased to `#`, so to run a script on all the server in that latest file:

`./evidencer os.show.boottime=#`

## EXPORT

You can keep your configuration clean by instead of running bash code directly, you isolate it into a script;
and pass the variables required through the `EXPORT` variable, like so:

`EXPORT=BASEDIR,SILENCE,OUTPUTDIR,RUNSERVERFQ,RUNSCRIPTFQ,OUTPUTLOG`
`RUN=%{RUNSCRIPTSDIR}/run.sh`

This means that `run.sh` can now use `$OUTPUTDIR` directly, without having to pass as a commandline parameter.

You can also use a regexp:  `EXPORT=/RUN/` will export all variables that contain "RUN" in their name.

From the commandline it looks like this:

`./evidencer script=serversfile -e /RUN/,BASEDIR`

Note that `-e` always ADDs to the existing `EXPORT` defined in the cfg. To replace it use `-r EXPORT=BASEDIR,/RUN/`

TIP: While debugging you can export all variables if you use `-e /./`

TIP: You can use `EXPORT=` or `-e` multiple times.
