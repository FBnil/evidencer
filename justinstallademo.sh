if true;then
if [ ! -f evidencer ];then
	echo "You are not in a directory with evidencer, please run this script from there"
	exit 1
fi

if [ ! -x evidencer ];then
	chmod +x evidencer
fi

echo "Downloading ssh-batch and deploying it to ~/bin"


# Although smaller, we don't have "head" and could potentially miss important updates
#[ ! -f ssh-batch.tgz ] && wget -O ssh-batch.tgz https://github.com/FBnil/ssh-batch/releases/download/v1.0/ssh-batch-v1.0.tar.gz
#mkdir bin 2>/dev/null
#tar xvf ./ssh-batch.tgz --strip-components=1 -C bin

[ ! -f ssh-batch.zip ] && wget -O ssh-batch.zip https://github.com/FBnil/ssh-batch/archive/refs/heads/master.zip
unzip -j ssh-batch.zip -d bin



MERGE=false
if [ -d ~/bin ];then
	echo "You already have a ~/bin/ directory, may I add some ssh-batch files to it? (y/n)"
	read ANS
	if [ x"$ANS" = x"y" ];then
		MERGE=true
	fi
else
	mkdir ~/bin 2>/dev/null
fi

$MERGE && install bin/* ~/bin || chmod +x bin/*


if [ ! -f ~/.ssh/askpass.vault ];then
	echo "Setting up a ssh-batch vault"
	echo "You will need to type in your password twice (once for $USER, and once for default, then"
	echo "Twice your vault password. Use dummy values if you do not have remote servers to test to."
	echo "although ssh'ing to server 127.0.0.1 works"
	~/bin/ssh_askpass --vault-create $USER ""
else
	echo "You already seem to have an ~/.ssh/askpass.vault . Skipping creation."
fi

echo "Setting up commandline completion for evidencer"

BASHRC=~/.bashrc
#if [ -f ~/.bash_aliases ];then
#	BASHRC=~/.bash_aliases
#fi

grep -q completion_for_evidencer $BASHRC

if [ $? = 0 ];then
	echo "You already have tab completion in your $BASHRC . Skipping."
else

cat << 'EOF' >> $BASHRC

if [[ "${-}" =~ 'i' ]];then

# completion_for_evidencer
function _getopt_complete () {
  COMPREPLY=($( COMP_CWORD=$COMP_CWORD perl `which ${COMP_WORDS[0]}` --complete ${COMP_WORDS[@]:0} ));
}
complete -F _getopt_complete evidencer

fi

EOF

echo "Your file $BASHRC has been updated."
echo "Please type this to enable autocompletion now:"
echo " source $BASHRC "
echo
echo "Or open a new terminal"

fi



# Create the toplevel structure where we are going to store some scripts
./evidencer -C -s ..


# Create a suit structure
./evidencer -C -s DEMO

cd suits/DEMO
./evidencer -C -s ..

# make the demo NOT run on systems, just echo things
perl -pi -e 's/^RUN=\K.*/echo "FAKE-RUN %{RUNSCRIPT} on %{RUNSERVER}"/' evidencer.cfg
perl -pi -e 's/^RUN_POST=\K.*/echo "results for:";cat \$RUNSERVERFQ/' evidencer.cfg


# Read the configuration's settings for the subdirectories we just created
eval $(./evidencer -Q SCRIPTS,SERVERS,RESULTS,CFGDIR)




for t in test1 test2 test3 ;do
	echo -e "echo '${e}=VM-ET'\n" > $SCRIPTS/${t}=VM-ET
	if [ $t != "test1" ];then
		echo -e "echo '${e}=VM-PR'\n" > $SCRIPTS/${t}=VM-PR
		[ $t = "test3" ] && echo -e "echo '${e}=VM+ doing a du - \$HOME'\ndu -h $HOME" > $SCRIPTS/${t}=VM+
		[ $t = "test3" ] && echo -e "echo '${e}=VM-PR-DMZ'\n" > $SCRIPTS/${t}=VM-PR-DMZ
	fi
done

fi

for t in a.spoon a.fork the.knife ;do
	s=$SCRIPTS/get.${t}=+
	echo -e "#!/usr/bin/bash'\n" > $s
	echo -e "# A normal comment (will not be shown but it will be word-searched)\n" > $s
	echo -e "echo 'I am getting ${t}. You are running: ${s}'\n" > $s
	echo -e "#: This script fetches $(echo ${t}|tr '.' ' ') from the <B>cupboard. \n" >> $s
	echo -e "#: <R>Warning: You might need to replenish your cupboard when empty.\n" >> $s
	echo -e "#+: <Y>Usage: <L>./evidencer <L><0>=# \n" >> $s
	echo -e "#+:\n" >> $s
	echo -e "#+: You can use the following text accents:\n" >> $s
	echo -e "#+: <B><B>BOLD <I><I>ITALIC <N><N>Normal <U><U>UNDERLINE <R><R>RED <G><G>GREEN <Y><Y>YELLOW\n" >> $s
	echo -e "#+: <L><L>BLUE <P><P>PURPLE <C><C>CYAN <Z><Z>INVERT <A><A>GRAY <O><O>ORANGE\n" >> $s
	echo -e "#+: You can also use numerical values:\n" >> $s
	echo -e "#+: <165><165>Magenta2 <140><140>MediumPurple2 <99><99>SlateBlue1 <236><236>Grey19 <070><070>Chartreuse3\n" >> $s
	echo -e "#=: Look up colorscodes by name on the web:\n" >> $s
	echo -e "#+: <Y>URL: https://jonasjacek.github.io/colors/\n" >> $s
	echo -e "#=: Look up colorcodes on the terminal:\n" >> $s
	echo -e "#+: <Y>URL: <77:>https://www.perturb.org/code/term-colors.pl<:>\n" >> $s
	echo -e "#=: To mark long use < B: > <B:>with the end tag <:> < : >" >> $s
	echo -e "#+: All while leaving normal <xml> ... </xml> tags intact." >> $s
	echo -e "#=: <4.>Blue Background<:> <11.><K:>Black on Yellow<:> <1.><Y>Yellow_on_red (one word <286.><G:><I>only<:>)" >> $s

	# Creating specialized POST configuration for dummy demo (slightly different, just as an example)
	cat << 'EOF' > $CFGDIR/get.$t.cfg
RUN=echo "FAKE-RUN './%{SCRIPTS}/%{RUNSCRIPT}' on './%{SERVERS}/%{RUNSERVER}' into './%{RESULTS}/%{RUNNAMES}/' all output to './%{RESULTS}/%{RUNNAMES}.log'" ; echo "grabbing $( echo '%{RUNNAMES}'|tr '.' ' '|sed 's/get //')"
RUN_POST=echo "showing results for:"; cat $RUNSERVERFQ
EOF

done

cat << 'EOF' > $SCRIPTS/header=+
### SERVER=`hostname` DATE=`date +%Y-%m-%d_%H:%M` TEST=__TEST__ ###
EOF

chmod +x $SCRIPTS/*


# Now create servers
# so you can do: ./evidencer script=server@frontend to only select frontends

for t in VM-PR VM-PR-DMZ ;do
	echo -e "server1\nserver2\nserver3" > $SERVERS/${t}
done
echo -e "127.0.0.1" > $SERVERS/localhost

echo "server1 frontend server 2" > $SERVERS/VM-ET
echo "server2 backend server 1" >> $SERVERS/VM-ET
echo "server3 backend server 2" >> $SERVERS/VM-ET
echo "server4 frontend server 1" >> $SERVERS/VM-ET


cd -

echo "Back in $(pwd), creating localhost serverfile"
echo -e "127.0.0.1" > $SERVERS/localhost


# We create the POST binary (script that parses the produced data)
if [ -f "$SCRIPTS/POST" ];then
	echo "You already have POST in your $SCRIPTS . Skipping."
else
cat << 'EOF' >> "$SCRIPTS/POST"

OUTPUTLOG=$1
RUNSERVERFQ=$2
OUTPUTDIR=$3
# for each server line in $RUNSERVERFQ we strip out the comments and
# remove the user. Now we have a pure hostname (long or short), which 
# has output in $OUTPUTDIR
for svr in $(cat $RUNSERVERFQ|awk '{print $1}'|sed -e 's/:.*\|.*\^\|.*@//g');do
	sed -e "s/^/$svr:/" $OUTPUTDIR/$svr |grep -v -e '<ssh_askpass>' 
done

EOF

chmod +x "$SCRIPTS/POST"
fi


echo "Extracting ./$SCRIPTS/os.show.boottime=+"
cat << 'EOF' > ./$SCRIPTS/os.show.boottime=+
#!/usr/bin/env bash
ARG=$1

_TZ=UTC
if [ -z "$ARG" ];then
	ARG=$_TZ
else
	_TZ=$ARG
	# A selection of deprecated zone aliases, we translate these to current TZ syntax
	ZoneAlias=("CET" "Europe/Paris" "IST" "Asia/Kolkata" "EST" "America/Cancun" "EST5EDT" "America/New_York" "PRC" "Asia/Shanghai" "ROC" "Asia/Taipei" "ROK"  "Asia/Seoul")
	size=${#ZoneAlias[@]}
	for ((i=0; i < size; i++,i++)); do
		[ "$ARG" == "${ZoneAlias[$i]}" ] && _TZ="${ZoneAlias[$i+1]}"
	done
fi

# This is a normal comment. This will not be displayed in the help.
# When transmitting scripts through ssh-batch, all comments are skipped, so you do not waste bandwidth.

# Print out the Linux reported timezone
CTZ=$(TZ=${_TZ} date +%Z)
# Here we try a who -b, but if you have an older Linux, the -b option does not exist. In that case
# Try uptime -s
echo $((TZ=${_TZ} who -b||TZ=${_TZ} uptime -s) | sed -e 's/^[[:space:]]*//') $CTZ

# Help can be added in any position of the script. In this case, I put it almost at the end.

#: Show the Linux boot time in the selected timezone.
#: The default TimeZone is <B>UTC, which you can change with a <B>parameter.
#+: you can select from the following deprecated timezones:
#+: <B>CET <B>IST <B>EST <B>EST5EDT <B>PRC <B>ROC <B>ROK
#+: Note: During CEST, CET will mean CEST.
#+: <Y>Example: <L>./evidencer <L>os.show.boottime=# <L>-- <L>CET
#+: <Y>Example: <L>./evidencer <L>os.show.boottime=# <L>-- <L>Europe/Lisbon
#+: <C>See: <A>https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
#+: So instead of <B>WET you need to use <B>Europe/Lisbon (although WET still works)

# Throw in a bit of reboot history, for good measure:
TZ=$_TZ last reboot |head -4


EOF

echo "Extracting ./$SCRIPTS/os.show.mem=+"
cat << 'EOF' > ./$SCRIPTS/os.show.mem=+
#!/usr/bin/env bash

cd /sys/devices/system && echo $(( $(grep -x online memory/memory[0-9]*/state|wc -l) * 0x$(cat memory/block_size_bytes) / 1024**3 ))"G" || /usr/bin/lsmem |grep 'Total online memory' |awk '{print $4}'

#: Shows the amount of <B>RAM a machine has.
#+: 
#+: The difficulty in getting the RAM is because /proc/meminfo reports the total memory 
#+: AFTER the kernel memory has been substracted (around 300KB). So it might seem like 
#+: these work, but they are wonky:
#=: <L:>echo $((($(awk '/MemTotal/ {print $2}' /proc/meminfo)+350000)/1024/1024))<:>
#!: <Y>source: <A>https://toroid.org/linux-physical-memory

EOF


echo "Extracting ./$SCRIPTS/os.show.cpu=+"
cat << 'EOF' > ./$SCRIPTS/os.show.cpu=+
#!/usr/bin/env bash

lscpu | grep -e "^CPU(s):" | cut -f2 -d: | awk '{print $1}'
#: Display the number of CPU's a (virtual)machine has.

EOF

echo "Extracting ./$SCRIPTS/os.show.free=+"
cat << 'EOF' > ./$SCRIPTS/os.show.free=+
#!/usr/bin/env bash
ARG=$1

if [ -z "$ARG" ];then
        free -h
else
        free $@
fi

#: Show the Linux Memory Usage.
#: The default is <B>-h, Human readable format, which you can change with a parameter.
#=: See the manual for <B>free for all the options. Some options are:
#+: <B>-b<:>, <B>--bytes Display the amount of memory in bytes.
#+: <B>-k<:>, <B>--kibi  Display the amount of memory in kibibytes. (official default)
#+: <B>-g<:>, <B>--gibi  Display the amount of memory in gibibytes.
#+: <B>--giga      Display the amount of memory in gigabytes.
#=: <Y>Example: <L:>./evidencer <0> -- -b<:>
#=: <Y>Example: <L:>./evidencer <0> -- -k -w<:>

EOF


echo "Extracting ./$SCRIPTS/os.show.uptime=+"
cat << 'EOF' > ./$SCRIPTS/os.show.uptime=+
#!/usr/bin/env bash
uptime $@

#: Show the Linux uptime.
#=: <Y>Example: <L:>./evidencer <0> -- -p<:>
#=: Shows only the update in human readable format.

EOF



echo "Extracting ./$SCRIPTS/PRE^filter"
cat << 'EOF' > ./$SCRIPTS/PRE^filter
OUTPUTDIR=$1
shift
SERVER="$@"

# This is a NOT filter.
# Return false (nonzero) if the results file already exists, and true (zero) if not
# This way, you can go to your ./results/script/ directory where there are output files, one for each server
# And delete the ones that are old/corrupt; then rerun evidencer to only pick up the servers that have no result yet.
# To use it, you need to:
# 1: use -x in the commandline
# 2: Have the filter defined in the configuration file, for example:
#
# FILTER_PROCESS_SCRIPT=%{RUNSCRIPTSDIR}/%{RUNNAME}^filter
# FILTER_PROCESS=%{RUNSCRIPTSDIR}/PRE^filter
# RUN_FILTER=if [ -x %{FILTER_PROCESS_SCRIPT} ];then %{FILTER_PROCESS_SCRIPT} "${SERVER}" ; else %{FILTER_PROCESS} "%{OUTPUTDIR}" "${SERVER}";fi
#
# 3: Have a RUN that uses ssh-batch with the --bg-log-dir parameter, to write the output for each machine into it's own file.
#
# Note: You can additionally use -r redefine to change the filter. (file too old, failed verification, etc). Make sure that if you have a 
# serversfile with rich content (not only the servername, but also the user/jumphost/comment) to clean the input first.

RESULTSFILE="$OUTPUTDIR/$SERVER"

if [ -f $RESULTSFILE ];then
	exit 1
else
	exit 0
fi
EOF


chmod +x $SCRIPTS/*

cd -

NORM="\033[0m"
UNDR="\033[4;37m"

echo ""
echo -e "${UNDR}Last known servers file${NORM}"
cat << EOF
When you run a script with evidencer and end it with =# then it fetches
The newest file in ./$SERVERS/ to run the script.

EOF


echo -e "${UNDR}TAB EXPANSION${NORM}"
cat << EOF
Run: ./evidencer  and press tab a lot to select your script
Also run: ./evidencer spoon+   and press tab to show a list of scripts that contain 'spoon'
Tab expansion also works to select a suit after typing -s
Note that tab expansion is still buggy when adding aliases and other parameters it can not match.

# Run this to get tab expansion in your current terminal (this script already added it to your bashrc)
source $BASHRC
# else use eval for one-time tab expansion:
eval \$(./evidencer --complete)

EOF

echo -e "${UNDR}Build-in HELP${NORM}"
cat << EOF
Run: ./evidencer . -hv    for all available help from all scripts in verbose mode
instead of . you can use a substring of a script, and it will display that scripts help (if available)

Using -h without any parameters gives you help about evidencer itself.
Using --man without any parameters gives you a pseudo man page.

If your terminal does not support ANSI color codes, then use -r NOCOLORS=2 to print out the help:
./evidencer . -hvr NOCOLORS=2

Remember the scripts extracted are in a suit called DEMO, so this is what you need to run:

./evidencer -s DEMO -hv .

or:

cd suits/DEMO; ./evidencer . -hv

# Filter only on "frontend" machines
./evidencer get.a.spoon=VM-ET@frontend

# Do only 1 server (the first in the VM-PR list)
./evidencer get.a.fork=VM-PR@#1

# Do the rest (skip the first)
./evidencer get.a.fork=VM-PR@#2-

# alternatively, skip if result file is newer than 24 hours:
./evidencer /skipifnew get.a.fork=VM-PR@

EOF

