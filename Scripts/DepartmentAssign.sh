#!/bin/sh    

## Allows user to assign computer to specific Department during enrollment
## Departments must already be entered into JSS, this is not used to read from AD
## Because this uses AppleScript it can result in TCC prompts in Mojave if it's triggered by enrollmentComplete
## 11/2/2018 elaugel/el2493

## Assign Variables
loggedInUser=$( scutil <<< "show State:/Users/ConsoleUser" | awk -F': ' '/[[:space:]]+Name[[:space:]]:/ { if ( $2 != "loginwindow" ) { print $2 }}  ' )
jssurl="jssurl:8443"

## Establish API Credentials
# https://github.com/jamfit/Encrypted-Script-Parameters

function DecryptString() {
    # Usage: ~$ DecryptString "Encrypted String" "Salt" "Passphrase"
    echo "${1}" | /usr/bin/openssl enc -aes256 -d -a -A -S "${2}" -k "${3}"
}

apiUserEncrypt=$4
apiPassEncrypt=$5

apiUsername=$(DecryptString $apiUserEncrypt 'Salt 1' 'Passphrase 1')
apiPassword=$(DecryptString $apiPassEncrypt 'Salt 2' 'Passphrase 2')

## User prompt function (to assign Department)
function UserPrompt() {
deptParsed=""
for department in ${deptList[@]}
do
	if [[ $department == "$deptName"* ]]; then
		# https://macscripter.net/viewtopic.php?id=35318
		f=${department##*/}
		if [ "${f:0:1}" = "_" ] ; then
        	echo "NOT Processing $department" 1>&2      # for now just a test
    else 
       	if [[ ! -z ${deptParsed} ]] ; then
           	deptParsed=${deptParsed}","
       	fi
       	echo "Processing $department" 1>&2
       	deptParsed=${deptParsed}"\""${f}"\""   # to create "item1","item2","item..n"
        fi
	fi
done 
# https://macscripter.net/viewtopic.php?id=35318
deptChosen="$(sudo -u ${loggedInUser} /usr/bin/osascript -e 'return (choose from list {'"$deptParsed"'} with prompt "Choose a Department:" with title "Department Chooser" OK button name "Select" cancel button name "Other")')"
if [ "$deptChosen" = "false" ]; then
	otherFollowup=$(sudo -u ${loggedInUser} /usr/bin/osascript -e 'button returned of (display dialog "If a Department is not listed, please email IT so the Department can be added.
	
Please click \"Back\" if you would like to return to the Department list." with title "Contact IT to Add Department" buttons {"Back","OK"} default button 2)')
	echo "otherFollowup is "$otherFollowup
	if [ "$otherFollowup" = "Back" ]; then
		UserPrompt
	fi
fi	
}

## Use API to get computer Site from UUID
# Get computer's UUID
compUUID=$(system_profiler SPHardwareDataType | awk '/UUID/ { print $3; }')

compRaw=$(curl ${jssurl}/JSSResource/computers/udid/${compUUID} --user "$apiUsername:$apiPassword")
echo $compRaw
compSite=$(echo $compRaw | xpath '//general/site/name' 2>&1 | awk -F'<name>|</name>' '{print $2}')
compSite="${compSite:2}"
echo "compSite is"$compSite

#If Site name is different than Department names, define deptName
if [[ $compSite = "Human Resources" ]]; then
	deptName="HR"
else
	deptName="$compSite"
fi
echo "deptName is "$deptName

## Use API to get list of departments
deptRaw=$(curl ${jssurl}/JSSResource/departments --user "$apiUsername:$apiPassword")
echo $deptRaw

# https://bryson3gps.wordpress.com/2014/03/30/the-jss-rest-api-for-everyone/
deptList=$(echo $deptRaw | xpath '//department/name' 2>&1 | awk -F'<name>|</name>' '{print $2}')
echo $deptList

## If there is only 1 Department in a Site, just assign the Department without prompting user to choose
if [ "$deptName" = "Engineering" ] || [ "$deptName" = "Managers" ]; then
	deptChosen=$deptName
elif [ -z "$deptName" ]; then
	echo "deptName not defined"
else
	UserPrompt
fi

echo "deptParsed: "${deptParsed} 
echo "deptChosen: "$deptChosen 

sudo /usr/local/bin/jamf recon -department "$deptChosen"
