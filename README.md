# YT Playlist Analyser

## Overview

YT Playlist Analyser is a Bash-based command line utility for analyzing YouTube playlists. It retrieves video metadata using yt-dlp, calculates the total playlist duration, and provides estimated watch times at different playback speeds.

The script is designed to be lightweight, memory efficient, and suitable for large playlists by streaming data directly from yt-dlp without storing the full dataset in memory.

---

## Features

- Validates required system dependencies before execution
- Streams playlist metadata without loading the entire list into memory
- Displays per video:
  - Sequential index number
  - Formatted duration in HH:MM:SS
  - Video title
- Calculates total playlist duration
- Provides estimated completion times at:
  - 1.00x
  - 1.25x
  - 1.50x
  - 2.00x
- Interactive CLI loop for multiple playlist analyses

---

## Dependencies

This script requires the following tools to be installed on your system:

- yt-dlp  
- bc  
- Bash shell  

---

## Installing Dependencies

### Debian and Ubuntu

```bash
sudo apt update
sudo apt install yt-dlp bc
```

---

### Fedora

```bash
sudo dnf install yt-dlp bc
```

If yt-dlp is not available in your enabled repositories:

```bash
sudo dnf install python3-pip
pip install -U yt-dlp
```

---

### Arch Linux and Manjaro

```bash
sudo pacman -S yt-dlp bc
```

---

### openSUSE

```bash
sudo zypper install yt-dlp bc
```

---

### Alpine Linux

```bash
sudo apk add yt-dlp bc
```

---

### Android Terminal using Termux

1. Install Termux from F-Droid.
2. Update packages:

```bash
pkg update
pkg upgrade
```

3. Install dependencies:

```bash
pkg install yt-dlp bc
```

If yt-dlp is unavailable:

```bash
pkg install python
pip install -U yt-dlp
```

You can then clone and run the script normally inside Termux.

---

## Installation

1. Clone this repository:

```bash
git clone https://github.com/harshit2k4/YT-Playlist-Analyser.git
cd YT-Playlist-Analyser
```

2. Make the script executable:

```bash
chmod +x analyser.sh
```

3. Run the script:

```bash
./analyser.sh
```

---

## Usage

When executed, the program starts an interactive prompt:

```
YT Playlist Analyser
Enter a YouTube playlist URL to begin.
Enter 'q' to quit the program.
```

Enter a valid YouTube playlist URL. The tool will:

1. Retrieve playlist entries using yt-dlp  
2. Display each video's duration and title  
3. Calculate the total number of videos  
4. Display total playlist duration  
5. Show estimated watch times at different playback speeds  

To exit the program, enter:

```
q
```

or

```
quit
```

---

## Output Example

```
NUM   | DURATION   | TITLE
--------------------------------------------------
[001] | 00:10:35   | Introduction to Topic
[002] | 00:08:42   | Deep Dive into Concept
...

SUMMARY
Total Videos  : 25
Total Duration: 05:42:18

ESTIMATED WATCH TIME AT DIFFERENT SPEEDS
Standard (1.00x): 05:42:18
Fast     (1.25x): 04:33:44
Faster   (1.50x): 03:48:12
Double   (2.00x): 02:51:09
```

---

## Technical Details

### Dependency Validation

The script verifies that:

- yt-dlp is installed  
- bc is installed for floating point calculations  

If a dependency is missing, the program exits with an error message.

### Duration Formatting

Durations are converted from seconds to a human readable HH:MM:SS format.

### Memory Efficiency

Playlist data is processed line by line using process substitution:

```bash
while IFS='|' read -r duration title
```

This approach avoids storing the full playlist in memory and ensures efficient handling of large playlists.

---

## Limitations

- Only publicly accessible playlists are supported  
- Internet connectivity is required  
- The tool relies on yt-dlp output format  
- Private or restricted videos may report zero duration  
