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

function rprompt_rvm_status() {
	if $(type rvm >/dev/null 2>&1); then
		if [ -f './Gemfile' ]; then
			RVM_INFO=$(rvm current)
			echo -n "%{$fg[red]%} %{$reset_color%}$RVM_INFO  "
		fi
	fi
}

function rprompt_nvm_status() {
	if $(type nvm >/dev/null 2>&1); then
		if [ -f './package.json' ]; then
			NVM_INFO=$(nvm current)
			echo -n "%{$fg[green]%} %{$reset_color%}$NVM_INFO  "
		fi
	fi
}

function rprompt_docker_machine_status() {
	if $(type docker-machine >/dev/null 2>&1); then
		if [[ -f 'Dockerfile' || -f '.dockerignore' ]]; then
			docker-machine status defaulti >/dev/null 2>&1;
			DOCKER_MACHINE_AVAILABE=$(test $? -eq 0);
			if [ DOCKER_MACHINE_AVAILABE ]; then
				DOCKER_MACHINE_INFO=$(docker-machine status default)
				DOCKER_MACHINE_COLOR=darkgray
				if [ $DOCKER_MACHINE_INFO = 'Running' ]; then
					DOCKER_MACHINE_COLOR=gray
				fi
			else
				DOCKER_MACHINE_COLOR=red
				DOCKER_MACHINE_INFO=''
			fi
			echo -n "%{$fg[$DOCKER_MACHINE_COLOR]%} %{$reset_color%}$DOCKER_MACHINE_INFO  "
		fi
	fi
}

function rprompt_jenkins_status() {
	if [[ (-f './binary/jenkins.js' || -f './node_modules/.bin/jenkins') ]]; then
		if [ -f './binary/jenkins.js' ]; then
			EXEC='./binary/jenkins.js';
		elif [ -f './node_modules/.bin/jenkins' ]; then
			EXEC='./node_modules/.bin/jenkins';
		fi

		JENKINS_STATUS=$(node $EXEC status)
		SIGN=' ';

		if [[ $JENKINS_STATUS = 'disconnected' ]] then;
			TEXT='Disconnected'
			COLOR='yellow';
		elif [[ $JENKINS_STATUS = 'passing' ]] then;
			TEXT='Passing';
			COLOR='green';
		elif [[ $JENKINS_STATUS = 'failing' ]] then;
			TEXT='Failing';
			COLOR='red';
		else
			TEXT='Unknown';
			COLOR='grey';
		fi
		echo -n "%{$fg[$COLOR]%}$SIGN%{$reset_color%}$TEXT  "
	fi
}

build_rprompt() {
	rprompt_jenkins_status
	rprompt_docker_machine_status
	rprompt_jenv_status
	rprompt_rvm_status
	rprompt_nvm_status
	rprompt_git_status
}

RPROMPT='%{$FG[008]%}$(build_rprompt)%{$reset_color%}'
