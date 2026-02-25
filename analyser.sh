#!/bin/bash

# Function to check if the required tools are installed on the system
check_dependencies() {
    if ! command -v yt-dlp &> /dev/null
    then
        echo "Error: yt-dlp is missing. Please install it first."
        exit 1
    fi

    if ! command -v bc &> /dev/null
    then
        echo "Error: bc is missing. This is needed for the math calculations."
        exit 1
    fi
}

# Function to convert seconds into a human readable format
# This converts seconds into Hours:Minutes:Seconds
format_seconds() {
    local total_seconds=${1%.*}
    if [[ -z "$total_seconds" || "$total_seconds" -eq 0 ]]
    then
        echo "00:00:00"
        return
    fi

    local h=$((total_seconds / 3600))
    local m=$(( (total_seconds % 3600) / 60 ))
    local s=$((total_seconds % 60))
    printf "%02d:%02d:%02d\n" "$h" "$m" "$s"
}

# Function to calculate and show finishing times for different speeds
calculate_playback_times() {
    local total=$1
    echo "ESTIMATED WATCH TIME AT DIFFERENT SPEEDS"
    echo "--------------------------------------------------"

    # We use 'bc' for floating point division
    local s125=$(echo "scale=2; $total / 1.25" | bc)
    local s150=$(echo "scale=2; $total / 1.5" | bc)
    local s200=$(echo "scale=2; $total / 2.0" | bc)

    printf "Standard (1.00x): %s\n" "$(format_seconds "$total")"
    printf "Fast     (1.25x): %s\n" "$(format_seconds "$s125")"
    printf "Faster   (1.50x): %s\n" "$(format_seconds "$s150")"
    printf "Double   (2.00x): %s\n" "$(format_seconds "$s200")"
}

# The main logic to parse the playlist data
analyze_playlist() {
    local url=$1
    local total_seconds=0
    local count=0

    echo ""
    echo "Starting analysis. This might take a moment for large playlists."
    echo "--------------------------------------------------"
    printf "%-5s | %-10s | %s\n" "NUM" "DURATION" "TITLE"
    echo "--------------------------------------------------"

    # We use a pipe to read each line as soon as yt-dlp finds it
    # This is memory efficient because we do not save the whole list at once
    while IFS='|' read -r duration title
    do
        # If duration is null or not a number, we treat it as 0
        if [[ ! "$duration" =~ ^[0-9]+$ ]]
        then
            duration=0
        fi

        count=$((count + 1))
        total_seconds=$((total_seconds + duration))

        local time_str=$(format_seconds "$duration")

        # We print a clean row for every video found
        printf "[%03d] | %-10s | %-50.50s\n" "$count" "$time_str" "$title"

    done < <(yt-dlp --flat-playlist --quiet --print "%(duration)s|%(title)s" "$url")

    if [ "$count" -eq 0 ]
    then
        echo "No videos found. Please check the URL and try again."
        return
    fi

    echo "--------------------------------------------------"
    echo "SUMMARY"
    echo "Total Videos  : $count"
    echo "Total Duration: $(format_seconds "$total_seconds")"
    echo "--------------------------------------------------"

    calculate_playback_times "$total_seconds"
}

# Interactive loop for the user
start_program() {
    check_dependencies

    while true
    do
        echo ""
        echo "=================================================="
        echo "          PLAYLIST INSPECTOR TOOL"
        echo "=================================================="
        echo "Enter a YouTube playlist URL to begin."
        echo "Enter 'q' to quit the program."
        echo ""
        read -p "URL > " input

        if [[ "$input" == "q" || "$input" == "quit" ]]
        then
            echo "Thank you for using YT-Playlist-Analyser"
            break
        fi

        if [[ -z "$input" ]]
        then
            echo "Error: Input cannot be empty."
            continue
        fi

        analyze_playlist "$input"
    done
}

# Run the program
start_program
