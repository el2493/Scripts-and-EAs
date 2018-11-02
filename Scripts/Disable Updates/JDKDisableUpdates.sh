#!/bin/sh

jdkFile="/Library/Preferences/com.oracle.java.Java-Updater.plist" # Preference
if [ -f "${jdkFile}" ] ; then
	# Read preference settings 
  autoUpdateStatus=$(sudo defaults read $jdkFile JavaAutoUpdateEnabled)
  if [[ $autoUpdateStatus == 0 ]]; then
  	echo "Updates Already Disabled"
	elif [[ $autoUpdateStatus != 0 ]]; then
	  #Auto Update is not disabled, run command to disable it
  	defaults write /Library/Preferences/com.oracle.java.Java-Updater JavaAutoUpdateEnabled -bool false
  	autoUpdateStatus=$(sudo defaults read $jdkFile JavaAutoUpdateEnabled)
  	if [[ $autoUpdateDisable == 0 ]]; then
  		echo "Disabled Updates"
  	else
  		echo "Unable to Disable Updates"
        exit 1
  	fi
	fi
else
    defaults write /Library/Preferences/com.oracle.java.Java-Updater JavaAutoUpdateEnabled -bool false
    autoUpdateStatus=$(sudo defaults read $jdkFile JavaAutoUpdateEnabled)
  	if [[ $autoUpdateDisable == 0 ]]; then
	  	echo "Created Prefs File, Disabled Updates"
	  else
		  echo "Created Prefs File, Unable to Disable Updates"
      exit 1
    fi
fi

exit 0
