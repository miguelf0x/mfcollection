#!/usr/bin/env bash

############################################################
# Variables                                                #
############################################################

Verbose=1
Tweaking=1

############################################################
# Help                                                     #
############################################################

Help()
{
   # Display Help
   echo "This script is designed for automatisation of installing some necessary packages"
   echo "Script should not be run as root"
   echo
   echo "Syntax: mfcollection [-v|-h|-t]"
   echo "Options:"
   echo "h     Print this help."
   echo "v     Verbose mode."
   echo "t     Applies minor tweaks to system"
   echo
}

############################################################
# IsPkgInstalled                                           #
############################################################

IsPkgInstalled()
{
   local res=$(sudo pacman -Qs "$packageName" > /dev/null)
   if [[ "$res" -eq 1 ]];
   then
     return 0
   else
     return 1
   fi
}

############################################################
# Main code                                                #
############################################################

while getopts ":hvt:" option; do
   case $option in
      h) # display Help
         Help
         exit;;
      v) # Verbose mode
         Verbose=0;;
      t) # Tweaking mode
         Tweaking=0;;
     \?) # Invalid option
         echo "Error: Invalid option"
         exit;;
   esac
done

case $Verbose in
    1) # Verbose mode is OFF
        sudo pacman -Syyu --noconfirm --noprogressbar > /dev/null
        sudo pacman -Rns $(pacman -Qdtq) --noconfirm  --noprogressbar > /dev/null
        if IsPkgInstalled git
        then
          sudo pacman -S git --noconfirm  --noprogressbar > /dev/null
        fi
        if IsPkgInstalled curl
        then
          sudo pacman -S curl --noconfirm  --noprogressbar > /dev/null
        fi
        if IsPkgInstalled base-devel
        then
          sudo pacman -S base-devel --noconfirm  --noprogressbar > /dev/null
        fi
        cd /tmp
        git clone https://aur.archlinux.org/yay.git > /dev/null
        sudo chown -R $USER yay > /dev/null
        cd yay
        makepkg -si --noconfirm --noprogressbar > /dev/null
        ;;
    0) # Verbose mode is ON
        echo "1. Updating system"
        sudo pacman -Syyu --noconfirm --noprogressbar
        echo "2. Removing unrequired packages"
        sudo pacman -Rns $(pacman -Qdtq) --noconfirm  --noprogressbar
        echo "3. Installing basic development tools"
        if IsPkgInstalled git
        then
          sudo pacman -S git --noconfirm  --noprogressbar
        fi
        if IsPkgInstalled curl
        then
          sudo pacman -S curl --noconfirm  --noprogressbar
        fi
        if IsPkgInstalled base-devel
        then
          sudo pacman -S base-devel --noconfirm  --noprogressbar
        fi
        echo "4. Installing yay"
        cd /tmp
        git clone https://aur.archlinux.org/yay.git
        sudo chown -R $USER yay
        cd yay
        makepkg -si --noconfirm --noprogressbar
        ;;
esac

case $Tweaking in
    1) #Tweaking is disabled
        if $Verbose
        then
            echo "Skipping step 5: Tweaking disabled"
        fi
        ;;
    0) #Tweaking is enabled
        if $Verbose
        then
            echo "5. Tweaking system"
        fi
        cd /tmp
        echo "Enable SysRq key?"
        read -r -p "Your choice [y/N] " response
        if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
        then
            echo "kernel.sysrq=1" >> 90-override.conf.tmp
        else
            :
        fi
        echo "Change vm.swappiness to optimum value?"
        read -r -p "Your choice [y/N] " response
        if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
        then
            mem=$(awk '/MemFree/ { printf "%.3f \n", $2/1024/1024 }' /proc/meminfo)
            if (($mem<=512))
            then
                $swappiness_opt = 60
            elif ((512<$mem && $mem<=2048))
            then
                $swappiness_opt = 50
            elif ((2048<$mem && $mem<=8192))
            then
                $swappiness_opt = 40
            elif ((8192<$mem && $mem<=16384))
            then
                $swappiness_opt = 20
            else
                $swappiness_opt = 10
            fi
            echo "vm.swappiness = $swappiness_opt" >> 90-override.conf.tmp
        else
            :
        fi
        echo "Are these options correct?"
        echo "##############################"
        cat 90-override.conf.tmp
        if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
        then
            cp 90-override.conf.tmp /etc/sysctl.d/90-override.conf
        else
            :
        fi
        ;;
esac
