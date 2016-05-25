#!/usr/bin/env bash

###########################
# This script installs the dotfiles and runs all other system configuration scripts
# @author Adam Eivy
###########################

# include my library helpers for colorized echo and require_brew, etc
source ./lib.sh

# make a backup directory for overwritten dotfiles
mkdir -p ~/.dotfiles_backup
# ensure ~/.gitshots exists
mkdir -p ~/.gitshots

bot "Hi. I'm going to make your OSX system better. But first, I need to configure this project based on your info so you don't check in files to github as Adam Eivy from here on out :)"

fullname=`osascript -e "long user name of (system info)"`

if [[ -n "$fullname" ]];then
  lastname=$(echo $fullname | awk '{print $2}');
  firstname=$(echo $fullname | awk '{print $1}');
fi

# me=`dscl . -read /Users/$(whoami)`

if [[ -z $lastname ]]; then
  lastname=`dscl . -read /Users/$(whoami) | grep LastName | sed "s/LastName: //"`
fi
if [[ -z $firstname ]]; then
  firstname=`dscl . -read /Users/$(whoami) | grep FirstName | sed "s/FirstName: //"`
fi
email=`dscl . -read /Users/$(whoami)  | grep EMailAddress | sed "s/EMailAddress: //"`

if [[ ! "$firstname" ]];then
  response='n'
else
  echo -e "I see that your full name is $COL_YELLOW$firstname $lastname$COL_RESET"
  read -r -p "Is this correct? [Y|n] " response
fi

if [[ $response =~ ^(no|n|N) ]];then
  read -r -p "What is your first name? " firstname
  read -r -p "What is your last name? " lastname
fi
fullname="$firstname $lastname"

bot "Great $fullname, "

if [[ ! $email ]];then
  response='n'
else
  echo -e "The best I can make out, your email address is $COL_YELLOW$email$COL_RESET"
  read -r -p "Is this correct? [Y|n] " response
fi

if [[ $response =~ ^(no|n|N) ]];then
  read -r -p "What is your email? " email
  if [[ ! $email ]];then
    error "you must provide an email to configure .gitconfig"
    exit 1;
  fi
fi

grep 'user = GITHUBUSER' .gitconfig
if [[ $? = 0 ]]; then
    read -r -p "What is your github.com username?" githubuser
fi

running "replacing items in .gitconfig with your info ($COL_YELLOW$fullname, $email, $githubuser$COL_RESET)"

# test if gnu-sed or osx sed

sed -i "s/GITHUBFULLNAME/$firstname $lastname/" .gitconfig > /dev/null 2>&1 | true
if [[ ${PIPESTATUS[0]} != 0 ]]; then
  echo
  running "looks like you are using OSX sed rather than gnu-sed, accommodating"
  sed -i '' "s/GITHUBFULLNAME/$firstname $lastname/" .gitconfig;
  sed -i '' 's/GITHUBEMAIL/'$email'/' .gitconfig;
  sed -i '' 's/GITHUBUSER/'$githubuser'/' .gitconfig;
else
  echo
  bot "looks like you are already using gnu-sed. woot!"
  sed -i 's/GITHUBEMAIL/'$email'/' .gitconfig;
  sed -i 's/GITHUBUSER/'$githubuser'/' .gitconfig;
fi

# read -r -p "OK? [Y/n] " response
#  if [[ ! $response =~ ^(yes|y|Y| ) ]];then
#     exit 1
#  fi

# bot "awesome. let's roll..."

echo $0 | grep zsh > /dev/null 2>&1 | true
if [[ ${PIPESTATUS[0]} != 0 ]]; then
  running "changing your login shell to zsh"
  chsh -s $(which zsh);ok
else
  bot "looks like you are already using zsh. woot!"
fi


git clone https://github.com/bhilburn/powerlevel9k.git oh-my-zsh/custom/themes/powerlevel9k

read -r -p "Do you want to use the project desktop background? [Y|n] " response
if [[ $response =~ ^(no|n|N) ]];then
  echo "skipping...";
  ok
else
  running "Set a custom wallpaper image"
  # `DefaultDesktop.jpg` is already a symlink, and
  # all wallpapers are in `/Library/Desktop Pictures/`. The default is `Wave.jpg`.
  rm -rf ~/Library/Application Support/Dock/desktoppicture.db
  sudo rm -f /System/Library/CoreServices/DefaultDesktop.jpg
  sudo rm -f /Library/Desktop\ Pictures/El\ Capitan.jpg
  sudo cp ./img/wallpaper.jpg /System/Library/CoreServices/DefaultDesktop.jpg;
  sudo cp ./img/wallpaper.jpg /Library/Desktop\ Pictures/El\ Capitan.jpg;ok
fi

pushd ~ > /dev/null 2>&1

bot "creating symlinks for project dotfiles..."

symlinkifne .crontab
symlinkifne .config/fontconfig
symlinkifne .gemrc
symlinkifne .gitconfig
symlinkifne .gitignore
symlinkifne .profile
symlinkifne .screenrc
symlinkifne .shellaliases
symlinkifne .shellfn
symlinkifne .shellpaths
symlinkifne .shellvars
symlinkifne .tmux.conf
symlinkifne .vim
symlinkifne .vimrc
symlinkifne .zlogout
symlinkifne .zprofile
symlinkifne .zshenv
symlinkifne .zshrc

popd > /dev/null 2>&1

./osx.sh

bot "Woot! All done."
