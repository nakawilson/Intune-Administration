#!/bin/bash

# Function to check the app version
check_app_version() {
    app_name="$1"
    app_path="/Applications/${app_name}.app"

    if [ -d "$app_path" ]; then
        /usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$app_path/Contents/Info.plist"
    else
        echo "${app_name} is not installed."
    fi
}

# Example usage
app_name="Windows App"
app_version=$(check_app_version "$app_name")

# Summarize results
if [ "$app_version" != "${app_name} is not installed." ]; then
    echo "${app_name} version: $app_version"
else
    echo "$app_version"
fi
