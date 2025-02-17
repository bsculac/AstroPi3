#!/bin/bash

#	AstroPi3 Raspberry Pi 3 Ubuntu-Mate KStars/INDI Configuration Script
#﻿  Copyright (C) 2018 Robert Lancaster <rlancaste@gmail.com>
#	This script is free software; you can redistribute it and/or
#	modify it under the terms of the GNU General Public
#	License as published by the Free Software Foundation; either
#	version 2 of the License, or (at your option) any later version.

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

function display
{
    echo ""
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo "~ $*"
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo ""
    
    # This will display the message in the title bar (Note that the PS1 variable needs to be changed too--see below)
    echo -en "\033]0;AstroPi3-SetupAstroPi3-$*\a"
}

display "Welcome to the AstroPi3 Raspberry Pi 3 Ubuntu-Mate KStars/INDI Configuration Script."

display "This will update, install and configure your Raspberry Pi 3 to work with INDI and KStars to be a hub for Astrophotography. Be sure to read the script first to see what it does and to customize it."

if [ "$(whoami)" != "root" ]; then
	display "Please run this script with sudo due to the fact that it must do a number of sudo tasks.  Exiting now."
	exit 1
fi

read -p "Are you ready to proceed (y/n)? " proceed

if [ "$proceed" != "y" ]
then
	exit
fi

export USERHOME=$(sudo -u $SUDO_USER -H bash -c 'echo $HOME')

# This changes the UserPrompt for the Setup Script (Necessary to make the messages display in the title bar)
PS1='AstroPi3-SetupAstroPi3~$ '

#########################################################
#############  Updates

# This would update the Raspberry Pi kernel.  For now it is disabled because there is debate about whether to do it or not.  To enable it, take away the # sign.
#display "Updating Kernel"
#sudo rpi-update 

# This will set Firefox to a known working version of Firefox and prevent any update.
# This fix was necessary on 16.04 because updating firefox would break it.
#read -p "Do you want to set Firefox to a known working version and prevent a Firefox update (y/n)? " preventUpdateFirefox
#if [ "$preventUpdateFirefox" == "y" ]
#then
#	wget http://ports.ubuntu.com/pool/main/f/firefox/firefox_52.0.2+build1-0ubuntu0.12.04.1_armhf.deb
#	sudo apt -y purge firefox
#	sudo dpkg -i firefox_52.0.2+build1-0ubuntu0.12.04.1_armhf.deb
#	sudo apt-mark hold firefox
#	rm firefox_52.0.2+build1-0ubuntu0.12.04.1_armhf.deb
#fi

# This uninstalls the upgrades package because it prevents us from updating the system until it is done
# It seems like a good idea, but I wouldn't want it doing that when doing astrophotography and when
# I want to update or upgrade the system, I have to wait for it to stop in order to begin.
sudo apt -y remove unattended-upgrades

# This prevents an update issue currently in the Raspberry Pi 3b+ where this package doesn't update correctly. (8/2/19)
# Hopefully this fix is temporary.
sudo apt-mark hold linux-firmware-raspi2

# Updates the Raspberry Pi to the latest packages.
display "Updating installed packages"
sudo apt update
sudo apt -y upgrade
sudo apt -y dist-upgrade

#########################################################
#############  Configuration for Ease of Use/Access

# This makes sure there is a config folder owned by the user, since many things depend on it.
mkdir -p $USERHOME/.config
sudo chown $SUDO_USER $USERHOME/.config

# This will set your account to autologin.  If you don't want this. then put a # on each line to comment it out.
display "Setting account: "$SUDO_USER" to auto login."
##################
sudo cat > /usr/share/lightdm/lightdm.conf.d/60-lightdm-gtk-greeter.conf <<- EOF
[SeatDefaults]
greeter-session=lightdm-gtk-greeter
autologin-user=$SUDO_USER
EOF
##################

display "Setting HDMI settings in /boot/config.txt."

# Note that for these settings, /boot/config.txt might actually be /boot/firmware/config.txt
# So we will change it in both places just in case.

# This pretends an HDMI display is connected at all times, otherwise, the pi might shut off HDMI
# So that when you go to plug in an HDMI connector to diagnose a problem, it doesn't work
# This makes the HDMI output always available
if [ -n "$(grep '#hdmi_force_hotplug=1' '/boot/config.txt')" ]
then
	sed -i "s/#hdmi_force_hotplug=1/hdmi_force_hotplug=1/g" /boot/config.txt
fi
if [ -n "$(grep '#hdmi_force_hotplug=1' '/boot/firmware/config.txt')" ]
then
	sed -i "s/#hdmi_force_hotplug=1/hdmi_force_hotplug=1/g" /boot/firmware/config.txt
fi

# This sets the group for the HDMI mode.  Please see the config file for details about all the different modes
# There are many options.  I selected group 1 mode 46 because that matches my laptop's resolution.
# You might want a different mode and group if you want a certain resolution in VNC
if [ -n "$(grep '#hdmi_group=1' '/boot/config.txt')" ]
then
	sed -i "s/#hdmi_group=1/hdmi_group=2/g" /boot/config.txt
fi
if [ -n "$(grep '#hdmi_group=1' '/boot/firmware/config.txt')" ]
then
	sed -i "s/#hdmi_group=1/hdmi_group=2/g" /boot/firmware/config.txt
fi

# This sets the HDMI mode.  Please see the config file for details about all the different modes
# There are many options.  I selected group 1 mode 46 because that matches my laptop's resolution.
# You might want a different mode and group if you want a certain resolution in VNC
if [ -n "$(grep '#hdmi_mode=1' '/boot/config.txt')" ]
then
	sed -i "s/#hdmi_mode=1/hdmi_mode=46/g" /boot/config.txt
fi
if [ -n "$(grep '#hdmi_mode=1' '/boot/firmware/config.txt')" ]
then
	sed -i "s/#hdmi_mode=1/hdmi_mode=46/g" /boot/firmware/config.txt
fi

# This will prevent the raspberry pi from turning on the lock-screen / screensaver which can be problematic when using VNC
gsettings set org.gnome.desktop.session idle-delay 0
gsettings set org.mate.screensaver lock-enabled false

# This will disable Parallel printer port CUPS modules that don't exist on the raspberry pi
# This was added because the raspberry pi often says "Failed to start load kernel modules" on startup
# Without this change, startup can take 1 to 2 extra minutes.
display "Disabling CUPS Kernel Modules that don't exist on the raspberry pi for faster startup."
##################
sudo cat > /etc/modules-load.d/cups-filters.conf <<- EOF
# Parallel printer driver modules loading for cups
# LOAD_LP_MODULE was 'yes' in /etc/default/cups
#lp
#ppdev
#parport_pc
EOF
##################

# Installs Synaptic Package Manager for easy software install/removal
display "Installing Synaptic"
sudo apt -y install synaptic

# This will enable SSH which is apparently disabled on Raspberry Pi by default.
display "Enabling SSH"
sudo apt -y install openssh-server
sudo systemctl enable ssh
sudo systemctl start ssh

# This will set up your Pi to have access to internet with wifi, ethernet with DHCP, and ethernet with direct connection
display "Setting up Ethernet for both link-local and DHCP"
if [ -z "$(ls /etc/NetworkManager/system-connections/ | grep Link\ Local\ Ethernet)" ]
then
	read -p "Do you want to give your pi a static ip address so that you can connect to it in the observing field with no router or wifi and just an ethernet cable (y/n)? " useStaticIP
	if [ "$useStaticIP" == "y" ]
	then
		read -p "Please enter the IP address you would prefer.  Please make sure that the first two numbers match your client computer's self assigned IP.  For Example mine is: 169.254.0.5 ? " IP
		if [[ "$IP" =~ ^(([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))\.){3}([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))$ ]] # Note that this formula came from Jon in the thread: https://stackoverflow.com/questions/13777387/check-for-ip-validity
		then
			echo "IP Address is in correct format, proceeding"
			
			# This will make sure that network manager can manage whether the ethernet connection is on or off and then you can change the connection in network maanager.
			if [ -n "$(grep 'managed=false' /etc/NetworkManager/NetworkManager.conf)" ]
			then
				sed -i "s/managed=false/managed=true/g" /etc/NetworkManager/NetworkManager.conf
			fi
	
			# This section should add two connections, one for connecting to ethernet with a router and the other for connecting directly to a computer in the observing field with a Link Local IP
			nmcli connection add type ethernet ifname eth0 con-name "Wired DHCP Ethernet" autoconnect yes
			nmcli connection modify "Wired DHCP Ethernet" connection.autoconnect-priority 2 	# Higher Priority because then it tries DHCP first and then switches to Link Local as a backup
			nmcli connection modify "Wired DHCP Ethernet" ipv4.dhcp-timeout 5 					# This sets the timeout for DHCP to a much shorter time so you don't have to wait forever for Link Local
			nmcli connection modify "Wired DHCP Ethernet" ipv4.may-fail no 						# I'm not sure why this is needed, but without it, it doesn't seem to want to switch to link local
			nmcli connection modify "Wired DHCP Ethernet" connection.autoconnect-retries 2		# These last two might not be necessary, but they might be needed if the global settings are to infinitely retry
			nmcli connection modify "Wired DHCP Ethernet" connection.auth-retries 2
	
			nmcli connection add type ethernet ifname eth0 con-name "Link Local Ethernet" autoconnect yes ip4 $IP/24
			nmcli connection modify "Link Local Ethernet" connection.autoconnect-priority 1		# Lower priority because this is the backup for when in the observing field
	
# This will make sure /etc/network/interfaces does not interfere
##################
sudo cat > /etc/network/interfaces <<- EOF
# interfaces(5) file used by ifup(8) and ifdown(8)
# Include files from /etc/network/interfaces.d:
source-directory /etc/network/interfaces.d

# The loopback network interface
auto lo
iface lo inet loopback
EOF
##################

		else
			echo "IP Address invalid, the static IP will not be set up.  Please configure Network Manager later or run the script again."
		fi
	else
		display "Leaving your IP address to be assigned only by dhcp.  Note that you will always need either a router or wifi network to connect to your pi."
	fi
else
	display "This computer already has been assigned a static ip address.  If you need to edit that, please edit the Link Local and Wired DHCP connections in Network Manager or delete them and run the script again."
fi

# To view the Raspberry Pi Remotely, this installs RealVNC Servier and enables it to run by default.
display "Installing RealVNC Server"

if [ -z "$(dpkg -l | grep realvnc-vnc-server)" ]
then
	architecture=$(dpkg --print-architecture)
	display "Your architechture is $architecture, attempting to install RealVNC for that version"
	cd ~/
	if [ $architecture == "arm64" ]
	then
		wget https://archive.raspberrypi.org/debian/pool/main/r/realvnc-vnc/realvnc-vnc-server_6.7.2.43081_arm64.deb -O VNC.deb
		cd /usr/lib/aarch64-linux-gnu
		sudo ln libvcos.so /usr/lib/libvcos.so.0
		sudo ln libvchiq_arm.so /usr/lib/libvchiq_arm.so.0
		sudo ln libbcm_host.so /usr/lib/libbcm_host.so.0
		cd ~/
	else
		wget https://www.realvnc.com/download/binary/latest/debian/arm/ -O VNC.deb
	fi
	sudo dpkg -i VNC.deb
	rm VNC.deb
else
	echo "RealVNC is already installed"
fi
sudo systemctl enable vncserver-x11-serviced.service
sudo systemctl enable vncserver-virtuald.service
sudo systemctl start vncserver-x11-serviced.service
sudo systemctl start vncserver-virtuald.service

display "Making Utilities Folder with script shortcuts for the Desktop"

# This will make a folder on the desktop for the launchers if it doesn't exist already
if [ ! -d "$USERHOME/Desktop/utilities" ]
then
	mkdir -p $USERHOME/Desktop/utilities
	sudo chown $SUDO_USER $USERHOME/Desktop/utilities
fi

# This will create a shortcut on the desktop in the utilities folder for creating udev rules for Serial Devices.
##################
sudo cat > $USERHOME/Desktop/utilities/SerialDevices.desktop <<- EOF
#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=true
Icon[en_US]=plip
Exec=sudo $(echo $DIR)/udevRuleScript.sh
Name[en_US]=Create Rule for Serial Device
Name=Create Rule for Serial Device
Icon=$(echo $DIR)/icons/plip.png
EOF
##################
sudo chmod +x $USERHOME/Desktop/utilities/SerialDevices.desktop
sudo chown $SUDO_USER $USERHOME/Desktop/utilities/SerialDevices.desktop

# This will create a shortcut on the desktop in the utilities folder for Installing Astrometry Index Files.
##################
sudo cat > $USERHOME/Desktop/utilities/InstallAstrometryIndexFiles.desktop <<- EOF
#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=true
Icon[en_US]=mate-preferences-desktop-display
Exec=sudo $(echo $DIR)/astrometryIndexInstaller.sh
Name[en_US]=Install Astrometry Index Files
Name=Install Astrometry Index Files
Icon=$(echo $DIR)/icons/mate-preferences-desktop-display.svg
EOF
##################
sudo chmod +x $USERHOME/Desktop/utilities/InstallAstrometryIndexFiles.desktop
sudo chown $SUDO_USER $USERHOME/Desktop/utilities/InstallAstrometryIndexFiles.desktop

# This will create a shortcut on the desktop in the utilities folder for Updating the System.
##################
sudo cat > $USERHOME/Desktop/utilities/systemUpdater.desktop <<- EOF
#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=true
Icon[en_US]=system-software-update
Exec=sudo $(echo $DIR)/systemUpdater.sh
Name[en_US]=Software Update
Name=Software Update
Icon=$(echo $DIR)/icons/system-software-update.svg
EOF
##################
sudo chmod +x $USERHOME/Desktop/utilities/systemUpdater.desktop
sudo chown $SUDO_USER $USERHOME/Desktop/utilities/systemUpdater.desktop

# This will create a shortcut on the desktop in the utilities folder for Backing Up and Restoring the KStars/INDI Files.
##################
sudo cat > $USERHOME/Desktop/utilities/backupOrRestore.desktop <<- EOF
#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Icon[en_US]=system-upgrade
Exec=mate-terminal -e '$(echo $DIR)/backupOrRestore.sh'
Name[en_US]=Backup or Restore
Name=Backup or Restore
Icon=$(echo $DIR)/icons/system-upgrade.svg
EOF
##################
sudo chmod +x $USERHOME/Desktop/utilities/backupOrRestore.desktop
sudo chown $SUDO_USER $USERHOME/Desktop/utilities/backupOrRestore.desktop

#########################################################
#############  Configuration for Hotspot Wifi for Connecting on the Observing Field

# This will fix a problem where AdHoc and Hotspot Networks Shut down very shortly after starting them
# Apparently it was due to power management of the wifi network by Network Manager.
# If Network Manager did not detect internet, it shut down the connections to save energy. 
# If you want to leave wifi power management enabled, put #'s in front of this section
display "Preventing Wifi Power Management from shutting down AdHoc and Hotspot Networks"
##################
sudo cat > /etc/NetworkManager/conf.d/default-wifi-powersave-on.conf <<- EOF
[connection]
wifi.powersave = 2
EOF
##################

# This will create a NetworkManager Wifi Hotspot File.  
# You can edit this file to match your settings now or after the script runs in Network Manager.
# If you prefer to set this up yourself, you can comment out this section with #'s.
# If you want the hotspot to start up by default you should set autoconnect to true.
display "Creating $(hostname -s)_FieldWifi, Hotspot Wifi for the observing field"
if [ -z "$(ls /etc/NetworkManager/system-connections/ | grep $(hostname -s)_FieldWifi)" ]
then

	nmcli connection add type wifi ifname '*' con-name $(hostname -s)_FieldWifi autoconnect no ssid $(hostname -s)_FieldWifi
	nmcli connection modify $(hostname -s)_FieldWifi 802-11-wireless.mode ap 802-11-wireless.band bg ipv4.method shared
	nmcli connection modify $(hostname -s)_FieldWifi 802-11-wireless-security.key-mgmt wpa-psk 802-11-wireless-security.psk $(hostname -s)_password

	nmcli connection add type wifi ifname '*' con-name $(hostname -s)_FieldWifi_5G autoconnect no ssid $(hostname -s)_FieldWifi_5G
	nmcli connection modify $(hostname -s)_FieldWifi_5G 802-11-wireless.mode ap 802-11-wireless.band a ipv4.method shared
	nmcli connection modify $(hostname -s)_FieldWifi_5G 802-11-wireless-security.key-mgmt wpa-psk 802-11-wireless-security.psk $(hostname -s)_password
else
	echo "$(hostname -s)_FieldWifi is already setup."
fi

# This section will set the new field wifi networks to autoconnect if the other networks don't connect.
display "Configuring Field wifi to autoconnect after wifi fails"
if [ -f /etc/NetworkManager/conf.d/wifi-enable-autohotspot.conf ]
then
	echo "Field Wifi autoconnection is already configured, if you want to change it, edit network manager and /etc/NetworkManager/conf.d/wifi-enable-autohotspot.conf"
else
	read -p "Do you wish to configure the field wifi hotspot to automatically come up after a certain time if there is no wifi network (y/n)? " autoWifi

	if [ "$autoWifi" == "y" ]
	then
		read -p "What do you want the timeout to be?  Mine is 30 seconds: " wifiTimeout
		if ! [ "$wifiTimeout" -eq "$wifiTimeout" ] 2> /dev/null
		then
   			echo "The timeout must be an integer number of seconds.  Making it 30 instead.  You can edit /etc/NetworkManager/conf.d/wifi-enable-autohotspot.conf to change it."
   			wifiTimeout=30
		fi
		# This sets both wifi networks to autoconnect with a priority to connect on 5G if available
		nmcli connection modify $(hostname -s)_FieldWifi connection.autoconnect yes
		nmcli connection modify $(hostname -s)_FieldWifi_5G connection.autoconnect yes
		nmcli connection modify $(hostname -s)_FieldWifi connection.autoconnect-priority -10
		nmcli connection modify $(hostname -s)_FieldWifi_5G connection.autoconnect-priority -5
	
		# This configuration file will ensure that the wifi networks come up successfully in a reasonable time if the regular wifi fails.
##################
sudo --preserve-env bash -c ' cat > /etc/NetworkManager/conf.d/wifi-enable-autohotspot.conf' <<- EOF
[connection-wifi]
match-device=interface-name:wlan0
ipv4.dhcp-timeout=$wifiTimeout
ipv4.may-fail=no
connection.auth-retries=2
connection.autoconnect-retries=2
EOF
##################
	fi
fi

# This will make a link to start the hotspot wifi on the Desktop
##################
sudo cat > $USERHOME/Desktop/utilities/StartFieldWifi.desktop <<- EOF
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Icon[en_US]=irda
Name[en_US]=Start $(hostname -s) Field Wifi
Exec=nmcli con up $(hostname -s)_FieldWifi
Name=Start $(hostname -s)_FieldWifi 
Icon=$(echo $DIR)/icons/irda.png
EOF
##################
sudo chmod +x $USERHOME/Desktop/utilities/StartFieldWifi.desktop
sudo chown $SUDO_USER $USERHOME/Desktop/utilities/StartFieldWifi.desktop
##################
sudo cat > $USERHOME/Desktop/utilities/StartFieldWifi_5G.desktop <<- EOF
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Icon[en_US]=irda
Name[en_US]=Start $(hostname -s) Field Wifi 5G
Exec=nmcli con up $(hostname -s)_FieldWifi_5G
Name=Start $(hostname -s)_FieldWifi_5G
Icon=$(echo $DIR)/icons/irda.png
EOF
##################
sudo chmod +x $USERHOME/Desktop/utilities/StartFieldWifi_5G.desktop
sudo chown $SUDO_USER $USERHOME/Desktop/utilities/StartFieldWifi_5G.desktop

# This will make a link to restart Network Manager Service if there is a problem or to go back to regular wifi after using the adhoc connection
##################
sudo cat > $USERHOME/Desktop/utilities/StartNmService.desktop <<- EOF
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Icon[en_US]=preferences-system-network
Name[en_US]=Restart Network Manager Service
Exec=pkexec systemctl restart NetworkManager.service
Name=Restart Network Manager Service
Icon=$(echo $DIR)/icons/preferences-system-network.svg
EOF
##################
sudo chmod +x $USERHOME/Desktop/utilities/StartNmService.desktop
sudo chown $SUDO_USER $USERHOME/Desktop/utilities/StartNmService.desktop

# This will make a link to restart nm-applet which sometimes crashes
##################
sudo cat > $USERHOME/Desktop/utilities/StartNmApplet.desktop <<- EOF
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Icon[en_US]=preferences-system-network
Name[en_US]=Restart Network Manager Applet
Exec=nm-applet
Name=Restart Network Manager
Icon=$(echo $DIR)/icons/preferences-system-network.svg
EOF
##################
sudo chmod +x $USERHOME/Desktop/utilities/StartNmApplet.desktop
sudo chown $SUDO_USER $USERHOME/Desktop/utilities/StartNmApplet.desktop

# This will support the functions of the next two shortcuts.
display "Setting up Night Vision tools"
sudo apt -y install xcalib

# This will create a link that will turn the screen red to preserve night vision
##################
sudo cat > $USERHOME/Desktop/utilities/NightVisionMode.desktop <<- EOF
[Desktop Entry]
Version=1.0
Type=Application
Terminal=true
Icon[en_US]=redeyes
Exec=xcalib -red 1 0 100 -green .1 0 1 -blue .1 0 1 -alter
Name[en_US]=Night Vision Mode
Name=Night Vision Mode
Icon=$(echo $DIR)/icons/redeyes.svg
EOF
##################
sudo chmod +x $USERHOME/Desktop/utilities/NightVisionMode.desktop
sudo chown $SUDO_USER $USERHOME/Desktop/utilities/NightVisionMode.desktop

# This will create a link that will turn the screen back to normal
##################
sudo cat > $USERHOME/Desktop/utilities/NormalVisionMode.desktop <<- EOF
[Desktop Entry]
Version=1.0
Type=Application
Terminal=true
Icon[en_US]=redeyes
Exec=xcalib -clear
Name[en_US]=Normal Vision Mode
Name=Normal Vision Mode
Icon=$(echo $DIR)/icons/blackeyes.svg
EOF
##################
sudo chmod +x $USERHOME/Desktop/utilities/NormalVisionMode.desktop
sudo chown $SUDO_USER $USERHOME/Desktop/utilities/NormalVisionMode.desktop

#########################################################
#############  File Sharing Configuration

display "Setting up File Sharing"

# Installs samba so that you can share files to your other computer(s).
sudo apt -y install samba

# Installs caja-share so that you can easily share the folders you want.
#sudo apt -y install caja-share

# Shares the entire user folder instead (much simpler to work with)
if [ ! -f /etc/samba/smb.conf ]
then
	sudo mkdir -p /etc/samba/
##################
sudo cat > /etc/samba/smb.conf <<- EOF
[global]
   workgroup = ASTROGROUP
   server string = Samba Server
   server role = standalone server
   log file = /var/log/samba/log.%m
   max log size = 50
   dns proxy = no
[homes]
   comment = Home Directories
   browseable = no
   read only = no
   writable = yes
   valid users = $SUDO_USER
EOF
##################
fi

# Adds yourself to the user group of who can use samba, but checks first if you are already in the list
if [ -z "$(sudo pdbedit -L | grep $SUDO_USER)" ]
then
	sudo smbpasswd -a $SUDO_USER
	sudo adduser $SUDO_USER sambashare
fi

#########################################################
#############  Very Important Configuration Items

# This will create a swap file for an increased 2 GB of artificial RAM.  This is not needed on all systems, since different cameras download different size images, but if you are using a DSLR, it definitely is.
# This method is disabled in favor of the zram method below. If you prefer this method, you can re-enable it by taking out the #'s
#display "Creating SWAP Memory"
#wget https://raw.githubusercontent.com/Cretezy/Swap/master/swap.sh -O swap
#sh swap 2G
#rm swap

# This will create zram, basically a swap file saved in RAM. It will not read or write to the SD card, but instead, writes to compressed RAM.  
# This is not needed on all systems, since different cameras download different size images, and different SBC's have different RAM capacities but 
# if you are using a DSLR on a Raspberry Pi with 1GB of RAM, it definitely is needed. If you don't want this, comment it out.
display "Installing zRAM for increased RAM capacity"
sudo apt -y install zram-config

# This should fix an issue where modemmanager could interfere with serial connections
display "Removing Modemmanger, which can interfere with serial connections."
sudo apt -y remove modemmanager

# This should fix an issue where you might not be able to use a serial mount connection because you are not in the "dialout" group
display "Enabling Serial Communication"
sudo usermod -a -G dialout $SUDO_USER


#########################################################
#############  ASTRONOMY SOFTWARE

# Installs INDI, Kstars, and Ekos bleeding edge and debugging
display "Installing INDI and KStars"
sudo apt-add-repository ppa:mutlaqja/ppa -y
sudo apt update
sudo apt -y install indi-full
sudo apt -y install indi-full kstars-bleeding
sudo apt -y install kstars-bleeding-dbg indi-dbg

# Creates a config file for kde themes and icons which is missing on the Raspberry pi.
# Note:  This is required for KStars to have the breeze icons.
display "Creating KDE config file so KStars can have breeze icons."
##################
sudo cat > $USERHOME/.config/kdeglobals <<- EOF
[Icons]
Theme=breeze
EOF
##################
sudo chown $SUDO_USER $USERHOME/.config/kdeglobals

# Installs the General Star Catalog if you plan on using the simulators to test (If not, you can comment this line out with a #)
display "Installing GSC"
sudo apt -y install gsc

# Installs the Astrometry.net package for supporting offline plate solves.  If you just want the online solver, comment this out with a #.
display "Installing Astrometry.net"
sudo apt -y install astrometry.net

# Installs PHD2 if you want it.  If not, comment each line out with a #.
display "Installing PHD2"
sudo apt-add-repository ppa:pch/phd2 -y
sudo apt update
sudo apt -y install phd2

# Installs PHD2 Log viewer if you want it.  If not, comment out with a #.
display "Installing PHD2 Log Viewer"
sudo apt install phdlogview

# This will make a shortcut to PHD Log Viewer.  If you aren't installing it, be sure to remove this too.
##################
sudo cat > $USERHOME/Desktop/utilities/PHDLogViewer.desktop <<- EOF
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Icon[en_US]=phd2
Name[en_US]=PHD Log Viewer
Exec=/usr/bin/phdlogview
Name=PHD Log Viewer
Icon=phd2
EOF
##################
sudo chmod +x $USERHOME/Desktop/utilities/PHDLogViewer.desktop
sudo chown $SUDO_USER $USERHOME/Desktop/utilities/PHDLogViewer.desktop

# This will copy the desktop shortcuts into place.  If you don't want  Desktop Shortcuts, of course you can comment this out.
display "Putting shortcuts on Desktop"

sudo cp /usr/share/applications/org.kde.kstars.desktop  $USERHOME/Desktop/
sudo chmod +x $USERHOME/Desktop/org.kde.kstars.desktop
sudo chown $SUDO_USER $USERHOME/Desktop/org.kde.kstars.desktop

sudo cp /usr/share/applications/phd2.desktop  $USERHOME/Desktop/
sudo chmod +x $USERHOME/Desktop/phd2.desktop
sudo chown $SUDO_USER $USERHOME/Desktop/phd2.desktop

#########################################################
#############  INDI WEB MANAGER App

display "Installing INDI Web Manager App, indiweb, and python3"

# This will install pip3 and python along with their headers for the next steps
sudo apt -y install python3-pip
sudo apt -y install python3-dev

# Setuptools may be needed in order to install indiweb on some systems
sudo apt -y install python3-setuptools
sudo -H -u $SUDO_USER pip3 install setuptools --upgrade

# Wheel might not be installed on some systems
sudo -H -u $SUDO_USER pip3 install wheel

# This will install indiweb as the user
sudo -H -u $SUDO_USER pip3 install indiweb

#This will install the INDIWebManagerApp in the INDI PPA
sudo apt -y install indiwebmanagerapp

# This will make a link to start INDIWebManagerApp on the desktop
##################
sudo cat > $USERHOME/Desktop/INDIWebManagerApp.desktop <<- EOF
[Desktop Entry]
Encoding=UTF-8
Name=INDI Web Manager App
Type=Application
Exec=INDIWebManagerApp %U
Icon=$(sudo -H -u $SUDO_USER python3 -m site --user-site)/indiweb/views/img/indi_logo.png
Comment=Program to start and configure INDI WebManager
EOF
##################
sudo chmod +x $USERHOME/Desktop/INDIWebManagerApp.desktop
sudo chown $SUDO_USER $USERHOME/Desktop/INDIWebManagerApp.desktop
##################

#########################################################
#############  Configuration for System Monitoring

# This will set you up with conky so that you can see how your system is doing at a moment's glance
# A big thank you to novaspirit who set up this theme https://github.com/novaspirit/rpi_conky
sudo apt -y install conky-all
cp "$DIR/conkyrc" $USERHOME/.conkyrc
sudo chown $SUDO_USER $USERHOME/.conkyrc

#This should dynamically add lines to the conkyrc file based on the number of CPUs found
NUMEROFCPUS=$(grep -c ^processor /proc/cpuinfo)
for (( c=1; c<=$NUMEROFCPUS; c++ ))
do  
   CPULINE="CPU$c  \${cpu cpu$c}% \${cpubar cpu$c}"
   echo $CPULINE
   sed -i "/\${cpugraph DimGray DarkSlateGray} \$color/i $CPULINE" $USERHOME/.conkyrc
done

# This will put a link into the autostart folder so it starts at login
##################
sudo cat > /usr/share/mate/autostart/startConky.desktop <<- EOF
[Desktop Entry]
Name=StartConky
Exec=conky -db -p 20
Terminal=false
Type=Application
EOF
##################
# Note that in order to work, this link needs to stay owned by root and not be executable


#########################################################


# This will make the utility scripts in the folder executable in case the user wants to use them.
chmod +x "$DIR/udevRuleScript.sh"
chmod +x "$DIR/astrometryIndexInstaller.sh"
chmod +x "$DIR/systemUpdater.sh"
chmod +x "$DIR/backupOrRestore.sh"

display "Script Execution Complete.  Your Raspberry Pi 3 should now be ready to use for Astrophotography.  You should restart your Pi."