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
# InstallIfNotExist                                        #
############################################################

InstallIfNotExist()
{
   Package=$packageName
   if sudo pacman -Qs "$packageName" > /dev/null
   then
     if Verbose=1
     then
       echo "Package $Package is already installed!"
     fi
   else
     if Verbose=1
     then
       sudo pacman -Sq "$Package" --noconfirm  --noprogressbar
     else
       sudo pacman -Sq "$Package" --noconfirm  --noprogressbar > /dev/null
     fi
   fi
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
  sudo pacman -Syyu --noconfirm --noprogressbar
  echo "2. Removing unneeded packages"
  if sudo pacman -Qdtq
  then
    sudo pacman -Rns $(pacman -Qdtq) --noconfirm  --noprogressbar
  fi
else
  sudo pacman -Syyu --noconfirm --noprogressbar > /dev/null
  if sudo pacman -Qdtq > /dev/null
  then
    sudo pacman -Rns $(pacman -Qdtq) --noconfirm  --noprogressbar > /dev/null
  fi
fi

InstallIfNotExist git
InstallIfNotExist curl
InstallIfNotExist base-devel

#if Verbose=1
#then
#  echo "3. Installing basic development tools"
#  if IsPkgInstalled git
#  then
#    sudo pacman -S git --noconfirm  --noprogressbar
#  fi
#  if IsPkgInstalled curl
#  then
#    sudo pacman -S curl --noconfirm  --noprogressbar
#  fi
#  if IsPkgInstalled base-devel
#  then
#    sudo pacman -Sq base-devel --noconfirm  --noprogressbar
#  fi
#else
#  if IsPkgInstalled git
#  then
#    sudo pacman -S git --noconfirm  --noprogressbar > /dev/null
#  fi
#  if IsPkgInstalled curl
#  then
#    sudo pacman -S curl --noconfirm  --noprogressbar > /dev/null
#  fi
#  if IsPkgInstalled base-devel
#  then
#    sudo pacman -S base-devel --noconfirm  --noprogressbar > /dev/null
#  fi

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
      sudo pacman -S nano --noconfirm --noprogressbar
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
      sudo pacman -S atom --noconfirm --noprogressbar
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
