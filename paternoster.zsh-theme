function rprompt_git_status() {
	if [[ $GIT_REPO = true ]]; then
		echo -n "%{$fg[grey]%} %{$reset_color%}$(git config --get user.email)  "
	fi
}

function rprompt_jenv_status() {
	if $(type jenv >/dev/null 2>&1); then
		if [ -f './pom.xml' ]; then
			JENV_INFO=$(jenv version-name);
			echo -n "%{$fg[blue]%} %{$reset_color%}$JENV_INFO  "
		fi
	fi
}

function rprompt_node_version() {
	if $(type node >/dev/null 2>&1); then
		if [ -f './package.json' ]; then
			NODE_INFO=$(node -v)
			echo -n "%{$fg[green]%} %{$reset_color%}$NODE_INFO  "
		fi
	fi
}

timeout () {
	( sleep $1 ; kill -s ALRM $$ ) &
	shift
	"$@" &
	wait $!
}

build_rprompt() {
	rprompt_jenv_status
	rprompt_node_version
	rprompt_git_status
}

RPROMPT='%{$FG[008]%}$(build_rprompt)%{$reset_color%}'
