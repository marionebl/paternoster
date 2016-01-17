# vim:ft=zsh ts=2 sw=2 sts=2
#
# patternoster
# =======
#
# An agnoster inspired zsh theme, based on [logon](https://gist.github.com/Neson/96487ceafd099d96c8d2)
### Configurations
# Display the git status on prompt by default?
L_DISPLAY_GIT_STATUS=true
# Note that you can use the command l-dis-git and l-en-git to switch this ...
# useful while browsing remote folders as git commands executes extremely slow.

# The Mark to show if the git working tree is dirty
L_GIT_DIRTY_MARK='±'

### Functions

l-dis-git() {
  L_DISPLAY_GIT_STATUS=false
}

l-en-git() {
  L_DISPLAY_GIT_STATUS=true
}

### Segment drawing
# A few utility functions to make it easy and re-usable to draw segmented prompts

L_CURRENT_BG='NONE'
L_SEGMENT_SEPARATOR='⮀'
L_SEGMENT_SEPARATOR_REVERSE='\uE0b8'

# Begin a segment
# Takes two arguments, background and foreground. Both can be omitted,
# rendering default background/foreground.
prompt_segment() {
  local bg fg
  [[ -n $1 ]] && bg="%K{$1}" || bg="%k"
  [[ -n $2 ]] && fg="%F{$2}" || fg="%f"
	[[ -n $4 ]] && reverse=true || reverse=false
  if [[ $L_CURRENT_BG != 'NONE' && $1 != $L_CURRENT_BG ]]; then
    if [[ $MOBILE != true ]]; then
			if [[ $reverse != true ]]; then
				echo -n " %{$bg%F{$L_CURRENT_BG}%}$L_SEGMENT_SEPARATOR%{$fg%} "
			else
				echo -n " %{$bg%F{$_CURRENT_BG}%}$L_SEGMENT_SEPARATOR_REVERSE%{$fg%} "
			fi
    else
      echo -n " %{$bg%F{$L_CURRENT_BG}%}%{$fg%} "
    fi
  else
    echo -n "%{$bg%}%{$fg%} "
  fi
  L_CURRENT_BG=$1
  [[ -n $3 ]] && echo -n $3
}

# End the prompt, closing any open segments
prompt_end() {
  if [[ -n $L_CURRENT_BG ]]; then
    if [[ $MOBILE != true ]]; then
      echo -n " %{%k%F{$L_CURRENT_BG}%}$L_SEGMENT_SEPARATOR"
    else
      echo -n " %{%k%F{$L_CURRENT_BG}%}"
    fi
  else
    echo -n "%{%k%}"
  fi
  echo -n "%{%f%}"
  L_CURRENT_BG=''
}

### Prompt components
# Each component will draw itself or hide itself if no information needs to be shown

# Find and simplify the computer name if running OS X (Darwin)
# "MacBook Pro" will display as "MBP" and "MacBook Air" will display as "MBA",
# additionally if it matches "[current_username]'s ", that will be hidden too.
if [[ $(uname) == "Darwin" ]]; then
  MAC_COMPUTERNAME=$(scutil --get ComputerName | sed "s/MacBook Pro[ ]*/MBP/g" | sed "s/MacBook Air[ ]*/MBA/g" | sed "s/ 的 /'s /g" | sed "s/${USER}'s //g" | sed "s/ /_/g")
fi

# Get some variables that can be used by everyone
prompt_prebuld() {
  SCREEN_WIDTH=$(tput cols)
  if [[ $(( $SCREEN_WIDTH < 50 )) = 1 ]] && MOBILE=true
  PWD="$(pwd | sed "s*$HOME*~*g")"
  if $(git rev-parse --is-inside-work-tree >/dev/null 2>&1); then
    GIT_REPO=true
    GIT_REF=$(git symbolic-ref HEAD 2> /dev/null) || ref="➦ $(git show-ref --head -s --abbrev | head -n1 2> /dev/null)"
    GIT_BRANCH=${GIT_REF/refs\/heads\//}
    if $(git log >/dev/null 2>&1); then
      GIT_HAS_COMMIT=true
    fi
  fi
}

# Context: user@hostname (who am I and where am I)
prompt_context() {
  [[ $MOBILE = true ]] && printf "\033[1A"
  local user=$(whoami)
  current_group=$(groups | sed 's/ .*//g')
  if [[ $current_group != $USER && $current_group != "staff" && $current_group != "users" ]]; then
    user="$user:$current_group"
  fi
  if [[ $(uname) == "Darwin" ]]; then
    L_BUILT_PROMPT="$L_BUILT_PROMPT $user@$MAC_COMPUTERNAME  "
    if [[ $MOBILE != true ]]; then
      prompt_segment black default "%(!.%{%F{yellow}%}.)$user@$MAC_COMPUTERNAME"
    else
      prompt_segment 0 6 "$user@$MAC_COMPUTERNAME"
    fi
  else
    L_BUILT_PROMPT="$L_BUILT_PROMPT $user@%m  "
    if [[ $MOBILE != true ]]; then
      prompt_segment black default "%(!.%{%F{yellow}%}.)$user@%m"
    else
      prompt_segment 0 6 "$user@%m"
    fi
  fi
}

# Git: branch/detached head, dirty status
prompt_git() {
  if [[ $L_DISPLAY_GIT_STATUS = true ]]; then
    local ref dirty
    if [[ $GIT_REPO = true ]]; then
      dirty=$(parse_git_dirty)
      ref=$(git symbolic-ref HEAD 2> /dev/null) || ref="➦ $(git show-ref --head -s --abbrev | head -n1 2> /dev/null)"
      if [[ -n $dirty ]]; then
        prompt_segment yellow black
        [[ $MOBILE != true ]] && dirty="$L_GIT_DIRTY_MARK"
      else
        prompt_segment green black
      fi
      if [[ $MOBILE != true ]]; then
        L_BUILT_PROMPT="$L_BUILT_PROMPT ${ref/refs\/heads\//⭠ }$dirty  "
        echo -n "${ref/refs\/heads\//⭠ }$dirty"
      else
        L_BUILT_PROMPT="$dirty"
        echo -n "$dirty"
      fi
    fi
  fi
}

# Dir: current working directory
# if it tends to spill over the screen, slash it from the left
prompt_dir() {
  T=$PWD
  I=$(echo "$T" | grep -o '/' | wc -l | sed 's/ //g')
  OTHER_PROMPT="$GIT_BRANCH................."
  [[ $MOBILE = true ]] && L_BUILT_PROMPT='' && OTHER_PROMPT='.....'
  if [[ $(expr "$(expr ${#L_BUILT_PROMPT} + ${#T} + ${#OTHER_PROMPT}) < $SCREEN_WIDTH") -eq 0 ]]; then
    T=$(echo "$T" | sed 's/\/[^\/]*\//\/...\//2')
    while [[ $(expr "$(expr ${#L_BUILT_PROMPT} + ${#T} + ${#OTHER_PROMPT}) < $SCREEN_WIDTH") -eq 0 && $(expr "$I > 1" ) -eq 1 ]]; do
      I=$(expr $I - 1)
      T=$(echo "$T" | sed 's/\/[.][.][.]\/[^\/]*\//\/...\//g')
    done
    if [[ $(expr "$(expr ${#L_BUILT_PROMPT} + ${#T} + ${#OTHER_PROMPT}) < $SCREEN_WIDTH") -eq 0 ]]; then
      T=$(echo "$T" | sed 's/\/[^\/]*\//\/...\//')
    fi
    if [[ $(expr "$(expr ${#L_BUILT_PROMPT} + ${#T} + ${#OTHER_PROMPT}) < $SCREEN_WIDTH") -eq 0 ]]; then
      T=$(echo "$T" | sed 's/\/[.][.][.]\/[^\/]*\//\/...\//g')
      T=$(echo "$T" | sed 's/[.][.][.]\/[.][.][.]/.../g')
    fi
  fi
  L_BUILT_PROMPT="$L_BUILT_PROMPT $T  "
  prompt_segment blue black "$T"
}

# Status:
# - was there an error
# - am I root
# - are there background jobs?
prompt_status() {
  local symbols
  symbols=()
  [[ $(jobs -l | wc -l) -gt 0 ]] && symbols+="%{%F{cyan}%}⚙" && L_BUILT_PROMPT="$L_BUILT_PROMPT J "
  [[ $RETVAL -ne 0 ]] && symbols+="%{%F{red}%}✘" && L_BUILT_PROMPT="$L_BUILT_PROMPT ! "
  [[ $UID -eq 0 ]] && symbols+="%{%F{yellow}%}⚡" && L_BUILT_PROMPT="$L_BUILT_PROMPT S "

  [[ -n "$symbols" ]] && prompt_segment black default "$symbols"

  [[ $MOBILE = true ]] && [[ -n $GIT_BRANCH ]] && echo -n "  $GIT_BRANCH$parse_git_dirty" && echo " "
}

prompt_date() {
  if [[ $MOBILE != true ]]; then
    if [[ $(expr "$(($SCREEN_WIDTH - ${#L_BUILT_PROMPT})) >= 18") -eq 1 ]]; then
      prompt_segment black default "%*"
    else
      prompt_segment black default ""
    fi
  fi
}

## The Main prompt
build_prompt() {
  RETVAL=$?
  L_BUILT_PROMPT=''
  SCREEN_WIDTH=0
  MOBILE=false
  PWD=''
  GIT_REPO=false
  GIT_REF=''
  GIT_BRANCH=''
  GIT_HAS_COMMIT=false

  prompt_prebuld
  prompt_date
  prompt_dir
  prompt_git
  prompt_end
}

### The Right Prompt

function rprompt_git_status() {
  if [[ $GIT_REPO = true ]]; then
    echo -n "%{$fg[grey]%} %{$reset_color%}$(git config --get user.email)  "
  fi
}

function rprompt_jenv_status() {
	if $(type jenv >/dev/null 2>&1); then
		JENV_INFO=$(jenv version-name);
		echo -n "%{$fg[blue]%} %{$reset_color%}$JENV_INFO  "
	fi
}

function rprompt_rvm_status() {
  if $(type rvm >/dev/null 2>&1); then
		RVM_INFO=$(rvm current)
		echo -n "%{$fg[red]%} %{$reset_color%}$RVM_INFO  "
  fi
}

function rprompt_nvm_status() {
  if $(type nvm >/dev/null 2>&1); then
    NVM_INFO=$(nvm current)
		echo -n "%{$fg[green]%} %{$reset_color%}$NVM_INFO  "
  fi
}

## Right prompt

build_rprompt() {
  RETVAL=$?
  L_BUILT_RPROMPT=''
  SCREEN_WIDTH=0
  GIT_REPO=false
  GIT_HAS_COMMIT=false

  prompt_prebuld

	rprompt_jenv_status
  rprompt_rvm_status
  rprompt_nvm_status
  rprompt_git_status
}

PROMPT='
%{%f%b%k%}$(build_prompt) %(!.#) '



RPROMPT='%{$FG[008]%}$(build_rprompt)%{$reset_color%}'
