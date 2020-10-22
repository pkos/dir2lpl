dir2lpl v1.2 - Generate RetroArch playlists from a directory scan.

with dir2lpl [ options ] [directory ...] [system]
Options:
  -p    write relative path instead of exact drive letter in playlist
  -zip  build the games playlist from the zip filename (default)
  -rom  build the games playlist from the unzipped rom filenames
        or a single rom filename inside the zip files, overridden by chosen extenstions
  -ext=[comma separated list] will only include the files with the chosen
        extensions for the playlist file

Notes:
  [-rom]      calculates the crc32 values of each rom: gcz, cso, chd, wbfs and iso are skipped
  [-zip]      reads the crc32 from the zip file header
  [directory] should be the path to the games folder
  [system]    must match a RetroArch database to properly configure system icons

Example:
              dir2lpl -p -rom -ext=bin,a26 "D:/ROMS/Atari - 2600" "Atari - 2600"

Author:
   Discord - Romeo#3620