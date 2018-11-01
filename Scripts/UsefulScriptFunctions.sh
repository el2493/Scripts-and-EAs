#!/bin/bash

## Jamf Binary Path (for when a "jamf" command needs to be run in a script, use $jamf_binary instead)

jamf_binary=`/usr/bin/which jamf`

if [[ "$jamf_binary" == "" ]] && [[ -e "/usr/sbin/jamf" ]] && [[ ! -e "/usr/local/bin/jamf" ]]; then
   jamf_binary="/usr/sbin/jamf"
elif [[ "$jamf_binary" == "" ]] && [[ ! -e "/usr/sbin/jamf" ]] && [[ -e "/usr/local/bin/jamf" ]]; then
   jamf_binary="/usr/local/bin/jamf"
elif [[ "$jamf_binary" == "" ]] && [[ -e "/usr/sbin/jamf" ]] && [[ -e "/usr/local/bin/jamf" ]]; then
   jamf_binary="/usr/local/bin/jamf"
fi

## Do something as loggedInUser (useful for osascript)

loggedInUser=$( scutil <<< "show State:/Users/ConsoleUser" | awk -F': ' '/[[:space:]]+Name[[:space:]]:/ { if ( $2 != "loginwindow" ) { print $2 }}      ' )
loggedInUserUID=$(id -u $loggedInUser)

/bin/launchctl asuser "$loggedInUserUID" /usr/bin/osascript -e

## DecryptString (for cases like API where credentials need to be entered in script)

function DecryptString() {
    # Usage: ~$ DecryptString "Encrypted String" "Salt" "Passphrase"
    echo "${1}" | /usr/bin/openssl enc -aes256 -d -a -A -S "${2}" -k "${3}"
}

usernameAPIEncrypted="Encrypted String 1"
passwordAPIEncrypted="Encrypted String 2"

usernameAPI=$(DecryptString $usernameAPIEncrypted 'Salt 1' 'Passphrase 1')
passwordAPI=$(DecryptString $passwordAPIEncrypted 'Salt 2' 'Passphrase 2')
