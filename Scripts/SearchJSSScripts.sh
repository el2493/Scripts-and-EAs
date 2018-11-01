#!/bin/sh

## Run locally, searches all scripts in JSS and returns which scripts (by ID) contain a specific string.
## 11/1/2018 by elaugel/el2493

jssurl="https://jssurl.com:8443"
loggedInUser=$( scutil <<< "show State:/Users/ConsoleUser" | awk -F': ' '/[[:space:]]+Name[[:space:]]:/ { if ( $2 != "loginwindow" ) { print $2 }}' )

## Establish API Credentials
# https://github.com/jamfit/Encrypted-Script-Parameters
# Values for username and password used below will be taken from the results obtained from the above-linked instructions
# If no one else is going to see this, you could also just enter apiUsername and apiPassword in plain text (not recommended)

function DecryptString() {
    # Usage: ~$ DecryptString "Encrypted String" "Salt" "Passphrase"
    echo "${1}" | /usr/bin/openssl enc -aes256 -d -a -A -S "${2}" -k "${3}"
}

apiUserEncrypt=[Encrypted String 1]
apiPassEncrypt=[Encrypted String 2]

apiUsername=$(DecryptString $apiUserEncrypt '[Salt 1]' '[Passphrase 1]')
apiPassword=$(DecryptString $apiPassEncrypt '[Salt 2]' '[Passphrase 2]')

searchString="Enter search string here"

## Use API to search scripts for $searchString

scriptIDs=$(curl -sku "$apiUsername":"$apiPassword" -H "Accept: application/xml" "$jssurl"/JSSResource/scripts -X GET | xmllint --xpath "/scripts/script/id" - | sed -e 's/<[^>]*>/ /g')
#echo "scriptIDs is "$scriptIDs
for scriptID in $(curl -sku "$apiUsername":"$apiPassword" -H "Accept: application/xml" "$jssurl"/JSSResource/scripts -X GET | xmllint --xpath "/scripts/script/id" - | sed -e 's/<[^>]*>/ /g')
do
	#echo "scriptID is "$scriptID
	scriptContent=$(curl -sku "$apiUsername":"$apiPassword" -H "Accept: application/xml" "$jssurl"/JSSResource/scripts/id/$scriptID -X GET)
	if [[ $scriptContent = *"$searchString"* ]]; then
		echo $scriptID" contains "$searchString
	fi	
done
