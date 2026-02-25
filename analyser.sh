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
        echo "Required tool 'bc' is not found. This is needed for math."
        exit 1
    fi
}

# Function to convert seconds into HH:MM:SS
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

# Function to analyze the playlist content
analyze_playlist() {
    local url=$1

    echo "Accessing playlist metadata..."

    local meta
    meta=$(yt-dlp --flat-playlist --playlist-items 1 --print "playlist_title:%(playlist_title)s|channel:%(uploader)s" "$url" 2>/dev/null | head -n 1)

    if [ -z "$meta" ]
    then
        echo "Error: Unable to access the playlist. The URL may be invalid or private."
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
    local max_sec=0
    local min_sec=999999
    local max_title=""
    local min_title=""

    # Temporary file for storing the report
    local report_file="analysis_$(date +%Y%m%d_%H%M%S).txt"

    while IFS='|' read -r duration title
    do
        if [[ ! "$duration" =~ ^[0-9]+$ ]]; then duration=0; fi

        count=$((count + 1))
        total_seconds=$((total_seconds + duration))

        # Track longest and shortest
        if [ "$duration" -gt "$max_sec" ]; then max_sec=$duration; max_title=$title; fi
        if [ "$duration" -lt "$min_sec" ] && [ "$duration" -gt 0 ]; then min_sec=$duration; min_title=$title; fi

        local time_label=$(format_standard "$duration")
        printf "[%03d] | %-10s | %s\n" "$count" "$time_label" "$title" | tee -a "$report_file"

    done < <(yt-dlp --flat-playlist --quiet --print "%(duration)s|%(title)s" "$url")

    if [ "$count" -eq 0 ]; then echo "No videos found."; return; fi

    # Calculate Average
    local avg_sec=$(echo "$total_seconds / $count" | bc)

    # Prepare summary output
    {
        echo "--------------------------------------------------------------------------------"
        echo "DETAILED SUMMARY"
        echo "Total Videos     : $count"
        echo "Total Duration   : $(format_standard "$total_seconds")"
        echo "Detailed         : $(format_detailed "$total_seconds")"
        echo "Average Duration : $(format_standard "$avg_sec")"
        echo "Longest Video    : $(format_standard "$max_sec") - $max_title"
        echo "Shortest Video   : $(format_standard "$min_sec") - $min_title"
        echo "--------------------------------------------------------------------------------"
        echo "SPEED ANALYSIS"

        local speeds=("1.25" "1.50" "2.00")
        for speed in "${speeds[@]}"; do
            local calc=$(echo "scale=2; $total_seconds / $speed" | bc)
            printf "%-10s : %s (%s)\n" "${speed}x" "$(format_standard "$calc")" "$(format_detailed "$calc")"
        done
        echo "--------------------------------------------------------------------------------"
    } | tee -a "$report_file"

    echo "Analysis complete. A copy has been saved to: $report_file"
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

        if [[ "$user_input" == "exit" ]]; then
            echo "Thank you for using YT-Playlist-Analyser. The session has ended."
            break
        fi

        if [[ -z "$user_input" ]]; then
            echo "Notice: No input detected."
            continue
        fi

        analyze_playlist "$user_input"
    done
}

run_app
