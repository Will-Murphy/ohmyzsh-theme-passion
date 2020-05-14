# REf https://github.com/ChesterYue
# gdate for macOS
# REF: https://apple.stackexchange.com/questions/135742/time-in-milliseconds-since-epoch-in-the-terminal

#Custom Colors [0-256]
DIR_COLOR=244

GIT_STATUS_COLOR=002
GIT_BRANCH_COLOR=244
GIT_DIRTY_COLOR=202

ARROW_1_COLOR=002
ARROW_2_COLOR=231
ARROW_3_COLOR=202

# Time after which to display cost and program command
MAX_DISPLAY_COST=5

if [[ "$OSTYPE" == "darwin"* ]]; then
    {
        gdate
    } || {
        echo "\n$fg_bold[yellow]passsion.zsh-theme depends on cmd [gdate] to get current time in milliseconds$reset_color"
        echo "$fg_bold[yellow][gdate] is not installed by default in macOS$reset_color"
        echo "$fg_bold[yellow]to get [gdate] by running:$reset_color"
        echo "$fg_bold[green]brew install coreutils;$reset_color";
        echo "$fg_bold[yellow]\nREF: https://github.com/ChesterYue/ohmyzsh-theme-passion#macos\n$reset_color"
    }
fi


# time
function real_time() {
    local color="%{$fg_no_bold[white]%}";                    # color in PROMPT need format in %{XXX%} which is not same with echo
    local time="[$(date +%H:%M:%S)]";
    local color_reset="%{$reset_color%}";
    echo "${color}${time}${color_reset}";
}


# directory
function directory() {
    local color="%{$FG[$DIR_COLOR]%}";
    # REF: https://stackoverflow.com/questions/25944006/bash-current-working-directory-with-replacing-path-to-home-folder
    local directory="${PWD/#$HOME/~}";
    local color_reset="%{$reset_color%}";
    echo "${color}${directory}${color_reset}";
}


# git
ZSH_THEME_GIT_PROMPT_PREFIX="%{$FG[$GIT_STATUS_COLOR]%}git(%{$FG[$GIT_BRANCH_COLOR]%}";
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%} ";
ZSH_THEME_GIT_PROMPT_DIRTY="%{$FG[$GIT_STATUS_COLOR]%})%{$FG[$GIT_DIRTY_COLOR]%}✗";
ZSH_THEME_GIT_PROMPT_CLEAN="%{$FG[$GIT_STATUS_COLOR]%})";

function update_git_status() {
    GIT_STATUS=$(git_prompt_info);
}

function git_status() {
    echo "${GIT_STATUS}"
}


# command
function update_command_status() {
    local arrow="";
    local color_reset="%{$reset_color%}";
    local reset_font="%{$fg_no_bold[white]%}";
    if $1;
    then
        arrow="%{$FG[$ARROW_1_COLOR]%}❱%{$FG[$ARROW_2_COLOR]%}❱%{$FG[$ARROW_3_COLOR]%}❱";
    else
        arrow="%{$fg_bold[red]%}❱❱❱";
    fi
    COMMAND_STATUS="${arrow}${reset_font}${color_reset}";
}
update_command_status true;

function command_status() {
    echo "${COMMAND_STATUS}"
}


# output command execute after
output_command_execute_after() {
    if [ "$COMMAND_TIME_BEIGIN" = "-20200325" ] || [ "$COMMAND_TIME_BEIGIN" = "" ];
    then
        return 1;
    fi

    
    # If cost is less than MAX_DISPLAY_COST, display nothing
    local time_end="$(current_time_millis)";
    local cost=$(bc -l <<<"${time_end}-${COMMAND_TIME_BEIGIN}");
    if (( $(echo "$cost > $MAX_DISPLAY_COST" |bc -l) )); 
    then 

        #cost
        COMMAND_TIME_BEIGIN="-20200325"
        local length_cost=${#cost};
        if [ "$length_cost" = "4" ];
        then
            cost="0${cost}"
        fi
        cost="[cost ${cost}s]"
        local color_cost="$fg_no_bold[white]";
        cost="${color_cost}${cost}${color_reset}";

        # cmd
        local cmd="${$(fc -l | tail -1)#*  }";
        local color_cmd="";
        if $1;
        then
            color_cmd="$fg_no_bold[green]";
        else
            color_cmd="$fg_bold[red]";
        fi
        local color_reset="$reset_color";
        cmd="${color_cmd}${cmd}${color_reset}"

        # time
        # local time="[$(date +%H:%M:%S)]"
        # local color_time="$fg_no_bold[white]";
        # time="${color_time}${time}${color_reset}";
        

        # echo -e "${time} ${cost} ${cmd}";
        
        echo -e "${cost} ${cmd}";
       
    fi
}


# command execute before
# REF: http://zsh.sourceforge.net/Doc/Release/Functions.html
preexec() {
    COMMAND_TIME_BEIGIN="$(current_time_millis)";
}

current_time_millis() {
    local time_millis;
    if [[ "$OSTYPE" == "linux-gnu" ]]; then
        # Linux
        time_millis="$(date +%s.%3N)";
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        time_millis="$(gdate +%s.%3N)";
    elif [[ "$OSTYPE" == "cygwin" ]]; then
        # POSIX compatibility layer and Linux environment emulation for Windows
    elif [[ "$OSTYPE" == "msys" ]]; then
        # Lightweight shell and GNU utilities compiled for Windows (part of MinGW)
    elif [[ "$OSTYPE" == "win32" ]]; then
        # I'm not sure this can happen.
    elif [[ "$OSTYPE" == "freebsd"* ]]; then
        # ...
    else
        # Unknown.
    fi
    echo $time_millis;
}


# command execute after
# REF: http://zsh.sourceforge.net/Doc/Release/Functions.html
precmd() {
    # last_cmd
    local last_cmd_return_code=$?;
    local last_cmd_result=true;
    if [ "$last_cmd_return_code" = "0" ];
    then
        last_cmd_result=true;
    else
        last_cmd_result=false;
    fi

    # update_git_status
    update_git_status;

    # update_command_status
    update_command_status $last_cmd_result;

    # output command execute after
    output_command_execute_after $last_cmd_result;
}


# set option
setopt PROMPT_SUBST;


# timer
#REF: https://stackoverflow.com/questions/26526175/zsh-menu-completion-causes-problems-after-zle-reset-prompt
TMOUT=1;
TRAPALRM() {
    # $(git_prompt_info) cost too much time which will raise stutters when inputting. so we need to disable it in this occurence.
    # if [ "$WIDGET" != "expand-or-complete" ] && [ "$WIDGET" != "self-insert" ] && [ "$WIDGET" != "backward-delete-char" ]; then
    # black list will not enum it completely. even some pipe broken will appear.
    # so we just put a white list here.
    if [ "$WIDGET" = "" ] || [ "$WIDGET" = "accept-line" ] ; then
        zle reset-prompt;
    fi
}


# prompt
# PROMPT='$(real_time) $(directory) $(git_status)$(command_status) ';
PROMPT='$(directory) $(git_status)$(command_status) ';