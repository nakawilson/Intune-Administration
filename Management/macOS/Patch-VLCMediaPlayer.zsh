#!/bin/zsh
designated_version="3.0.19"
websource_version="https://www.videolan.org/vlc/download-macosx.html"
websource_binary="https://www.videolan.org/vlc/download-macosx.html"
app_name="VLC.app"
app_friendlyname="VLC Media Player"
app_brewcask="vlc"
app_logtag="videolan-vlc_media_player"

brew_path="/bin/brew"
export PATH=/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
log_location="/Library/Logs/Microsoft/ClientPatching"
compliant_version=""

function set_logfile()
{
    if [[ ! -d $log_location ]]
    then
        sudo mkdir -p $log_location || echo "ERROR: Unable to create log directory $log_location" >&2
    fi

    if [[ ! -f $log_location/$app_logtag.log ]]
    then
        sudo touch $log_location/$app_logtag.log || echo "ERROR: Unable to create $app_logtag.log under $log_location" >&2
    fi
    
    if [[ $(cat $log_location/$app_logtag.log | wc -l | tr -d " ") > 300 ]]
    then
        tail -50 $log_location/$app_logtag.log | sudo tee $log_location/$app_logtag.log >/dev/null
    fi
}

function write_log()
{
    if [[ $# -lt 2 ]]
    then
        echo "CRITICAL: Invalid arguments provided for write_log()"
        return
    fi

    timestamp=$(date +"%D %H:%M")

    if [[ $1 == "0" ]]
    then
        prefix="ERROR"
    elif [[ $1 == "1" ]]
    then
        prefix="WARNING"
    elif [[ $1 == "2" ]]
    then
        prefix="EXCEPTION"
    elif [[ $1 == "3" ]]
    then
        prefix="INFO"
    else
        echo "CRITICAL: Invalid argument 1 passed to write_log()"
    fi

    msg=${2//[^a-zA-Z0-9\/\-:. ]/}

    log_str="[$timestamp] $prefix: $msg"

    echo $log_str | sudo tee -a $log_location/$app_logtag.log >/dev/null
}

function handle_process()
{
    local wait=${3:-60}
    declare -i local slept=0
    
    write_log 3 "Pre-checking process $1..."
    while ps aux | grep -v grep | grep $1 &>/dev/null
    do
        if [[ $2 || $slept > 600 ]]
        then
            write_log 1 "Conflict process found. Terminating running process $1..."
            pkill -f $1
            return
        fi

        write_log 3 "Additional instance(s) of $1 found running. Re-checking in $wait seconds (max wait time 10 mins)..."
        sleep $wait
        slept+=$wait
    done
    
    write_log 3 "Pre-check completed: No instance of process $1 found."
}

function compliance_logic()
{
    if [[ ! -d "/Applications/${app_name}" ]]
    then
        echo "INFO: $app_friendlyname not found under /Applications."
        write_log 3 "No local $app_friendlyname instance found under /Applications. Program completed."
        exit
    fi

    local installed_version=$(/usr/bin/defaults read "/Applications/${app_name}/Contents/Info.plist" CFBundleVersion)
    write_log 3 "Local app instance found installed with v$installed_version."
    
    compliant_version=$(curl -s $websource_version | grep -A1 'downloadVersion' | sed -n 2p | sed -E 's/.*([0-9]+\.[0-9]+\.[0-9]+).*/\1/g')
    
    if [[ -z $compliant_version ]]
    then
        write_log 1 "Unable to fetch and extract latest release version from $websource_version. Reassessing with admin-designated version."
        
        if [[ -z $designated_version ]]
        then
            echo "ERROR: Unable to fetch version from web source. Exit as no admin-designated version configured."
            write_log 0 "Admin-designated version not configured. Program exited."
            exit
        else
            compliant_version=$designated_version
            echo "INFO: Unable to fetch version from web source. Using admin-designated version v$designated_version."
            write_log 3 "Admin-designated version set on v$designated_version."
        fi
    else
        write_log 3 "Latest release v$compliant_version found on $websource_version"
    fi
    
    autoload is-at-least
    
    is-at-least "$compliant_version" "$installed_version"
    
    result="$?"
    
    if [[ "$result" == "0" ]]
    then
        echo "INFO: $app_friendlyname compliant on $installed_version. (official: $compliant_version)"
        write_log 3 "Local $app_friendlyname instance is currently compliant on $installed_version. Program completed."
        exit
    elif [[ "$result" == "1" ]]
    then
        write_log 3 "Local $app_friendlyname instance is incompliant. Executing update."
    else
        echo "ERROR: Unexpected is-at-least() result"
        write_log 1 "Unexpected is-at-least() output $result. Attempt patching regardless."
    fi
}

function homebrew_check()
{
    if [[ $(which brew) == *${brew_path} ]]
    then
        if [[ -d $(brew --prefix)/Caskroom/$app_brewcask ]]
        then
            echo "EXCEPTION: $app_friendlyname installed through Homebrew. No actions taken."
            write_log 2 "$app_friendlyname was installed through homebrew on this device. Program exited due to out of scope."
            exit
        fi
    fi
}

function get_systemarch()
{
    cpu_str=$(sysctl machdep.cpu.brand_string | cut -c27-)

    if [[ $cpu_str = 'Apple M'* ]]
    then
        echo 'arm64'
    elif [[ $cpu_str = 'Intel'* ]]
    then
        echo 'x64'
    else
        write_log 3 "Unable to determine system architecture $cpu_str."
        echo 'universal'
    fi
}

set_logfile

compliance_logic

homebrew_check

arch=$(get_systemarch)

if [[ $arch == 'universal' ]]
then
    binary_link=$(curl -s --connect-timeout 15 --retry 3 --retry-delay 60 $websource_binary | grep 'VLC for Mac (Universal Binary)' | sed -E 's/.*(\/\/get\.videolan\..*dmg).*/\1/g' | sed '1s/^/https:/')
elif [[ $arch == 'arm64' ]]
then
    binary_link=$(curl -s --connect-timeout 15 --retry 3 --retry-delay 60 $websource_binary | grep 'VLC for Mac (Universal Binary)' | sed -E 's/.*(\/\/get\.videolan\..*dmg).*/\1/g' | sed '1s/^/https:/' | sed 's/universal/arm64/g')
elif [[ $arch == 'x64' ]]
then
    binary_link=$(curl -s --connect-timeout 15 --retry 3 --retry-delay 60 $websource_binary | grep 'VLC for Mac (Universal Binary)' | sed -E 's/.*(\/\/get\.videolan\..*dmg).*/\1/g' | sed '1s/^/https:/' | sed 's/universal/intel64/g')
else
    echo "CRITICAL: unexpected return on get_systemarch()"
fi

curl -sL --connect-timeout 30 --retry 3 --retry-delay 60 -o /var/tmp/${app_friendlyname}.dmg $binary_link

if [[ ! -f /var/tmp/${app_friendlyname}.dmg ]]
then
    echo "ERROR: Download failed with $binary_link"
    write_log 0 "Failure occurred when attempt to download installer from $binary_link. Program exited."
    exit
fi

sudo xattr -rd com.apple.quarantine /var/tmp/${app_friendlyname}.dmg

write_log 3 "Mounting image from /var/tmp/${app_friendlyname}.dmg..."
hdiutil attach -quiet -nobrowse /var/tmp/${app_friendlyname}.dmg

if [[ ! -d "/Volumes/VLC media player/${app_name}" ]]
then
    echo "ERROR: Content $app_name not found in mounted location."
    write_log 0 "Content $app_name not found in mounted location. Program exited."
    exit
fi

handle_process "${app_name}" true

write_log 3 "Remove outdated binary at /Applications/${app_name}"
sudo rm -rf /Applications/${app_name}

write_log 3 "Copying app files from mounted volume to /Applications/${app_name}"
sudo cp -R "/Volumes/VLC media player/${app_name}" /Applications

write_log 3 "Unmounting image..."
hdiutil detach -quiet "/Volumes/VLC media player"

sudo xattr -rd com.apple.quarantine /Applications/${app_name}

sudo rm -rf /var/tmp/${app_friendlyname}.dmg

installed_version=$(/usr/bin/defaults read "/Applications/${app_name}/Contents/Info.plist" CFBundleVersion)
if [[ $installed_version != $compliant_version ]]
then
    echo "ERROR: Update process completed, but incompliant app version is still detected."
    write_log 1 "Update process completed, but ${app_friendlyname} with v$installed_version is still not on the latest release v$compliant_version. Program exited."
    exit
fi

echo "SUCCESS: ${app_friendlyname} successfully updated."
write_log 3 "Update process successfully completed, and ${app_friendlyname} is now on the latest/admin-designated version v$compliant_version. Program completed."
