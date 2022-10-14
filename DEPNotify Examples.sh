: HEADER = <<'EOL'

██████╗  ██████╗  ██████╗██╗  ██╗███████╗████████╗███╗   ███╗ █████╗ ███╗   ██╗
██╔══██╗██╔═══██╗██╔════╝██║ ██╔╝██╔════╝╚══██╔══╝████╗ ████║██╔══██╗████╗  ██║
██████╔╝██║   ██║██║     █████╔╝ █████╗     ██║   ██╔████╔██║███████║██╔██╗ ██║
██╔══██╗██║   ██║██║     ██╔═██╗ ██╔══╝     ██║   ██║╚██╔╝██║██╔══██║██║╚██╗██║
██║  ██║╚██████╔╝╚██████╗██║  ██╗███████╗   ██║   ██║ ╚═╝ ██║██║  ██║██║ ╚████║
╚═╝  ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝╚══════╝   ╚═╝   ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝

        Name: Onboarding with DEPNotify - Supplemental Workflows
 Description: This is supplemental workflows and documentation that pairs with them
              onboading.sh script.
       Notes: There are two functions to help simplify your DEPNotify commands and
              calls to Jamf for other policies.

          1. DEPNotify - Appends text to /var/tmp/depnotify.log
             Example:
             DEPNotify "Command: MainText: Message goes here"
             DEPNotify "Status: Tell the user what we are doing..."

          2. jamfCommand - Simplifies calls to the jamf binary with three options
             "recon"  - Submits an inventory to udpate Smart Groups, etc.
             "policy" - Makes a normal policy check for new applicable policies
             other 		- Calls jamf policy with the passed in argument as a manual trigger

             Example:
             "jamfCommand renameComputer" - executes "/usr/local/bin/jamf policy -trigger renameComputer"

      Below are examples of different types of worfklows you can setup using DEPNotify.
      For more information, visit the DEPNotify Documentation: https://gitlab.com/Mactroll/DEPNotify

EOL

##
## EXAMPLE WORKFLOW #1
##

## This is a simplistice workflow that involves some initial configuration and then
## Utilizing a "jamf policy" to kick off the rest of the deployment.

## Machine Configuration
DEPNotify "Command: MainText: Configuring Machine."
DEPNotify "Status: Setting Computer Name"
jamfCommand configureComputer

## Installers required for every Mac - Runs policies with 'deploy' manual trigger
DEPNotify "Status: Starting Deployment"
DEPNotify "Command: MainText: Starting software deployment.\n\nThis process can take some time to complete."
jamfCommand deploy

## Add Departmental Apps - Run polices with "installDepartmentalApps" manual and scoped to departments
DEPNotify "Command: MainText: Adding Departmental Components."
DEPNotify "Status: Adding Departmental Applications. This WILL take a while."
jamfCommand recon
jamfCommand installDepartmentalApps

## Check for any remaining scoped policies
DEPNotify "Status: Final policy check."
jamfCommand policy

## Send updated inventory for Smart Groups
DEPNotify "Command: MainText: Final install checks."
DEPNotify "Status: Update inventory record."
jamfCommand recon

##
## EXAMPLE WORKFLOW #2
##

## This worklfow guides the user through each step and completely controlling the
## flow of the onboarding process.

## Start the count
NUM=1
TOTAL=10 ## Update this to the number of 'DEPNotify "Status:..." commands below
DEPNotify "Command: Determinate: ${TOTAL}"

## Update inventory for exception smart groups
DEPNotify "Status ${NUM}/${TOTAL} Gathering inventory"
jamfCommand recon
NUM=$((NUM+1))

## Backdoor Admin Account
DEPNotify "Status: ${NUM}/${TOTAL} Initial configuration"
jamfCommand createBackdoorAdmin
NUM=$((NUM+1))

## Rename Computer
DEPNotify "Status: ${NUM}/${TOTAL} Renaming computer to company standards"
jamfCommand renameComputer
NUM=$((NUM+1))

## Install Jamf Connect
DEPNotify "Status: ${NUM}/${TOTAL} Installing Jamf Connect"
jamfCommand connect
NUM=$((NUM+1))

## Install Jamf Protect
DEPNotify "Status: ${NUM}/${TOTAL} Installing Jamf Protect"
jamfCommand installJamfProtect
NUM=$((NUM+1))

DEPNotify "Command: MainText: Installing Applications. This may take a while."

## Install Creative Cloud
DEPNotify "Status: ${NUM}/${TOTAL} Installing Adobe Creative Cloud"
jamfCommand installCreativeCloud
NUM=$((NUM+1))

## Install Latest Chrome
DEPNotify "Status: ${NUM}/${TOTAL} Installing Latest Chrome"
jamfCommand installChrome
NUM=$((NUM+1))

## Install Microsoft Office
DEPNotify "Status: ${NUM}/${TOTAL} Installing Microsoft Office"
jamfCommand installMicrosoft
NUM=$((NUM+1))

DEPNotify "Command: MainText: Final settings and configuration"

## Running a "jamf policy" for any additional installs we didn't call manually
DEPNotify "Status: ${NUM}/${TOTAL} Final Installs"
jamfCommand policy
NUM=$((NUM+1))

## Final inventory update
DEPNotify "Status: ${NUM}/${TOTAL} Updating inventory"
jamfCommand recon
NUM=$((NUM+1))

cleanUp ## Quits application, deletes temporary files, and resumes normal operation

##
## EXAMPLE WORKFLOW #3
##

## This workflow users a while loop to wait for users to complete something,
## like logging into Jamf Connect. You can also use this to wait for the user to
## connect to a VPN (among many other things).

## Machine Configuration
DEPNotify "Command: MainText: Configuring Machine."
DEPNotify "Status: Installing Jamf Connect"
jamfCommand installJamfConnect

## Instructing the user to login to Jamf Connect once it launches
DEPNotify "Command: MainTitle: Login to Jamf Connect"
DEPNotify "Command: MainText: Please login to Jamf Connect with your company credentials."
DEPNotify "Status: Waiting for user to login to Jamf Connect"

## Waiting for the user to log into Jamf Connect.
TIMEOUT=600
LOGINTEST=$(defaults read /Users/$USER/Library/Preferences/com.jamf.connect.state LastSignIn)
while [ $LOGINTEST ]
do
  LOGINTEST=$(defaults read /Users/$USER/Library/Preferences/com.jamf.connect.state LastSignIn)
  counter=$((counter+1))
  if [[ $counter -gt $TIMEOUT ]]
  then
    DEPNotify "Status: Error Logging into Jamf Connect"
    DEPNotify "Command: Quit: Error logging into Jamf Connect. Contact IT for assistance."
    echo "ERROR: User did not login to Jamf Connect in alloted time"
    sleep 30
    cleanUp
    exit 1
  fi
  sleep 1
done

## Check for any remaining scoped policies
DEPNotify "Status: Final policy check."
jamfCommand policy

## Send updated inventory for Smart Groups
DEPNotify "Command: MainText: Final install checks."
DEPNotify "Status: Update inventory record."
jamfCommand recon
