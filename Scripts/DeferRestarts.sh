#!/bin/bash -v

#inspired by alexjdale's restart script (https://www.jamf.com/jamf-nation/discussions/14940/restart-script-forked)
#also inspired by FVHelper

##Define Parameters
deferRemainJSS="$4"
#test if deferRemainJSS is an integer
if [[ $deferRemainJSS =~ ^-?[0-9]+$ ]]; then
    echo "DeferRemainJSS set"
else
    deferRemainJSS=3
fi

deferHours="$5"
if [[ $deferHours =~ ^-?[0-9]+$ ]]; then
    echo "DeferHours set"
else
    deferHours=4
fi
deferSeconds=$(( $deferHours * 3600 ))
echo $deferSeconds
prefs="/tmp/restart"

pathToApp="$6"
if [ -n "$pathToApp" ]; then
    echo "pathToApp defined"
else
    echo "pathToApp not defined, cancelling"
    exit 1
fi
#Check to see if app exists, if it doesn't then installation failed
if [ -d "$pathToApp" ]; then
    echo "App installed"
else
    echo "App not installed, cancelling Policy"
    exit 1
fi

##Define commands
#process for initial run with immediate restart
initRestart() {
# Create restart script
echo > /tmp/restartscript.sh '#!/bin/bash

#message information
msgRestartHead="Restart Pending"
msgRestart="This computer will restart in 2 minutes.  Please save any open documents and close any open applications."

dialogicon="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/Resources/Message.png"
jamfhelper="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"

shutdown -r +2
restartprompt=$("${jamfhelper}" -windowType utility -heading "${msgRestartHead}" -alignHeading center -description "${msgRestart}" -icon "${dialogicon}" -timeout 112)

exit 0'

# Create and load a LaunchDaemon to fork a restart
echo "<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.org.restart</string>
    <key>UserName</key>
    <string>root</string>
    <key>ProgramArguments</key>
    <array>
        <string>sh</string>
        <string>/tmp/restartscript.sh</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>" > /tmp/restart.plist
sudo chown root:wheel /tmp/restart.plist
sudo chmod 755 /tmp/restart.plist
sudo launchctl load /tmp/restart.plist
}

#process for deferred run
deferRestart() {
# Create restart script
echo > /tmp/restartscript.sh '#!/bin/bash

deferThreshold=$1
prefs=$2
deferHours=$3

#restart prompt message
msgPromptHead="Software Restart Required"
msgPromptEnable="This computer needs to restart to complete a software update.

Would you like to restart now?"

#no deferrals message
msgPromptEnableForce="The maximum amount of deferments has been reached.

The computer will now restart.  Please save and close any files you have open on the computer, then click Restart..."

#deferrals remaining message
msgDeferralsRemainingHead="Restart Deferred"
msgDeferralsRemaining="The required restart has been deferred.  You will be prompted to restart again in "${deferHours}" hours."

#restart selected message
msgRestartHead="Restart Pending"
msgRestart="This computer will restart in 2 minutes.  Please save any open documents and close any open applications."

dialogicon="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/Resources/Message.png"
jamfhelper="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"

#used to make sure Finder is running
checkProcess()
{
	if [ "$(ps aux | grep "${1}" | grep -v grep)" != "" ]; then
		return 0
	else
		return 1
	fi
}

#make sure user is logged in
checkConsoleStatus()
{
	userloggedin="$(who | grep console | awk '\''{print $1}'\'')"
	consoleuser="$(ls -l /dev/console | awk '\''{print $3}'\'')"
	screensaver="$(ps aux | grep ScreenSaverEngine | grep -v grep)"

	if [ "${screensaver}" != "" ]; then
		# screensaver is running
		echo "screensaver"
		return
	fi

	if [ "${userloggedin}" == "" ]; then
		# no users logged in (at loginwindow)
		echo "nologin"
		return
	fi

	if [ "${userloggedin}" != "${consoleuser}" ]; then
		# a user is loggedin, but we are at loginwindow or we have multiple users logged in with switching (too hard for now)
		echo "loginwindow or fast switching multi login"
		return
	fi

	# if we passed all checks, user is logged in and we are safe to prompt or display bubbles
	echo "userloggedin"
}

# if starting on login trigger, wait for the finder to start

until checkProcess "Finder.app"
do
	sleep 3
done

if [ "$(checkConsoleStatus)" == "userloggedin" ] # double check we have logged in user
then
	# read deferCounter if exists, write if not
	deferCounter=$(defaults read "${prefs}" DeferCount 2> /dev/null)
	if [ -n "$deferCounter" ]; then
		echo "File exists, DeferCount is ${deferCounter}"
	else
		echo "File does not exist"
		defaults write "${prefs}" DeferCount -int 1
		deferCounter=1
		deferRemain=$(( deferThreshold - deferCounter ))
		restartprompt=$("${jamfhelper}" -windowType utility -heading "${msgDeferralsRemainingHead}" -alignHeading center -description "${msgDeferralsRemaining}
You have "${deferRemain}" deferral(s) remaining before a restart will be enforced." -icon "${dialogicon}" -button1 "OK"  -defaultButton 1 -timeout 60)
		exit 0
	fi

	deferRemain=$(( deferThreshold - deferCounter ))
	if [ ${deferRemain} -eq 0 ] || [ ${deferRemain} -lt 0 ]; then
		restartprompt=$("${jamfhelper}" -windowType utility -heading "${msgPromptHead}" -alignHeading center -description "${msgPromptEnableForce}" -icon "${dialogicon}" -button1 "Restart..."  -defaultButton 1)
		shutdown -r +2
		restartprompt=$("${jamfhelper}" -windowType utility -heading "${msgRestartHead}" -alignHeading center -description "${msgRestart}" -icon "${dialogicon}" -timeout 112)
	else
		restartprompt=$("${jamfhelper}" -windowType utility -heading "${msgPromptHead}" -alignHeading center -description "${msgPromptEnable}
To temporarily defer restart, click Later. It can be deferred ${deferRemain} more time(s)." -icon "${dialogicon}" -button1 "Restart..."  -button2 "Later" -defaultButton 1 -cancelButton 2)
	fi

	if [ "$restartprompt" == "0" ]; then
		echo "jamf please display restart message"
		shutdown -r +2
		restartprompt=$("${jamfhelper}" -windowType utility -heading "${msgRestartHead}" -alignHeading center -description "${msgRestart}" -icon "${dialogicon}" -timeout 112)
	elif [ "$restartprompt" == "2" ]; then
		(( deferCounter ++ ))
		defaults write "${prefs}" DeferCount -int ${deferCounter}
		deferRemain=$(( deferThreshold - deferCounter ))
		echo "user skipped restart - deferCount: ${deferCounter}"
		restartprompt=$("${jamfhelper}" -windowType utility -heading "${msgDeferralsRemainingHead}" -alignHeading center -description "${msgDeferralsRemaining}
You have "${deferRemain}" deferral(s) remaining before a restart will be enforced." -icon "${dialogicon}" -button1 "OK"  -defaultButton 1 -timeout 60)		
	fi
else
	echo "there is no console user active, consolestatus: $(checkConsoleStatus)..."
fi

exit 0'
#sudo chown root:wheel /tmp/restartscript.sh
#sudo chmod 755 /tmp/restartscript.sh

# Create and load a LaunchDaemon to fork a restart
echo "<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.org.restart</string>
    <key>UserName</key>
    <string>root</string>
    <key>ProgramArguments</key>
    <array>
        <string>sh</string>
        <string>/tmp/restartscript.sh</string>
        <string>$deferRemainJSS</string>
        <string>$prefs</string>
        <string>$deferHours</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>StartInterval</key>
    <integer>$deferSeconds</integer>
</dict>
</plist>" > /tmp/restart.plist
sudo chown root:wheel /tmp/restart.plist
sudo chmod 755 /tmp/restart.plist
sudo launchctl load /tmp/restart.plist
}

##Define User Promt Info
dialogicon="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/Resources/Message.png"
jamfhelper="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"

#restart prompt message
msgPromptHead="Software Restart Required"
msgPromptRestart="This computer needs to restart to complete a software update.

Would you like to restart the computer now?"

##Start user prompts
restartprompt=$("${jamfhelper}" -windowType utility -heading "${msgPromptHead}" -alignHeading center -description "${msgPromptRestart}
To temporarily defer restart, click Later. It can be deferred ${deferRemainJSS} more time(s)." -icon "${dialogicon}" -button1 "Restart..."  -button2 "Later" -defaultButton 1 -cancelButton 2)

	if [ "$restartprompt" == "0" ]; then
		echo "jamf please display restart message"
		initRestart
	elif [ "$restartprompt" == "2" ]; then
		echo "user deferred restart"
		deferRestart
	fi

exit 0
