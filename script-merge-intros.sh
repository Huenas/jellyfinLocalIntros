#!/bin/bash

# Films directory
films_directory="$FILMS_DIRECTORY"
# Series directory
series_directory="$SERIES_DIRECTORY"

# Intro directory
intro_directory="$INTRO_DIRECTORY"

# Absolute path of the script directory
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# File tracking movies with added intros
intro_added_file="$script_dir/intro_added.txt"

# File tracking errors
error_log_file="$script_dir/error_log.txt"

# Function to log errors
log_error() {
    local message="$1"
    echo "$(date +'%Y-%m-%d %H:%M:%S') - ERROR: $message" >> "$error_log_file"
}

# Function to merge intro with a video file
merge_intro() {
    local input_file="$1"
    local output_file="${input_file%.*}_avec_intro.mkv"

    # Check if intro was added to the file
    if grep -Fxq "$input_file" "$intro_added_file"; then
        return
    fi

    # Check if the folder has an intro
    if ffprobe -loglevel error -show_entries format_tags=title -of default=noprint_wrappers=1:nokey=1 "$input_file" | grep -q "avec_intro"; then
        return
    fi

    # Add the file to the intro added file
    echo "$input_file" >> "$intro_added_file"

    # Create a temporary file of files to join
    echo "file '$intro_directory/video.mkv'" > temp_list.txt
    echo "file '$input_file'" >> temp_list.txt

    # Concatenate
    ffmpeg -f concat -safe 0 -i temp_list.txt -c copy "$output_file" > /dev/null 2>&1

    if [ $? -ne 0 ]; then
        log_error "Error merging intro with $input_file."
    else
        rm temp_list.txt

        # Replace the original file with the file with the intro
        mv -f "$output_file" "$input_file" > /dev/null 2>&1
    fi
}

# Function to process files in a directory
process_files() {
    local directory="$1"
    for file in "$directory"/*; do
        if [ -f "$file" ]; then
            merge_intro "$file"
        fi
    done
}

# Infinite loop to monitor directories
while true; do
    process_files "$films_directory"
    process_files "$series_directory"
    sleep 5
done

