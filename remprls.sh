#!/bin/bash
program=`basename $0`
version="3.1.0"

#
# Mac OS X Parallels Removal Script v3.1.0
#
# Copyright (c) 2013-2014 Danijel James
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
# the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#
# Copyright (C) 2007-2013 Oracle Corporation
#
# Portions of this file are part of VirtualBox Open Source Edition (OSE), 
# as available from http://www.virtualbox.org. This file is free software;
# you can redistribute it and/or modify it under the terms of the GNU
# General Public License (GPL) as published by the Free Software
# Foundation, in version 2 as it comes in the "COPYING" file of the
# VirtualBox OSE distribution. VirtualBox OSE is distributed in the
# hope that it will be useful, but WITHOUT ANY WARRANTY of any kind.
#

# Override $PATH directory to prevent issues
export PATH="/bin:/usr/bin:/sbin:/usr/sbin:$PATH"

# Test sudo and rm are available to the user
test -x /usr/bin/sudo || echo "warning: Cannot find /usr/bin/sudo or it's not an executable." || exit 0
test -x /bin/rm || echo "warning: Cannot find /bin/rm or it's not an executable" || exit 0

#
# Welcome message
#
echo ""
echo "Mac OS X Remove Parallels Script v$version"
echo ""

#
# New menu layout
#
the_default_prompt=0
if test "$#" != "0"; then
    if test "$#" != "1" -o "$1" != "-s"; then
        echo "Error: Unknown argument(s): $*"
        echo ""
        echo "Usage: $program [-s]"
        echo ""
        echo "If the '-s' option is not given, the script
        echo "will not save a copy of your license file."
        echo ""
        exit 4;
    fi
fi


#
# Display the sudo usage instructions and execute validation
#
echo "The uninstallation processes requires administrative privileges"
echo "because some of the installed files cannot be removed by a normal"
echo "user. You may be prompted for your password now..."
echo ""
sleep 5
/usr/bin/sudo -p "Please enter %u's password:"

#
# Display the files and directories that will be removed
# and get the user's consent before continuing.
#
if test -n "${my_files[*]}"  -o  -n "${my_directories[*]}"; then
    echo "The following files and directories (bundles) will be removed:"
    for file in "${my_files[@]}";       do echo "    $file"; done
    for dir  in "${my_directories[@]}"; do echo "    $dir"; done
    echo ""
fi


#
# Stop Parallels if running and unload Kernel Extensions
#
echo ""
echo "Stopping Parallels"
echo ""
sleep 5
for pid in $(ps aux | grep "Parallels*" | awk '{print $2}'); do kill -HUP $pid; done
echo "Unloading Kernel Extensions"
sleep 5
for kext in $(kextstat | grep parallels | awk '{print $6}'); do kextunload $kext; done


# remove User Library data
remULibrary() {
echo "Removing User Library Data"
sleep 5
sudo rm -rf $HOME/Library/Preferences/com.parallels.
sudo rm -rf $HOME/Library/Preferences/Parallels/
sudo rm -rf $HOME/Library/Preferences/Parallels
sudo rm -rf $HOME/Library/Preferences/parallels/
sudo rm -rf $HOME/Library/Preferences/parallels
sudo rm -rf $HOME/Library/Parallels/
sudo rm -rf $HOME/Library/Logs/Parallels
sudo rm -rf $HOME/Library/Logs/parallels
sudo rm -rf $HOME/Library/Saved\ Application\ State/com.parallels.*/
sudo rm -rf $HOME/Library/Saved\ Application\ State/com.parallels.
}

# remove System Library Data
remSLibrary() {
echo "Removing System Library Data"
sleep 5
sudo rm -rf /Library/Logs/parallels*
sudo rm -rf /Library/Logs/Parallels*
sudo rm -rf /Library/logs/parallels.log
sudo rm -rf /Library/Preferences/com.parallels*
sudo rm -rf /Library/Preferences/Parallels/*
sudo rm -rf /Library/Preferences/Parallels
}

# remove Core Application Data
remCoreData() {
echo "Removing Core Application Data"
sleep 5
sudo rm -rf /private/var/db/parallels/stats/* sudo rm -rf /private/var/db/Parallels/stats/*
sudo rm -rf /private/var/db/parallels/stats
sudo rm -rf /private/var/db/Parallels/stats
sudo rm -rf /private/var/db/parallels
sudo rm -rf /private/var/.parallels_swap
sudo rm -rf /private/var/.Parallels_swap
sudo rm -rf /private/var/db/receipts/'com.parallels*'
sudo rm -rf /private/var/root/library/preferences/com.parallels.desktop.plist
sudo rm -rf /private/tmp/qtsingleapp-*-lockfile
sudo rm -rf /private/tmp/com.apple.installer*/*
sudo rm -rf /private/tmp/com.apple.installer*
sudo rm -rf /System/Library/Extensions/prl*
}

advRestart() {
echo "It is advised you restart your system"
echo "to complete the removal process..."
sleep 5
}

args=
for arg in $*; do
    case $arg in
	-r)
		sudo -v
		stopPrls
		sudo rm /Library/Preferences/Parallels/licenses.xml
	    remULibrary
		remSLibrary
		remCoreData
		advRestart
	    exit 0
	    ;;
	-s)
		sudo -v
		stopPrls
		if [ -f /Library/Preferences/Parallels/licenses.xml ]; then
			echo "Saving Parallels License to Desktop"
			sleep 5
			mkdir -p $HOME/Desktop/SavedPrlsLicense
			/usr/bin/printf "The License for Parallels is called license.xml\n\nThis file has been saved to this directory. You will be required\nto replace this file if you install Parallels onto a new system,\nor this system again.\n\nPlease consult with Parallels for further information." >> $HOME/Desktop/SavedPrlsLicense/ReadMe.txt
			sudo cp /Library/Preferences/Parallels/licenses.xml $HOME/Desktop/SavedPrlsLicense/
			sudo rm -f /Library/Preferences/Parallels/licenses.xml
		fi
		remULibrary
		remSLibrary
		remCoreData
		advRestart
		exit 0
		;;
	--help|-h)
        showHelp
	    exit 0
	    ;;
	*|-*)
	    echo "$program: $arg: unknown option"
	    exit 1
	    ;;
    esac
done


if test "$my_rc" -eq 0; then
    echo "Successfully unloaded VirtualBox kernel extensions."
else

echo "Done."
exit 0;