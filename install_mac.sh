#!/bin/bash

COLOR_NC=$'\e[0m' # No Color
COLOR_WHITE=$'\e[1;37m'
COLOR_BLACK=$'\e[0;30m'
COLOR_BLUE=$'\e[0;34m'
COLOR_LIGHT_BLUE=$'\e[1;34m'
COLOR_GREEN=$'\e[0;32m'
COLOR_LIGHT_GREEN=$'\e[1;32m'
COLOR_CYAN=$'\e[0;36m'
COLOR_LIGHT_CYAN=$'\e[1;36m'
COLOR_RED=$'\e[0;31m'
COLOR_LIGHT_RED=$'\e[1;31m'
COLOR_PURPLE=$'\e[0;35m'
COLOR_LIGHT_PURPLE=$'\e[1;35m'
COLOR_BROWN=$'\e[0;33m'
COLOR_YELLOW=$'\e[1;33m'
COLOR_GRAY=$'\e[0;30m'
COLOR_LIGHT_GRAY=$'\e[0;37m'

SELF_NAME=$(basename $0)
UC=$COLOR_WHITE

check_if_installed() {
    program=$1
    installer=$2
    printf "${UC}${COLOR_LIGHT_BLUE}Checking to see if $program is installed${COLOR_NC}\n"
    binary=$(command -v $program)
    if ! [ -x "$binary" ]; then
        printf "${UC}${COLOR_BLUE}Installing $program${COLOR_NC}\n";
        /bin/bash -c "$installer"
    else
        printf "${UC}${COLOR_GREEN}$program is installed${COLOR_NC}\n"
    fi
}

# add_line_to_profile()
# {
#     line_to_add=$1
#     if ! grep -Fx "$line_to_add" ~/.profile ~/.bash_profile >/dev/null 2>/dev/null; then
#         profile=~/.profile
#         [ -w "$profile" ] || profile=~/.bash_profile
#         printf "${UC}${COLOR_PURPLE}Adding $path_line to $profile${COLOR_NC}\n"
#         printf "%s\n" "$line_to_add" >> "$profile"
#     fi
# }

check_if_line_exists()
{
    # grep wont care if one or both files dont exist.
    grep -qsFx "$LINE_TO_ADD" $FILE_ADD_TO
}

add_line_to_file()
{
    # profile=~/.profile
    # [ -w "$profile" ] || profile=~/.bash_profile
    echo "$LINE_TO_ADD" >> $FILE_ADD_TO
}

# set profile file
if [[ ! -s "$HOME/.bash_profile" && -s "$HOME/.profile" ]] ; then
  profile_file="$HOME/.profile"
else
  profile_file="$HOME/.bash_profile"
fi

# Check to see if homebrew is installed and install it if it's not
check_if_installed "brew" "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
check_if_installed "node" "brew install nodejs"
check_if_installed "node" "brew install ruby"
check_if_installed "git" "brew install git"

check_if_installed "pip" <<EOF
curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
python get-pip.py --user
EOF

pip_path=$(find ~/Library/Python -type f -name "pip" | xargs dirname)

########################
# Update PATH in profile file
if ! grep -q "PATH=${pip_path}:$PATH" "${profile_file}"; then
    FILE_ADD_TO="${profile_file}"
    LINE_TO_ADD="export PATH=${pip_path}:\$PATH"
    check_if_line_exists || add_line_to_file
fi

source "${profile_file}"

check_if_installed "aws" <<EOF
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
installer -pkg ./AWSCLIV2.pkg -target /
EOF
check_if_installed "yarn" "brew install yarn"
check_if_installed "git-remote-codecommit" "pip install git-remote-codecommit"

printf "${UC}${COLOR_BLUE}Setting up git-remote-codecommit${COLOR_NC}\n"
git config --global credential.helper '!aws codecommit credential-helper $@'
git config --global credential.UseHttpPath true

printf "${UC}Now run aws configure with your credentials${COLOR_NC}\n"

printf "${UC}${COLOR_GREEN}HUZZAH. You are setup${COLOR_NC}\n"
