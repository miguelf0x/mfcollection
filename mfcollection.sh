#!/usr/bin/env bash

###############################################################################
#                             mfcollection script                             #
#                                                                             #
#  This script is designed for faster completion of Archlinux based systems.  #
#  Currently implemented functions are:                                       #
#     Updating system                                                         #
#     Removing unrequired packages                                            #
#     Installing git, curl, base-devel (required for yay compiling)           #
#     Enabling SysRq key combinations                                         #
#     Changing vm.swappiness value to optimal one (depending on RAM size)     #
#     Changing IO schedulers to optimal ones (depending on drive type)        #
#                                                                             #
###############################################################################


###############################################################################
# Variables                                                                   #
###############################################################################

Verbose=1     #disabled by default
Tweaking=1    #disabled by default


###############################################################################
# Help: displays help                                                         #
###############################################################################

Help()
{
   echo "This script is designed for automatisation of installing some necessary packages"
   echo "Script should not be run as root"
   echo
   echo "Syntax: mfcollection [-v|h|t]"
   echo "Options:"
   echo "h     Print this help."
   echo "v     Verbose mode."
   echo "t     Applies minor tweaks to system"
   echo
}


################################################################################
# IsPkgInstalled: checks if package is installed                               #
################################################################################

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


################################################################################
# WriteSchedConfig: writes optimal IO scheduler config                         #
################################################################################

WriteSchedConfig()
{
echo "# set scheduler for NVMe" > /etc/udev/rules.d/60-ioschedulers.rules
echo "ACTION==\"add|change\", KERNEL==\"nvme[0-9]*\", ATTR{queue/scheduler}=\"none\"" >> /etc/udev/rules.d/60-ioschedulers.rules
echo "# set scheduler for eMMC and SSD" >> /etc/udev/rules.d/60-ioschedulers.rules
echo "ACTION==\"add|change\", KERNEL==\"sd[a-z]|mmcblk[0-9]*\", ATTR{queue/rotational}==\"0\", ATTR{queue/scheduler}=\"bfq\"" >> /etc/udev/rules.d/60-ioschedulers.rules
echo "# set scheduler for rotating disks" >> /etc/udev/rules.d/60-ioschedulers.rules
echo "ACTION==\"add|change\", KERNEL==\"sd[a-z]\", ATTR{queue/rotational}==\"1\", ATTR{queue/scheduler}=\"bfq\"" >> /etc/udev/rules.d/60-ioschedulers.rules
}


################################################################################
# Main code                                                                    #
################################################################################

SHORT=h,v,t
LONG=help,verbose,tweak
OPTS=$(getopt -a -n mfcollection --options $SHORT --longoptions $LONG -- "$@")
VALID_ARGUMENTS=$#

eval set -- "$OPTS"

while [ "$1" != "--" ];
do
  case "$1" in
    -h | --help)
        Help
        exit
        ;;
    -v|--verbose)
        Verbose=0
        shift
        ;;
    -t|--tweak) # Tweaking mode
        Tweaking=0
        shift
        ;;
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
        git clone https://aur.archlinux.org/yay.git >> /dev/null
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
        if [[ $Verbose -eq 0 ]];
        then
            echo "Skipping step 5: Tweaking disabled"
        fi
        ;;
    0) #Tweaking is enabled
        if [[ $Verbose -eq 0 ]];
        then
            echo "5. Tweaking system"
        fi

        cd /tmp
        echo "###################################################" >> 90-override.conf.tmp
        echo "# This config is generated by mfcollection script #" >> 90-override.conf.tmp
        echo "#           USE ONLY AT YOUR OWN RISK !           #" >> 90-override.conf.tmp
        echo "###################################################" >> 90-override.conf.tmp
        echo "" >> 90-override.conf.tmp

        read -r -p "Enable SysRq key? [y/N] " response
        if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
        then
            echo "# Enable SysRq key combinations" >> 90-override.conf.tmp
            echo "kernel.sysrq=1" >> 90-override.conf.tmp
            echo "" >> 90-override.conf.tmp
        else
            :
        fi

        read -r -p "Change vm.swappiness to optimum value? [y/N] " response
        if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
        then
            memf=$(awk '/MemTotal/ { printf "%.3f \n", $2/1024 }' /proc/meminfo)
            mem=${memf/.*} ## convert float to int
            if [[ $mem -le 512 ]];
            then
                swappiness_opt=70
            elif [[ $mem -gt 512 && $mem -le 2048 ]];
            then
                swappiness_opt=60
            elif [[ $mem -gt 2048 && $mem -le 4096 ]];
            then
                swappiness_opt=45
            elif [[ $mem -gt 4096 && $mem -le 8192 ]];
            then
                swappiness_opt=20
            else
                swappiness_opt=10
            fi
            echo "# Aggressiveness of swapping [Higher means more swappy]" >> 90-override.conf.tmp
            echo "vm.swappiness = $swappiness_opt" >> 90-override.conf.tmp
            echo "" >> 90-override.conf.tmp
        else
            :
        fi

        read -r -p "Change IO schedulers to optimal ones? [y/N] " response
        if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
        then
            FILE=/etc/udev/rules.d/60-ioschedulers.rules
            if test -f "$FILE"; then
                echo "$FILE already exists. Rewrite? [y/N]" response2
                if [[ "$response2" =~ ^([yY][eE][sS]|[yY])$ ]]
                then
                    WriteSchedConfig
                fi
            else
                WriteSchedConfig
            fi
            echo "# IO schedulers cfg is located at /etc/udev/rules.d/60-ioschedulers.rules " >> 90-override.conf.tmp
            echo "" >> 90-override.conf.tmp
        else
            :
        fi

        echo
        cat 90-override.conf.tmp
        read -r -p "Are these options correct? [y/N] " response
        if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
        then
            current_date=$(date)
            echo "# Created at $current_date" >> 90-override.conf.tmp
            cp 90-override.conf.tmp /etc/sysctl.d/90-override.conf
            rm 90-override.conf.tmp
        else
            rm 90-override.conf.tmp
        fi
        ;;
esac
