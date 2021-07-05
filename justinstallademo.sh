
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

echo "Setting up commandline completion for evidencer"

BASHRC=~/.bashrc
#if [ -f ~/.bash_aliases ];then
#	BASHRC=~/.bash_aliases
#fi

grep -q completion_for_evidencer $BASHRC

if [ $? != 0 ];then

cat << 'EOF' >> $BASHRC

if [[ "${-}" =~ 'i' ]];then

# completion_for_evidencer
function _getopt_complete () {
  COMPREPLY=($( COMP_CWORD=$COMP_CWORD perl `which ${COMP_WORDS[0]}` --complete ${COMP_WORDS[@]:0} ));
}
complete -F _getopt_complete evidencer

fi

EOF
echo "Please type this to enable autocompletion now:"
echo " source $BASHRC "
echo
echo "Or open a new terminal"

fi

./evidencer -C -t ..

for t in test1 test2 test3 ;do
	echo -e "echo '${e}=VM-ET'\n" > scripts/${t}=VM-ET
	if [ $t != "test1" ];then
		echo -e "echo '${e}=VM-PR'\n" > scripts/${t}=VM-PR
		[ $t = "test3" ] && echo -e "echo '${e}=VM+ doing a du - \$HOME'\ndu -h $HOME" > scripts/${t}=VM+
		[ $t = "test3" ] && echo -e "echo '${e}=VM-PR-DMZ'\n" > scripts/${t}=VM-PR-DMZ
	fi
done

for t in a.spoon a.fork the.knife ;do
	echo -e "echo '${e}=+'\n" > scripts/get.${t}=+
done

cat << 'EOF' >> scripts/header=+
### SERVER=`hostname` DATE=`date +%Y-%m-%d_%H:%M` TEST=__TEST__ ###
EOF

chmod +x scripts/*

for t in VM-PR VM-PR-DMZ VM-ET ;do
	echo -e "server1\nserver2\nserver3" > servers/${t}
done
echo -e "127.0.0.1" > servers/localhost


echo "Now run: ./evidencer  and press tabs a lot to select your script"


