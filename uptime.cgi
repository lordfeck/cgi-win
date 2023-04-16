#!/bin/bash
# New CGI that handles stats as JSON
# Author: Thran Authored: 06/12/19

#==============================================================================#
# BEGIN COMMON FUNCTIONS
#==============================================================================#

function writeJSONHeader {
    echo -e 'Content-type: application/json\n'
}

#JSON TAG
function jT {
    echo -n "\"$1\":"
}

#JSON FIELD
function jF {
    # JSON expects a comma after each field until the final
    if [ "$2" = "f" ]; then
        echo "\"$1\""
    else
        echo "\"$1\","
    fi
}

#==============================================================================#
# END COMMON FUNCTIONS
#==============================================================================#

writeJSONHeader

# CPU Usage in tenths of a percent
function getNginxCPU {
    ps --no-headers -C nginx -o cp | awk '{cp += $1} END {print cp}'
}
# PS returns perc of CPU time / time program has been running.
function getNginxCPUPerc {
    ps --no-headers -C nginx -o %cpu | awk '{cpu += $1} END {print cpu}'
}

function getUptime {
    uptime -p | sed 's/up //' | tr -d '\n' 
}

function getTotalMem {
    free -m | grep Mem | awk '{ print $3 }' | tr -d '\n'
}

function getLoadAvg {
    uptime |  awk -F 'load average:' '{ print $2 }' | tr -d ',' | tr -d '\n'
}

# Resident set size; total of process in memory
function getNginxRSS {
    ps --no-headers -C nginx -o rss |  awk '{rss += $1} END {print rss}'
}

function getUname {
    uname
}

# Begin JSON composition
echo "{"

jT "hostname"
jF "$(hostname)"

jT "uptime"
jF "$(getUptime)"

jT "totalMem"
jF "$(getTotalMem)"

jT "loadAvg"
jF "$(getLoadAvg)"

jT "uname"
jF "$(getUname)"

jT "nginxCPU"
jF "$(getNginxCPU)" 

jT "nginxCPUPerc"
jF "$(getNginxCPUPerc)" 

jT "nginxRssKb"
jF "$(getNginxRSS)" "f"

echo "}"
