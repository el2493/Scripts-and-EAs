#!/bin/sh

#Shows version of CrowdStrike Installed on computer

crowdstrikeVersion=$(sysctl cs | grep "cs.version")
if [[ -z crowdstrikeVersion ]]; then
	crowdstrikeVersion="CrowdStrike Not Installed"
else
	crowdstrikeVersion=${crowdstrikeVersion:12}
fi

echo "<result>$crowdstrikeVersion</result>"
