# evidencer
Create test scripts to be run on servergroups. Combine it with a remote execution tool like [Rundeer](https://github.com/FBnil/rundeer)/[ssh-batch](https://github.com/hans-vervaart/ssh-batch) or similar to produce results called "evidence".

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

## File naming
yada (talk about glob and the + to *)
## evidencer.cfg
The configuration file contains many variables you can set.
yada

### Test case run (RUN_PRE, RUN, RUN_POST)
These run for each test (a valid script and server combination). RUN_PRE is the only one from this group that get's it's timedate variables updated, so you can re-use them in all the three and they will have the same values.

### Global run (RUN_START, RUN_FINISH, RUN_ABORT)
These are executed only at the absolute start, end, and when evidencer dies from a fatal error.




