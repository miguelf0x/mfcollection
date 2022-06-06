#!/usr/bin/env bash

############################################################
# Vars                                                     #
############################################################

Verbose=0

############################################################
# Help                                                     #
############################################################

Help()
{
   # Display Help
   echo "This script is designed for automatisation of installing some necessary packages"
   echo
   echo "Syntax: mfcollection [-v|-h]"
   echo "Options:"
   echo "h     Print this help."
   echo "v     Verbose mode."
   echo
}

############################################################
# IsPkgInstalled                                           #
############################################################

IsPkgInstalled()
{
   sudo pacman -Qs "$packageName" > /dev/null
}

############################################################
# Main code                                                #
############################################################

while getopts ":hv:" option; do
   case $option in
      h) # display Help
         Help
         exit;;
      v) # Enter a name
         Verbose=1;;
     \?) # Invalid option
         echo "Error: Invalid option"
         exit;;
   esac
done

if Verbose=1
then
  echo "1. Updating system"
fi

sudo pacman -Syyuq --noconfirm --noprogressbar

if Verbose=1
then
  echo "2. Removing unneeded packages"
fi

sudo pacman -Rnsq $(pacman -Qdtq) --noconfirm  --noprogressbar

if Verbose=1
then
  echo "3. Installing basic development tools"
fi

if IsPkgInstalled git
then
  sudo pacman -Sq git --noconfirm  --noprogressbar
fi

if IsPkgInstalled curl
then
  sudo pacman -Sq curl --noconfirm  --noprogressbar
fi

if IsPkgInstalled base-devel
then
  sudo pacman -Sq base-devel --noconfirm  --noprogressbar
fi

cd /tmp
git clone https://aur.archlinux.org/yay.git
sudo chown -R $USER yay
cd yay
makepkg -si --noconfirm --noprogressbar

if Verbose=1
then
  echo "4. Installing optional packages"
fi

#Office tools

if IsPkgInstalled nano
then
  echo "Install nano CLI text editor?"
  read -r -p "Your choice [y/N] " response
  if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
  then
      sudo pacman -Sq nano --noconfirm --noprogressbar
  else
      :
  fi
fi

if IsPkgInstalled atom
then
  echo "Install Atom GUI text editor?"
  read -r -p "Your choice [y/N] " response
  if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
  then
      sudo pacman -Sq atom --noconfirm --noprogressbar
  else
      :
  fi
fi

#Internet tools
#pacman -S firefox --noconfirm

echo "Install file transfer tools? (qbittorrent, filezilla)"
read -r -p "Your choice [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
then
    sudo pacman -S qbittorrent filezilla --needed --noconfirm --noprogressbar
else
    :
fi

echo "Install messengers? (telegram, discord)"
read -r -p "Your choice [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
then
    sudo pacman -S telegram-desktop discord --needed --noconfirm --noprogressbar
else
    :
fi

#Multimedia
#pacman -S smplayer --noconfirm

#Development tools
#pacman -S tigervnc --noconfirm
