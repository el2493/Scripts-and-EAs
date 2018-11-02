#!/bin/bash -v
exec 2>&1

loggedInUser=$( scutil <<< "show State:/Users/ConsoleUser" | awk -F': ' '/[[:space:]]+Name[[:space:]]:/ { if ( $2 != "loginwindow" ) { print $2 }}      ' )

rm -rf /Users/$loggedInUser/Library/Google/GoogleSoftwareUpdate/GoogleSoftwareUpdate.bundle
mkdir -p /Users/$loggedInUser/Library/Google/GoogleSoftwareUpdate/
touch /Users/$loggedInUser/Library/Google/GoogleSoftwareUpdate/GoogleSoftwareUpdate.bundle
chown root /Users/$loggedInUser/Library/Google/GoogleSoftwareUpdate/GoogleSoftwareUpdate.bundle
chmod 644 /Users/$loggedInUser/Library/Google/GoogleSoftwareUpdate/GoogleSoftwareUpdate.bundle

exit 0
