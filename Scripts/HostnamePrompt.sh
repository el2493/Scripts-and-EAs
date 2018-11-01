#!/bin/sh

# Decrypt API Credentials
function DecryptString() {
    # Usage: ~$ DecryptString "Encrypted String" "Salt" "Passphrase"
    echo "${1}" | /usr/bin/openssl enc -aes256 -d -a -A -S "${2}" -k "${3}"
}

usernameAPIEncrypted="$4"
passwordAPIEncrypted="$5"

usernameAPI=$(DecryptString $usernameAPIEncrypted 'Salt 1' 'Passphrase 1')
passwordAPI=$(DecryptString $passwordAPIEncrypted 'Salt 2' 'Passphrase 2')

# Define general variables
jssurl="https://jssurl:8443/"
udid=$( ioreg -rd1 -c IOPlatformExpertDevice | awk '/IOPlatformUUID/ { split($0, line, "\""); printf("%s\n", line[4]); }' )

# Where's the jamf binary stored? This is for SIP compatibility.
jamf_binary=`/usr/bin/which jamf`

 if [[ "$jamf_binary" == "" ]] && [[ -e "/usr/sbin/jamf" ]] && [[ ! -e "/usr/local/bin/jamf" ]]; then
    jamf_binary="/usr/sbin/jamf"
 elif [[ "$jamf_binary" == "" ]] && [[ ! -e "/usr/sbin/jamf" ]] && [[ -e "/usr/local/bin/jamf" ]]; then
    jamf_binary="/usr/local/bin/jamf"
 elif [[ "$jamf_binary" == "" ]] && [[ -e "/usr/sbin/jamf" ]] && [[ -e "/usr/local/bin/jamf" ]]; then
    jamf_binary="/usr/local/bin/jamf"
 fi
 
# CocoaDialog (for prompts)
 
cDialogApp="/Applications/Utilities/cocoaDialog.app"
cDialog="$cDialogApp/Contents/MacOS/cocoadialog"
hostName=$(hostname | sed -e s/.local//g)

if [[ ! -d "$cDialogApp" ]]; then
	echo "cocoadialog not installed"
	$jamf_binary policy -id ## #enter policy number to install cocoadialog
    sleepCounter=0
    while [ ! -d "$cDialogApp" ]; do
    	sleep 5
    	if [ "$sleepCounter" -le 24 ]; then
    		((sleepCounter++))
    	else
    		echo "policy timed out waiting for cocoadialog"
        	exit 1
    	fi
    done
    echo "cocoadialog installed"
else
	echo "cocoadialog installed"
fi

# Define Functions
userPrompt() {
promptWindow=$($cDialog inputbox --title "Choose Hostname" --informative-text "Enter computer hostname and click \"OK\", or click \"$hostName\" to use the existing hostname." --button1 "OK" --button2 "$hostName")
buttonClicked=$(echo "$promptWindow" | awk 'NR==1{print}')
computerName=$(echo "$promptWindow" | awk 'NR>1{print}')
echo $buttonClicked
echo $computerName
}

computerCheckJSS() {
# Check to see if there is another computer in JSS with same name
udidlookup=$(curl -H "Accept: application/xml" -s -u "$usernameAPI:$passwordAPI" "${jssurl}JSSResource/computers/name/$(echo "$computerName" | sed -e 's/ /\+/g')/subset/general" | xpath "//computer/general/udid/text()" 2> /dev/null)
}

duplicatePrompt() {
duplicatePromptWindow=$($cDialog inputbox --title "Duplicate Hostname, Choose Another" --informative-text "A Mac named $computerName already exists in the JSS. Please enter another hostname and click \"OK\"." --button1 "OK")
buttonClicked=$(echo "$duplicatePromptWindow" | awk 'NR==1{print}')
computerName=$(echo "$duplicatePromptWindow" | awk 'NR>1{print}')
echo $buttonClicked
echo $computerName
}

getCompSiteAndDept () {
# Use API to get computer Site from UUID
# Get computer's UUID
compUUID=$(system_profiler SPHardwareDataType | awk '/UUID/ { print $3; }')
#echo "compUUID is "$compUUID
compRaw=$(curl ${jssurl}JSSResource/computers/udid/${compUUID} --user "$usernameAPI:$passwordAPI")
echo $compRaw
compSite=$(echo $compRaw | xpath '//general/site/name' 2>&1 | awk -F'<name>|</name>' '{print $2}')
compSite="${compSite:2}"
echo "compSite is "$compSite
compDept=$(echo $compRaw | xpath '//location/department' 2>&1 | awk -F'<department>|</department>' '{print $2}')
compDept="${compDept:2}"
echo "compDept is "$compDept
} 

# Begin user interaction
userPrompt
if [[ "$buttonClicked" == 2 ]]; then
	computerCheckJSS
	if [ "$udidlookup" == "" ] || [ "$udidlookup" == "$udid" ]; then # no entry, or our entry - ok to go
		echo "use existing $hostName"
	else
		# another computer with this name exists in the JSS
		duplicateComputer="yes"
		while [ "$duplicateComputer" = "yes" ]; do	
			duplicatePrompt
			computerCheckJSS
			if [ "$udidlookup" == "" ] || [ "$udidlookup" == "$udid" ]; then # no entry, or our entry - ok to go
				echo "use $computerName"
				/usr/sbin/scutil --set ComputerName $computerName
				/usr/sbin/scutil --set LocalHostName $computerName
				/usr/sbin/scutil --set HostName $computerName
				dscacheutil -flushcache
				$jamf_binary -setComputerName -name "$computerName"
				duplicateComputer="no"
			fi
		done
	fi
elif [[ "$buttonClicked" == 1 ]]; then
	if [ "$computerName" == "" ]; then #Make sure user didn't leave field blank when they clicked OK
    	while [ "$computerName" == "" ]; do
      		userPrompt  
        done
  fi
  computerCheckJSS
	if [ "$udidlookup" == "" ] || [ "$udidlookup" == "$udid" ]; then # no entry, or our entry - ok to go
		echo "use $computerName"
		/usr/sbin/scutil --set ComputerName $computerName
		/usr/sbin/scutil --set LocalHostName $computerName
		/usr/sbin/scutil --set HostName $computerName
		dscacheutil -flushcache
		$jamf_binary -setComputerName -name "$computerName"
	else
		# another computer with this name exists in the JSS
		duplicateComputer="yes"
		while [ "$duplicateComputer" = "yes" ]; do	
			duplicatePrompt
			computerCheckJSS
			if [ "$udidlookup" == "" ] || [ "$udidlookup" == "$udid" ]; then # no entry, or our entry - ok to go
				echo "use $computerName"
				/usr/sbin/scutil --set ComputerName $computerName
				/usr/sbin/scutil --set LocalHostName $computerName
				/usr/sbin/scutil --set HostName $computerName
				dscacheutil -flushcache
				$jamf_binary -setComputerName -name "$computerName"
				duplicateComputer="no"
			fi
		done
	fi
else
	echo "not defined"
fi

$jamf_binary recon

getCompSiteAndDept
## Below section can be used to bind to AD, depending on Department or Site.  Relies on AD binding policies with custom triggers
if [[ $compSite == "HR" ]]; then
	echo "don't bind to AD"
elif [[ $compSite == "IT" ]]; then
	echo "bind to IT AD"
  $jamf_binary policy -trigger adbindIT
elif [[ $compSite == "Managers" ]]; then
	if [[ $compDept == *"Managers-CEO"* ]]; then
    	echo "bind to CEO AD"
      $jamf_binary policy -trigger adbindCEO
  else
    	echo "bind to Managers AD"
    	$jamf_binary policy -trigger adbindManagers
  fi
else
	echo "compSite not defined correctly"
fi

exit 0
