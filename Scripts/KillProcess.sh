#!/bin/bash -v
exec 2>&1

proc=("$4")

runningProc=$(ps axc | grep -i "$proc" | awk '{print $1}')

if [[ -n $runningProc ]]; then
    echo "Found running process $proc with PID: ${runningProc}. Killing it..."
    kill $runningProc
else
    echo "$proc not found running..."
fi

exit 0
