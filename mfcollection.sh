#!/usr/bin/env bash

################################################################################
#                             mfcollection script                              #
#                                                                              #
#    This script is designed for faster personalization and tweaking of        #
#    Archlinux-based systems.                                                  #
#    Currently implemented functions are:                                      #
#       Updating system                                                        #
#       Removing unrequired packages                                           #
#       Installing git, curl, base-devel (required for yay compiling)          #
#       Enabling SysRq key combinations                                        #
#       Changing vm.swappiness value to optimal one (depending on RAM size)    #
#       Changing IO schedulers to optimal ones (depending on drive type)       #
#                                                                              #
################################################################################


###############################################################################
# Variables                                                                   #
###############################################################################

NC='\033[0m'        # No color
BLK='\033[0;30m'    # Black
RED='\033[0;31m'    # Red
GRN='\033[0;32m'    # Green

Verbose=1     #disabled by default
Tweaking=1    #disabled by default


################################################################################
# Help: displays help                                                          #
################################################################################

Help()
{
  echo -e "This script is designed for automation of installing some necessary packages
Sudo is required for normal operation
${RED}Script should not be run as root${NC}\n
Syntax: mfcollection [-h|v|V|t]
Options:
h     Print this help.
v     Verbose mode.
V     Print script version.
t     Enable tweaking stage.\n"
}


###############################################################################
# Version: prints version info                                                #
###############################################################################

Version()
{
  echo -e "mfcollection.sh
Version a004 250622"
}


################################################################################
# InstallIfNotExist: installs multiple packages if necessary                   #
################################################################################

InstallIfNotExist()
{
  local PackageList=()
  for i in "${RequiredPackages[@]}"
  do
    if sudo pacman -Qs "$i" > /dev/null
    then
      if [[ $Verbose -eq 0 ]]
      then
        echo "$i is already installed, skipping..."
      fi
    else
      if [[ $Verbose -eq 0 ]]
      then
        echo "$i is added to queue..."
      fi
      $PackageList+=$i
    fi
  done
  if [[ $Verbose -eq 0 ]]
  then
    if ((${#PackageList[@]})); then
      sudo pacman -S $PackageList --noconfirm --noprogressbar
    else
      echo "No packages to install"
    fi
  else
    if ((${#PackageList[@]})); then
      sudo pacman -S $PackageList --noconfirm --noprogressbar > /dev/null
    fi
  fi
}


################################################################################
# WriteSchedConfig: writes optimal IO scheduler config                         #
################################################################################

WriteSchedConfig()
{
  sudo echo -e "# set scheduler for NVMe
ACTION==\"add|change\", KERNEL==\"nvme[0-9]*\", ATTR{queue/scheduler}=\"none\"
# set scheduler for eMMC and SSD
ACTION==\"add|change\", KERNEL==\"sd[a-z]|mmcblk[0-9]*\", ATTR{queue/rotational}==\"0\", ATTR{queue/scheduler}=\"bfq\"
# set scheduler for rotating disks
ACTION==\"add|change\", KERNEL==\"sd[a-z]\", ATTR{queue/rotational}==\"1\", ATTR{queue/scheduler}=\"bfq\"" | sudo tee /etc/udev/rules.d/60-ioschedulers.rules
}


################################################################################
# Main code                                                                    #
################################################################################

SHORT=h,v,V,t
LONG=help,verbose,version,tweak
OPTS=$(getopt -a -n mfcollection --options $SHORT --longoptions $LONG -- "$@")
VALID_ARGUMENTS=$#

eval set -- "$OPTS"

while [ "$1" != "--" ];
do
  case "$1" in
    -h|--help)
        Help
        exit
        ;;
    -V|--version)
        Version
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

if [[ $EUID -eq 0 ]]; then
  echo -e "${RED}This script should not be run as root!${NC}"
  exit
fi

case $Verbose in
    1) # Verbose mode is OFF
        sudo pacman -Syyu --noconfirm --noprogressbar > /dev/null
        sudo pacman -Rns $(pacman -Qdtq) --noconfirm  --noprogressbar > /dev/null
        RequiredPackages=("git" "curl" "base-devel")
        InstallIfNotExist
        cd /tmp
        git clone https://aur.archlinux.org/yay.git >> /dev/null
        sudo chown -R $USER yay > /dev/null
        cd yay
        makepkg -si --noconfirm --noprogressbar > /dev/null
        ;;
    0) # Verbose mode is ON
        echo -e "${GRN}1. Updating system${NC}"
        sudo pacman -Syyu --noconfirm --noprogressbar
        echo -e "${GRN}2. Removing unrequired packages${NC}"
        sudo pacman -Rns $(pacman -Qdtq) --noconfirm  --noprogressbar
        echo -e "${GRN}3. Installing base development tools${NC}"
        RequiredPackages=("git" "curl" "base-devel")
        InstallIfNotExist
        echo -e "${GRN}4. Installing yay${NC}"
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
            echo -e "${GRN}Skipping step 5: Tweaking disabled${NC}"
        fi
        ;;
    0) #Tweaking is enabled
        if [[ $Verbose -eq 0 ]];
        then
            echo -e "${GRN}5. Tweaking system${NC}"
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
                read -r -p "$FILE already exists. Rewrite? [y/N] " response2
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
            sudo cp 90-override.conf.tmp /etc/sysctl.d/90-override.conf
            rm 90-override.conf.tmp
        else
            rm 90-override.conf.tmp
        fi
        ;;
esac
