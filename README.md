# Onboarding-With-DEPNotify

Create an end user-based provisioning workflow for Jamf deployments with a DEPNotify interface.

## Background
It has become increasingly important in many organizations to be able to ship a new Mac directly to an employee and have it ready for the user right out of the box.

We take a three-pronged approach to zero-touch provisioning:
1. Apple Business/School Manager and Automated Device Enrollment
2. Jamf Prestage Enrollments
3. DEPNotify

This script controls the workflow from the time the machine is enrolled to the time the user logs in. At that point, DEPNotify launches and guides the new employee through the setup of their machine to company standards.

## ...where credit is due

I want to take a moment to credit Richard Purves (aka “franton”) in the Jamf Nation and MacAdmins communities as the inspiration for much of this script. He had posted a very wonderful script to the #depnotify channel of the MacAdmins Slack server in December of 2018. I may have written this version, but it shares a lot of the same DNA as his initial work.

## Training
The philosophy, use cases, and detailed examples are included in a three-part blog series called **Creating Magic With Endpoint Provisioning** on our website:
- [PART 1 – THE “TA DA!” OF DEPNOTIFY](https://www.rocketman.tech/post/creating-magic-with-endpoint-provisioning-part-1-the-ta-da-of-depnotify)
- [PART 2 – THE SCRIPT](https://www.rocketman.tech/post/creating-magic-with-endpoint-provisioning-part-2-the-script)
- [PART 3 – THE POLICIES](https://www.rocketman.tech/post/creating-magic-with-endpoint-provisioning-part-3-the-policies)

## Requirements
- DEPNotify Package. Can be found at [https://gitlab.com/Mactroll/DEPNotify/-/releases](https://gitlab.com/Mactroll/DEPNotify/-/releases)

## Parameters
- Parameter 4: Base64 encoded string for username/password.
	- Label: Base64 encoded string for username/password.
	- Type: String
	- Instructions: Created in Terminal using "echo -n 'username:password' | base64 | pbcopy"
	- Example: YXBpdXNlcm5hbWU6cGFzc3dvcmQK
- Parameter 5: Options to pass to DEPNotify
	- Label: Options to pass to DEPNotify
	- Type: Options
	- Options: -fullscreen | -jamf
		- -fullscreen: Makes the DEPNotify window full screen so the user can't interrupt it
		- -jamf: Reads the Jamf log and puts it into the status window
		- More info: [https://gitlab.com/Mactroll/DEPNotify#application-flags](https://gitlab.com/Mactroll/DEPNotify#application-flags)
- Parameter 6: Initial title - defaults to "Welcome to your new Mac!"
	-Label: Initial Title
	-Type: String
	-Example: "Welcome to your new Mac!"
- Parameter 7: Full path to logo - must be previously deployed to work
	-Label: Full path to logo
	-Type: File Path
	-Example: "/Library/Application Support/Rocketman/logo.png"
- Parameter 8: Title of window - not normally visible to users
	-Label: Title of Window
	-	-Type: String
	-Example: "Welcome to your new Mac!"

## Additional Customization

The "Onboarding with DEPNotify" starter script workflow is meant to work out-of-box without any customization. However, the true power of DEPNotify is in the customization of the the workflow. With DEPNotify, you can:
1. Control the provisioning workflow
2. Provide instructions for users on components they need to setup
3. Wait to continue until certain components are installed
4. And anything else you can think of in a bash script!

Because of this, we've created an auxiliary script with examples of different onboarding workflows you can setup within DEPNotify. These workflows are located in the "DEPNotify Examples.sh" script and can be copied into your onboarding.sh script.

## Deployment Instructions

Auto Deployment
1. Upload the DEPNotify Package found in https://gitlab.com/Mactroll/DEPNotify/-/releases
2. Run the Auto Deployment script
3. Add the DEPNotify Package to the Onboarding with DEPNotify Policy

Manual
- Add the onboarding.sh script to Jamf Pro with the Parameter Labels above
- Create a Policy deploying onboarding.sh Once Per Computer with the Enrollment trigger with the parameters set above
- Optional: Create an API User with the following permissions and add the API Hash to Parameter 4
	-Departments: Read
- Optional: Package and upload a logo and add it the path to the logo to Parameter 7
