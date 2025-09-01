#!/bin/bash

# This function sets the PS1 variable
function prompt_command {
    local EXIT_CODE=$?
    # Set background and foreground colors
    local RESET="\[\033[0m\]" #0m restores to the terminal's default colour
    local DIVIDER="" # U+E0B0
    local DIVIDER2=""
    local WHITE="\[\033[97m\]"
    local WHITE_BOLD="\[\033[1;37m\]"
    local BG_DEFAULT="\[\033[49m\]"
    local BG_TIME="\[\033[48;2;105;121;16m\]"
    local FG_TIME="\[\033[38;2;105;121;16m\]"
    local BG_USER="\[\033[48;2;221;57;57m\]"
    local FG_USER="\[\033[38;2;221;57;57m\]"
    local FG_PATH="\[\033[38;2;0;0;223m\]"
    local BG_PATH="\[\033[48;2;0;0;223m\]"
    local FG_GIT="\[\033[38;2;0;139;139m\]"
    local BG_GIT="\[\033[48;2;0;139;139m\]"
    local FG_CONDA="\[\033[38;5;172m\]"
    local BG_CONDA="\[\033[48;5;172m\]"
    local FG_ERROR="\[\033[38;2;255;0;0m\]"
    local BG_ERROR="\[\033[48;2;255;0;0m\]"
    # Set the user name
    local myUSER="TBD"
    case $HOSTNAME-$USER in 
        Kitsune-*)                      myUSER="Kitsune" ;;
        zen-*)                          myUSER="Zen" ;;
        madamete-*)                     myUSER="Madamete" ;;
        hpclogin-*)                     myUSER="HPC" ;;
    esac
    if [ "$SINGULARITY_NAME" != "" ]; then myUSER="$SINGULARITY_NAME@$myUSER"; fi
    # Check the exit code of the last executed command
    local ERRMSG=""
    if [ $EXIT_CODE != 0 ]; then
        ERRMSG="[$EXIT_CODE]"
    fi
    # Check if the folder is a git repo
    local BRANCH=""
    local GIT_LOCAL_CHANGES=""
    if which git &>/dev/null; then
        local REMOTE=""
        local STATE=""
        local branch_pattern="^On branch ([a-zA-Z0-9_\-]*)" # This captures the branch name
        local remote_pattern="Your branch is (ahead|behind|up to date) " # This captures the status
        local diverge_pattern="Your branch and (.*) have diverged" # This captures the status
        local git_status="$(LC_ALL=C git status 2> /dev/null)"
        if [ "$git_status" != "" ] ; then
            # This sets a change
            if [[ ! ${git_status} =~ "working tree clean" ]]; then
                STATE="±"
            fi
            # If the pattern is captured, set A (ahead), B (behind) or empty (up-to-date)
            if [[ ${git_status} =~ ${remote_pattern} ]]; then
                if [[ ${BASH_REMATCH[1]} == "ahead" ]]; then
                    REMOTE="A"
                elif [[ ${BASH_REMATCH[1]} == "behind" ]]; then
                    REMOTE="B"
                else
                    REMOTE=""
                fi
            # If not ahead, behind or up-to-date, set U (unkown)
            else
                REMOTE="U"
            fi
            # This sets divergent
            if [[ ${git_status} =~ ${diverge_pattern} ]]; then
                REMOTE="${REMOTE}D"
            fi
            # Get the branch name
            if [[ ${git_status} =~ ${branch_pattern} ]]; then
                BRANCH=${BASH_REMATCH[1]}
            fi
            # Combine information
            GIT_LOCAL_CHANGES="${REMOTE}${STATE}"
            # Reformat if there is something to display
            if [ "$GIT_LOCAL_CHANGES" != "" ]; then
                GIT_LOCAL_CHANGES=" (${GIT_LOCAL_CHANGES})"
            fi
        fi
    fi
    # Check if conda is set (only show non-"base" environments)
    local CONDA=$CONDA_DEFAULT_ENV
    if [ "$CONDA" == "base" ]; then CONDA=""; fi
    # Create the PS1 variable
    local QUERY=""
    QUERY+="${BG_TIME}${WHITE}[\t]${FG_TIME}"
    QUERY+="${BG_USER}${DIVIDER}${WHITE}${myUSER}${FG_USER}"
    QUERY+="${BG_PATH}${DIVIDER}${WHITE}\w${RESET}${FG_PATH}"
    if [ "$CONDA" != "" ]; then QUERY+="${BG_CONDA}${DIVIDER}${WHITE}${CONDA}${FG_CONDA}"; fi
    if [ "$BRANCH" != "" ]; then QUERY+="${BG_GIT}${DIVIDER}${WHITE}${BRANCH}${GIT_LOCAL_CHANGES}${FG_GIT}"; fi
    if [ "$ERRMSG" != "" ]; then QUERY+="${BG_ERROR}${DIVIDER}${WHITE_BOLD}${ERRMSG}${FG_ERROR}"; fi
    QUERY+="${BG_DEFAULT}${DIVIDER}${RESET} "
    export PS1=$QUERY
}

# This function counts the number of files/directories/links in the current folder (no $1) or in a given folder ($1)
function files {
    local FILES="\033[31m" # Red
    local DIRECTORIES="\033[34m" # Blue
    local LINKS="\033[36m" # Cyan
    local RESET="\033[0m"
    if [ "$1" != "" ]; then
        if [ -d "$1" ]; then
            LOC="$1"
        else
            echo "\$1 ($1) is not a valid directory"
            return 1
        fi
    else
        LOC="."
    fi
    local nFILES=$(find $LOC -maxdepth 1 -type f | wc -l | sed -r "s/^ +//g")
    local nDIRECTORIES=$(find $LOC -mindepth 1 -maxdepth 1 -type d | wc -l | sed -r "s/^ +//g")
    local nLINKS=$(find $LOC -maxdepth 1 -type l | wc -l | sed -r "s/^ +//g")
    echo -e "Under \"$LOC\": ${FILES}${nFILES} files${RESET}; ${DIRECTORIES}${nDIRECTORIES} directories${RESET}; ${LINKS}${nLINKS} links${RESET}"
}

# This function jumps to X many parent directories (1 without $1)
function up {
    local d=""
    local limit=$1
    for ((i=1 ; i <= limit ; i++)); do
        d=$d/..
    done
    d=$(echo $d | sed 's/^\///')
    if [ -z "$d" ]; then
        d=..
    fi
    cd $d
}

# This function extracts a given archive ($1) with the right tool and/or options
function extract {
    if [ -f $1 ] ; then
        case $1 in
        *.tar.bz2)   tar xjf $1   ;;
        *.tar.gz)    tar xzf $1   ;;
        *.bz2)       bunzip2 $1   ;;
        *.rar)       unrar x $1   ;;
        *.gz)        gunzip $1    ;;
        *.tar)       tar xf $1    ;;
        *.tbz2)      tar xjf $1   ;;
        *.tgz)       tar xzf $1   ;;
        *.zip)       unzip $1     ;;
        *.Z)         uncompress $1;;
        *.7z)        7z x $1      ;;
        *)           echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file!"
    fi
}

# This function transfers a file/folder from a location ($1) to another ($2) using a double rsync (it checks md5 and removes source).
function transfer {
    if [[ -z $1 && -z $2 ]]; then echo "Usage: transfer <source> <destination>" && return 99; fi
    if [[ ! -e $1 ]]; then echo "\$1 ("$1") must exist" && return 99; fi
    if [[ ! -e $2 ]]; then echo "\$2 ("$2") must exist" && return 99; fi
    if [[ -e $1/$2 ]]; then echo "\$1/\$2 ($1/$2) must not exist" && return 99; fi

    DEST_TYPE=$(df -T $2 | awk 'NR==2' | sed -r 's/ +/ /g' | cut -f2 -d' ')
    if [[ "$DEST_TYPE" =~ ^(cifs|smb)$ ]]; then
        echo "# This is cifs|smb #"
        ARGS="--no-perms --no-times --no-group --no-links"
    else
        ARGS=""
    fi

    echo "############################"
    echo "##### Initial transfer #####"
    echo "############################"
    rsync -azv $ARGS $1 $2 || return 1

    echo "###########################"
    echo "##### Second transfer #####"
    echo "###########################"
    rsync --remove-source-files -azv -c $ARGS $1 $2 || return 2
    if [[ -d $1 ]]; then find $1 -type d -empty -delete || return 3; fi

    echo "#################"
    echo "##### Done. #####"
    echo "#################"
}

# This function tests whether a variable is writable (i.e. not readonly)
function is_writable {
    eval "$1+=" 2> /dev/null
}

if [[ "$-" =~ "i" ]]; then
    # Ignore case when using tab to autocomplete path
    bind 'set completion-ignore-case on'
    # Show auto-completion list automatically, without double tab
    bind "set show-all-if-ambiguous on"
fi
# give same rights to the group and user to everything I create
umask 0002
# Allow ctrl-S for history navigation (with ctrl-R)
stty -ixon
# Expand the history size
is_writable HISTFILESIZE && export HISTFILESIZE=10000
is_writable HISTSIZE && export HISTSIZE=500
# Don't put duplicate lines in the history and do not add lines that start with a space
is_writable HISTCONTROL && export HISTCONTROL=erasedups:ignoreboth
# Append to the history file, don't overwrite it
shopt -s histappend
# Check the window size after each command and, if necessary, update the values of LINES and COLUMNS
shopt -s checkwinsize
# My alliases
alias grep='grep --color=auto'
alias zgrep='zgrep --color=auto'
alias egrep='egrep --color=auto'
alias ls='ls --color=auto'
alias lsl='ls -lsah'
alias cd.='cd ../'
alias less='less -S'
alias vi='vim'
alias squeue="squeue -o \"%.10i %.8u %.9P %.20j %.20k %.2t %.12M %.12l %.6m %.3C %.3D %R\""
alias squ="squeue -u $USER"
alias sacctm='sacct --units=G --format JobID,JobName%60,Comment%20,Partition,Account,User,AllocCPUS,Elapsed,CPUTime,Timelimit,MaxRSS,ReqMem,NodeList,State,ExitCode'
# Set PROMPT_COMMAND
export PROMPT_COMMAND=prompt_command
