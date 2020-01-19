dir2lpl v0.6 - Generate RetroArch playlists from a directory scan.

with dir2lpl [ options ] [directory ...] [system]
Options:
  -p    write relative path instead of exact drive letter in playlist
  -zip  build the games playlist from the zip filename (default)
  -rom  build the games playlist from the unzipped rom filenames
        or a single rom filename inside the zip files

Notes:
  [-rom]      calculates the crc32 values of each rom and larger files process longer
  [-zip]      reads the crc32 from the zip file header and is quicker
  [directory] should be the path to the games folder and contain backslash symbols
  [system]    must match a RetroArch database to properly configure system icons

Example:
              dir2lpl -p -rom "D:/ROMS/Atari - 2600" "Atari - 2600"

Author:
   Discord - Romeo#3620

