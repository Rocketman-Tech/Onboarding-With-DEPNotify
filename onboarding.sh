#!/bin/bash

: HEADER = <<'EOL'

██████╗  ██████╗  ██████╗██╗  ██╗███████╗████████╗███╗   ███╗ █████╗ ███╗   ██╗
██╔══██╗██╔═══██╗██╔════╝██║ ██╔╝██╔════╝╚══██╔══╝████╗ ████║██╔══██╗████╗  ██║
██████╔╝██║   ██║██║     █████╔╝ █████╗     ██║   ██╔████╔██║███████║██╔██╗ ██║
██╔══██╗██║   ██║██║     ██╔═██╗ ██╔══╝     ██║   ██║╚██╔╝██║██╔══██║██║╚██╗██║
██║  ██║╚██████╔╝╚██████╗██║  ██╗███████╗   ██║   ██║ ╚═╝ ██║██║  ██║██║ ╚████║
╚═╝  ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝╚══════╝   ╚═╝   ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝

        Name: Onboarding with DEPNotify
 Description: Provides a user-facing onboarding walkthrough for DEPNotify
  Created By: Chad Lawson
     License: Copyright (c) 2022, Rocketman Management LLC. All rights reserved. Distributed under MIT License.
   More Info: For Documentation, Instructions and Latest Version, visit https://www.rocketman.tech/jamf-toolkit
  Parameters: $1-$3 - Reserved by Jamf (Mount Point, Computer Name, Username)
                 $4 - API Encoded String (Username:Password). Only needed if pulling buildings and departments from Jamf Pro
                 $5 - Options for DEPNotify (see code)
                 $6 - Main Title Starting Text (optional)
                 $7 - Path to icon (optional)
                 $8 - Window Title (not normally visible, optional)

EOL

##
## Parameters and Variables
##

APIHASH="$4" ## Base64 hash for username/password. Created in Terminal using "echo -n 'username:password' | base64 | pbcopy"
DNOPTS="$5" ## Options to pass to DEPNotify
## Most common options:
##
## -fullScreen
## This flag will create a full screen behind the DEPNotify screen to focus the
## user on the task at hand. By default, DEPNotify launches as a window that
## can be moved by the end user. Additionally, command-control-x will quit
## DEPNotify, although this can be modified via the DEPNotify configuration.
##
## -jamf
## This has DEP Notify read in the Jamf log at /var/log/jamf.log and then
## update the status line in the DEP Notify window with any installations or
## policy executions from the Jamf log. Note there is nothing special you need
## to name your items in Jamf for them to be read.
##
## See more at: https://gitlab.com/Mactroll/DEPNotify#application-flags
MAINTITLE="$6" ## Initial title - defaults to "Welcome to your new Mac!"
LOGOFILE="$7" ## Full path to logo - must be previously deployed to work
WINDOWTITLE="$8" ## Title of window - not normally visiable to users


##
## System Variables
##

JAMFURL=$( defaults read /Library/Preferences/com.jamfsoftware.jamf.plist jss_url )
USERNAME=$( scutil <<< "show State:/Users/ConsoleUser" | awk -F': ' '/[[:space:]]+Name[[:space:]]:/ { if ( $2 != "loginwindow" ) { print $2 }}' )
USERID=$( id -u $USERNAME )


##
## Functions to call in the script
##

function coffee {

	## Disable sleep for duration of run
	caffeinate -d -i -m -u &
	caffeinatepid=$!
}

function pauseJamfFramework {

	## Update Jamf frameworks
	jamf manage

	## Disable Jamf Check-Ins
	jamftasks=($( find /Library/LaunchDaemons -iname "*task*" -type f -maxdepth 1 ))
	for ((i=0;i<${#jamftasks[@]};i++))
	do
		launchctl unload -w "${jamftasks[$i]}"
	done

	## Kill any check-in in progress
	jamfpid=$( ps -ax | grep "jamf policy -randomDelaySeconds" | grep -v "grep" | awk '{ print $1 }' )
	if [ "$jamfpid" != "" ];
	then
		kill -9 "$jamfpid"
	fi
}

function waitForUser {

	## Check to see if we're in a user context or not. Wait if not.
	dockStatus=$( pgrep -x Dock )
	while [[ "$dockStatus" == "" ]]; do
		sleep 1
		dockStatus=$( pgrep -x Dock )
	done
}

function startDEPNotify {

	## Create the depnotify log file
	touch /var/tmp/depnotify.log
	chmod 777 /var/tmp/depnotify.log

	## Set up the initial DEP Notify window
	echo "Command: Image: ${LOGOFILE}" >> /var/tmp/depnotify.log
	echo "Command: WindowTitle: ${WINDOWTITLE}" >> /var/tmp/depnotify.log
	echo "Command: MainTitle: ${MAINTITLE}" >> /var/tmp/depnotify.log
	echo "Status: Initial Setup" >> /var/tmp/depnotify.log

	## Load DEP Notify
	deploc=$( find /Applications -maxdepth 2 -type d -iname "*DEP*.app" )
	launchctl asuser $USERID "$deploc/Contents/MacOS/DEPNotify" ${DNOPTS} 2>/dev/null &
	deppid=$!
}

function cleanUp {

	## Re-enable Jamf management
	for ((i=0;i<${#jamftasks[@]};i++))
	do
		launchctl load -w "${jamftasks[$i]}"
	done

	## Quit DEPNotify
	echo "Command: Quit" >> /var/tmp/depnotify.log
	rm -rf "$deploc" ## Deletes the DEPNotify.app

	## Delete temp files
	rm /var/tmp/depnotify.log
	defaults delete menu.nomad.DEPNotify

	## Disable Caffeine
	kill "$caffeinatepid"
}

function DEPNotify {

	local NotifyCommand=$1
	echo "$NotifyCommand" >> /var/tmp/depnotify.log
}

function jamfCommand {

	local jamfTrigger=$1

	if [[ $jamfTrigger == "recon" ]]; then
		jamf recon
	elif [[ $jamfTrigger == "policy" ]]; then
		jamf policy
	else
		jamf policy -event $jamfTrigger
	fi
}

function selectBuildingDepartment {

  ## Get the departments from the API
	DEPTS=$(curl -sk -H "Authorization: Basic ${APIHASH}" "${JAMFURL}/JSSResource/departments" -H "accept: application/xml" | xmllint  --format - | awk -F '[<>]' '/<name>/{printf "\"%s\" ", $3}')

	## Get the building from the API
	BLDGS=$(curl -sk -H "Authorization: Basic ${APIHASH}" "${JAMFURL}/JSSResource/buildings" -H "accept: application/xml" | xmllint  --format - | awk -F '[<>]' '/<name>/{printf "\"%s\" ", $3}')

	## Prepare DEPNotify to get the registration information
	defaults write menu.nomad.DEPNotify pathToPlistFile "/var/tmp/registration.plist"
	defaults write menu.nomad.DEPNotify registrationMainTitle "Please select your Building and Department."
	defaults write menu.nomad.DEPNotify registrationButtonLabel "Done"
	defaults write menu.nomad.DEPNotify	popupButton1Label "Building"
	defaults write menu.nomad.DEPNotify popupButton1Content -array ${BLDGS}
  defaults write menu.nomad.DEPNotify	popupButton2Label "Department"
	defaults write menu.nomad.DEPNotify popupButton2Content -array ${DEPTS}
  if [ $LOGOFILE ];then
		defaults write menu.nomad.DEPNotify	registrationPicturePath "$LOGOFILE"
	fi

  ## Creating the Regnistration Button
  echo "Status: Please click the button to choose your building and department." >> /var/tmp/depnotify.log
  echo "Command: ContinueButtonRegister: Select" >> /var/tmp/depnotify.log

	## Wait until a selection is made
	while [ ! -f /var/tmp/com.depnotify.registration.done ]; do
		sleep 1
	done
	/bin/rm /var/tmp/com.depnotify.registration.done

    ## Get the department from the plist
	DEPT=$(defaults read /var/tmp/registration.plist Department)

	## Get the department from the plist
	BLDG=$(defaults read /var/tmp/registration.plist Building)

	## Send the building and department selection back to Jamf
	echo "Status: Getting departmental configuration..." >> /var/tmp/depnotify.log
	jamf recon -department "${DEPT}" -building "${BLDG}"
}


##
## Main Script
##

## These next four lines execute functions above
coffee				## Uses 'caffeinate' to disable sleep and stores the PID for later
pauseJamfFramework 		## Disables recurring Jamf check-ins to prevent overlaps
waitForUser 			## Blocking loop; Waits until DEP is complete and user is logged in
startDEPNotify 			## Initial setup and execution of DEPNotify as user

##
## YOUR STUFF GOES HERE
##

## At the bare minimum, you need to call "jamf policy" to kick off the policies,
## and DEPNotify will display Jamf's logs at the bottom.

## For more info and examples, look at the DEPNotify Exmaples.sh

selectBuildingDepartment
jamfCommand policy

###         ###
### Cleanup ###
###         ###
cleanUp ## Quits application, deletes temporary files, and resumes normal operation
