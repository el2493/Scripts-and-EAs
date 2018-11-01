#!/bin/bash -v
exec 2>&1

#># Purpose: Set the Software Update Server for root and all users to the OS-appropriate catalog
#># Original Author: Jared F. Nichols
#># With additions from Chad Brewer post on JamfNation

#Adapted by Bram Cohen 2/20/13
#Updated 6/13/2014 by Bram Cohen

#Define the Name of your Server for the log output
netsusURL="netsusurl.com"
NAME="ORG SUS"
Branch="$4"

#Define your Snow Leopard Branch 10.6
SLSUS="http://applesus.domain.com/content/catalogs/others/index-leopard-snowleopard.merged-1.sucatalog"
#Define your Lion Branch 10.7
LSUS="http://${netsusURL}/content/catalogs/others/index-lion-snowleopard-leopard.merged-1_${Branch}.sucatalog"
#Define your Mountian Lion Branch 10.8
MLSUS="http://${netsusURL}/content/catalogs/others/index-mountainlion-lion-snowleopard-leopard.merged-1_${Branch}.sucatalog"
#Define your MavericksBranch 10.9
MVSUS="http://${netsusURL}/content/catalogs/others/index-10.9-mountainlion-lion-snowleopard-leopard.merged-1_${Branch}.sucatalog"
#Define your YosemiteBranch 10.10
YOSUS="http://${netsusURL}/content/catalogs/others/index-10.10-10.9-mountainlion-lion-snowleopard-leopard.merged-1_${Branch}.sucatalog"
#Define your ElCaptainBranch 10.11
ELSUS="http://${netsusURL}/content/catalogs/others/index-10.11-10.10-10.9-mountainlion-lion-snowleopard-leopard.merged-1_${Branch}.sucatalog"
#Define your SierraBranch 10.12
SISUS="http://${netsusURL}/content/catalogs/others/index-10.12-10.11-10.10-10.9-mountainlion-lion-snowleopard-leopard.merged-1_${Branch}.sucatalog"
#Define your HighSierraBranch 10.13
HSSUS="http://${netsusURL}/content/catalogs/others/index-10.13-10.12-10.11-10.10-10.9-mountainlion-lion-snowleopard-leopard.merged-1_${Branch}.sucatalog"
#Define your MojaveBranch 10.14
MOSUS="https://${netsusURL}/content/catalogs/others/index-10.14-10.13-10.12-10.11-10.10-10.9-mountainlion-lion-snowleopard-leopard.merged-1_${Branch}.sucatalog"

#System Variable - Don't Modify
OSversion=`sw_vers | grep ProductVersion`


#Sets System-Level com.apple.SoftwareUpdate.plist
case "$OSversion" in
  
*10.6*)
	defaults write /Library/Preferences/com.apple.SoftwareUpdate CatalogURL "$SLSUS"
	defaults read /Library/Preferences/com.apple.SoftwareUpdate CatalogURL
	echo "Setting SUS to $NAME Lion Branch for User $3"
	;;
*10.7*)
	defaults write /Library/Preferences/com.apple.SoftwareUpdate CatalogURL "$LSUS"
	defaults read /Library/Preferences/com.apple.SoftwareUpdate CatalogURL
	echo "Setting System SUS to $NAME Lion Branch."
	;;
*10.8*)
	defaults write /Library/Preferences/com.apple.SoftwareUpdate CatalogURL "$MLSUS"
	defaults read /Library/Preferences/com.apple.SoftwareUpdate CatalogURL
	echo "Setting System SUS to $NAME Mountain Lion Branch."
	;;
*10.9*)
	defaults write /Library/Preferences/com.apple.SoftwareUpdate CatalogURL "$MVSUS"
	defaults read /Library/Preferences/com.apple.SoftwareUpdate CatalogURL
	echo "Setting System SUS to $NAME Mavericks Branch."
	;;
*10.10*)
	defaults write /Library/Preferences/com.apple.SoftwareUpdate CatalogURL "$YOSUS"
	defaults read /Library/Preferences/com.apple.SoftwareUpdate CatalogURL
	echo "Setting System SUS to $NAME Yosemite Branch."
	;;
*10.11*)
	defaults write /Library/Preferences/com.apple.SoftwareUpdate CatalogURL "$ELSUS"
	defaults read /Library/Preferences/com.apple.SoftwareUpdate CatalogURL
	echo "Setting System SUS to $NAME El Captain Branch."
	;;
*10.12*)
	defaults write /Library/Preferences/com.apple.SoftwareUpdate CatalogURL "$SISUS"
	defaults read /Library/Preferences/com.apple.SoftwareUpdate CatalogURL
	echo "Setting System SUS to $NAME Sierra Branch."
	;;
*10.13*)
	defaults write /Library/Preferences/com.apple.SoftwareUpdate CatalogURL "$HSSUS"
	defaults read /Library/Preferences/com.apple.SoftwareUpdate CatalogURL
	echo "Setting System SUS to $NAME High Sierra Branch."
	;;
*10.14*)
	sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate CatalogURL "$MOSUS"
	sudo defaults read /Library/Preferences/com.apple.SoftwareUpdate CatalogURL
	echo "Setting System SUS to $NAME Mojave Branch."
	;;
esac

exit 0
