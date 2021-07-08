if true;then
if [ ! -f evidencer ];then
	echo "You are not in a directory with evidencer, please run this script from there"
	exit 1
fi

if [ ! -x evidencer ];then
	chmod +x evidencer
fi

echo "Downloading ssh-batch and deploying it to ~/bin"

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

for t in test1 test2 test3 ;do
	echo -e "echo '${e}=VM-ET'\n" > scripts/${t}=VM-ET
	if [ $t != "test1" ];then
		echo -e "echo '${e}=VM-PR'\n" > scripts/${t}=VM-PR
		[ $t = "test3" ] && echo -e "echo '${e}=VM+ doing a du - \$HOME'\ndu -h $HOME" > scripts/${t}=VM+
		[ $t = "test3" ] && echo -e "echo '${e}=VM-PR-DMZ'\n" > scripts/${t}=VM-PR-DMZ
	fi
done

fi

for t in a.spoon a.fork the.knife ;do
	s=scripts/get.${t}=+
	echo -e "echo '${e}=+'\n" > $s
	echo -e "#: This script fetches $(echo ${t}|tr '.' ' ') from the <B>cupboard. \n" >> $s
	echo -e "#: <R>Warning: You might need to replenish your cupboard when empty.\n" >> $s
	echo -e "#+: <Y>Usage: <L>./evidencer <L>get.${t}=# \n" >> $s
	echo -e "#+:\n" >> $s
	echo -e "#+: You can use the following text accents:\n" >> $s
	echo -e "#+: <B>BOLD <I>ITALIC <N>Normal <U>UNDERLINE <R>RED <G>GREEN <Y>YELLOW \n" >> $s
	echo -e "#+: <L>BLUE <P>PURPLE <C>CYAN <Z>INVERT <A>GRAY	\n" >> $s
done

cat << 'EOF' > scripts/header=+
### SERVER=`hostname` DATE=`date +%Y-%m-%d_%H:%M` TEST=__TEST__ ###
EOF

chmod +x scripts/*

for t in VM-PR VM-PR-DMZ VM-ET ;do
	echo -e "server1\nserver2\nserver3" > servers/${t}
done
echo -e "127.0.0.1" > servers/localhost

# Create a suit structure
./evidencer -C -s DEMO

cd suits/DEMO

echo -e "127.0.0.1" > servers/localhost

cat << 'EOF' > ./scripts/os.show.boottime=+
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

# Here we try a who -b, but if you have an older Linux, the -b option does not exist. In that case
# Try uptime -s
echo $((TZ=${_TZ} who -b||TZ=${_TZ} uptime -s) | sed -e 's/^[[:space:]]*//') $ARG

# Help can be added in any position of the script. In this case, I put it almost at the end.

#: Show the Linux boot time in the selected timezone.
#: The default TimeZone is <B>UTC, which you can change with a parameter.
#: you can select from the following deprecated timezones:
#: <B>CET <B>IST <B>EST <B>EST5EDT <B>PRC <B>ROC <B>ROK
#+: <Y>Example: <L>./evidencer <L>os.show.boottime=# <L>-- <L>CET
#+: <Y>Example: <L>./evidencer <L>os.show.boottime=# <L>-- <L>Europe/Lisbon
#+: <C>See: <A>https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
#+: So instead of <B>WET you need to use <B>Europe/Lisbon (although WET still works)

last reboot |head -4

EOF


chmod +x scripts/*

cd -

NORM="\033[0m"
UNDR="\033[4;37m"

echo ""
echo -e "${UNDR}Last known servers file${NORM}"
cat << EOF
When you run a script with evidencer and end it with =# then it fetches
The newest file in ./servers/ to run the script.

EOF


echo -e "${UNDR}TAB EXPANSION${NORM}"
cat << EOF
Run: ./evidencer  and press tab a lot to select your script
Also run: ./evidencer spoon+   and press tab to show a list of scripts that contain 'spoon'
Tab expansion also works to select a suit after typing -s

EOF

echo -e "${UNDR}Build-in HELP${NORM}"
cat << EOF
Run: ./evidencer . -hv    for all available help from all scripts in verbose mode
instead of . you can use a substring of a script, and it will display that scripts help (if available)

Using -h without any parameters gives you help about evidencer itself.
Using --man without any parameters gives you a pseudo man page.

EOF
