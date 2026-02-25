#!/bin/bash

# Function to check if required tools are available
check_environment() {
    if ! command -v yt-dlp &> /dev/null
    then
        echo "Required tool 'yt-dlp' is not found. Please install it to proceed."
        exit 1
    fi

    if ! command -v bc &> /dev/null
    then
        echo "Required tool 'bc' is not found. This is needed for time calculations."
        exit 1
    fi
}

# Function to convert seconds into HH:MM:SS format
format_standard() {
    local seconds=${1%.*}
    if [ -z "$seconds" ] || [ "$seconds" -lt 0 ]; then seconds=0; fi

    local h=$((seconds / 3600))
    local m=$(( (seconds % 3600) / 60 ))
    local s=$((seconds % 60))
    printf "%02d:%02d:%02d" "$h" "$m" "$s"
}

# Function to convert seconds into a long human readable string
format_detailed() {
    local seconds=${1%.*}
    if [ -z "$seconds" ] || [ "$seconds" -lt 0 ]; then seconds=0; fi

    local h=$((seconds / 3600))
    local m=$(( (seconds % 3600) / 60 ))
    local s=$((seconds % 60))

    local output=""
    if [ "$h" -gt 0 ]; then output="$h hours "; fi
    if [ "$m" -gt 0 ]; then output="$output$m minutes "; fi
    if [ "$s" -gt 0 ]; then output="$output$s seconds"; fi

    if [ -z "$output" ]; then echo "0 seconds"; else echo "$output"; fi
}

# Function to display time stats for different speeds
display_speed_table() {
    local total=$1
    echo "COMPUTED WATCH TIMES"
    echo "--------------------------------------------------------------------------------"

    local speeds=("1.00" "1.25" "1.50" "2.00")

    for speed in "${speeds[@]}"
    do
        local calc_seconds=$(echo "scale=2; $total / $speed" | bc)
        local std=$(format_standard "$calc_seconds")
        local det=$(format_detailed "$calc_seconds")
        printf "%-10s | %-10s | %s\n" "${speed}x" "$std" "$det"
    done
}

# Function to analyze the playlist content
analyze_playlist() {
    local url=$1

    echo "Accessing playlist metadata..."

    # Improved metadata extraction
    # We use --get-filename as a trick to check if the URL is reachable/valid
    local meta
    meta=$(yt-dlp --flat-playlist --playlist-items 1 --print "playlist_title:%(playlist_title)s|channel:%(uploader)s" "$url" 2>/dev/null | head -n 1)

    if [ -z "$meta" ]
    then
        echo "Error: Unable to access the playlist. The URL may be invalid, private, or blocked."
        return
    fi

    local p_title=$(echo "$meta" | awk -F'playlist_title:|\\|channel:' '{print $2}')
    local p_owner=$(echo "$meta" | awk -F'\\|channel:' '{print $2}')

    echo "--------------------------------------------------------------------------------"
    echo "PLAYLIST INFO"
    echo "Title: ${p_title:-Unknown Playlist}"
    echo "Channel: ${p_owner:-Unknown Channel}"
    echo "--------------------------------------------------------------------------------"
    printf "%-5s | %-10s | %s\n" "ID" "TIME" "VIDEO TITLE"
    echo "--------------------------------------------------------------------------------"

    local total_seconds=0
    local count=0

    # Stream processing for memory efficiency
    while IFS='|' read -r duration title
    do
        # Ensure duration is a valid integer
        if [[ ! "$duration" =~ ^[0-9]+$ ]]; then duration=0; fi

        count=$((count + 1))
        total_seconds=$((total_seconds + duration))

        local time_label=$(format_standard "$duration")

        # No length limit on title to prevent cutoff
        printf "[%03d] | %-10s | %s\n" "$count" "$time_label" "$title"

    done < <(yt-dlp --flat-playlist --quiet --print "%(duration)s|%(title)s" "$url")

    if [ "$count" -eq 0 ]
    then
        echo "The analysis completed but no videos were found in this list."
        return
    fi

    echo "--------------------------------------------------------------------------------"
    echo "SUMMARY"
    echo "Total Videos Found: $count"
    echo "Total Duration    : $(format_standard "$total_seconds")"
    echo "Detailed Duration : $(format_detailed "$total_seconds")"
    echo "--------------------------------------------------------------------------------"

    display_speed_table "$total_seconds"
}

# Main interface
run_app() {
    check_environment

    while true
    do
        echo ""
        echo "================================================================================"
        echo "                         YT-PLAYLIST-ANALYSER"
        echo "================================================================================"
        echo "Please enter the YouTube playlist URL to begin the analysis."
        echo "To terminate the program, please type 'exit'."
        echo ""
        read -p "Input: " user_input

        if [[ "$user_input" == "exit" ]]
        then
            echo "Thank you for using YT-Playlist-Analyser. The session has ended."
            break
        fi

        if [[ -z "$user_input" ]]
        then
            echo "Notice: No input detected. Please provide a valid URL."
            continue
        fi

        analyze_playlist "$user_input"
    done
}

run_app
