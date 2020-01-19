use strict;
use warnings;
use Archive::Zip qw/:ERROR_CODES :CONSTANTS/;
use Digest::CRC qw(crc64 crc32 crc16 crcccitt crc crc8 crcopenpgparmor);
use Term::ProgressBar;

#init
my $relative = "FALSE";
my $substring = "-p";
my $substringh = "-h";
my $substringr = "-rom";
my $listname = "ZIP";
my $directory = "";
my $system = "";

#check command line
foreach my $argument (@ARGV) {
  if ($argument =~ /\Q$substringh\E/) {
    print "dir2lpl v0.6 - Generate RetroArch playlists from a directory scan. \n";
	print "\n";
	print "with dir2lpl [ options ] [directory ...] [system]";
    print "\n";
	print "Options:\n";
	print "  -p    write relative path instead of exact drive letter in playlist\n";
	print "  -zip  build the games playlist from the zip filename (default)\n";
	print "  -rom  build the games playlist from the unzipped rom filenames\n";
	print "        or a single rom filename inside the zip files\n";
    print "\n";
	print "Notes:\n";
	print "  [-rom]      calculates the crc32 values of each rom and larger files process longer\n";
	print "  [-zip]      reads the crc32 from the zip file header and is quicker\n";
	print "  [directory] should be the path to the games folder and contain backslash symbols\n";
	print "  [system]    must match a RetroArch database to properly configure system icons\n";
	print "\n";
	print "Example:\n";
	print '              dir2lpl -p -rom "D:/ROMS/Atari - 2600" "Atari - 2600"' . "\n";
	print "\n";
	print "Author:\n";
	print "   Discord - Romeo#3620\n";
	print "\n";
    exit;
  }
  if ($argument =~ /\Q$substring\E/) {
    $relative = "TRUE";
  }
    if ($argument =~ /\Q$substringr\E/) {
    $listname = "ROM";
  }
}

#set directory and system variables
if (scalar(@ARGV) < 2 or scalar(@ARGV) > 4) {
  print "Invalid command line.. exit\n";
  print "use: dir2lpl -h\n";
  print "\n";
  exit;
}
$directory = $ARGV[-2];
$system = $ARGV[-1];

#debug
print "relative path: $relative\n";
print "game names from: $listname\n";
print "directory: $directory\n";
print "system: $system\n";

#exit no parameters
if ($system eq "" or $directory eq "") {
  print "Invalid command line.. exit\n";
  print "use: dir2lpl -h\n";
  print "\n";
  exit;
}

#init output files
my @linesf;
my $playlist = "$system" . ".lpl";

#read games directory to @linesf
my $dirname = $directory;
opendir(DIR, $dirname) or die "Could not open $dirname\n";
while (my $filename = readdir(DIR)) {
  push(@linesf, $filename) unless $filename eq '.' or $filename eq '..';
}
closedir(DIR);

#init varibles for playlist
my $version = '  "version": "1.2",';
my $default_core_path = '  "default_core_path": "",';
my $default_core_name = '  "default_core_name": "",';
my $label_display_mode = '  "label_display_mode": 0,';
my $right_thumbnail_mode = '  "right_thumbnail_mode": 0,';
my $left_thumbnail_mode = '  "left_thumbnail_mode": 0,';
my $items = '  "items": [';
my $romname = '';
my $zipfile = '';

#write playlist header
open(FILE, '>', $playlist) or die "Could not open file '$playlist' $!";
print FILE "{\n";
print FILE "$version\n";
print FILE "$default_core_path\n";
print FILE "$default_core_name\n";
print FILE "$label_display_mode\n";
print FILE "$right_thumbnail_mode\n";
print FILE "$left_thumbnail_mode\n";
print FILE "$items\n";
my $endoflist = $linesf[-1];
my $gamefile;
my $gamepath;
my $path;
my $ctx = Digest::CRC->new( type => 'crc32' );
my $max = scalar(@linesf);
my $progress = Term::ProgressBar->new({name => 'progress', count => $max});
my $crc;
my $romcrc;

#print each game from @lines to playlist file
foreach my $element (@linesf) {
  $progress->update($_);
  $gamefile = $element;
  $gamepath = $dirname;
  #check parameter rom files outside zip
  if ($listname eq "ROM" and substr($gamefile, -4) !~ '.zip') {
    #calculate CRC of rom file
	my $crcfilename = "$gamepath" . "\\" . "$gamefile";
	open (my $fh, '<:raw', $crcfilename) or die $!;
    $ctx->addfile(*$fh);
    close $fh;
    $crc = $ctx->hexdigest;
	if ($relative eq "FALSE") {
      $path = '      "path": ' . '"' . "$gamepath/" . "$gamefile" . '",';
    }
    else {
      $path = '      "path": ' . '"..' . substr($gamepath,2,length($gamepath),"") .  "/" . "$gamefile" . '",';
    }
    my $name = substr $gamefile, 0, -4;
    my $label = '      "label": "' . "$name" . '"' . ',';
    my $core_path = '      "core_path": "DETECT",';
    my $core_name = '      "core_name": "DETECT",';
    my $crc32 = '      "crc32": "' . "$crc" . '|crc"' . ',';
    my $db_name = '      "db_name": "' . "$system" . '.rdb"';
    print FILE "    {\n";
    print FILE "$path\n";
    print FILE "$label\n";
    print FILE "$core_path\n";
    print FILE "$core_name\n";
    print FILE "$crc32\n";
    print FILE "$db_name\n";
    if ($element eq $endoflist){
      print FILE "    }\n";
    } else {
      print FILE "    },\n";
    }
  #check paramter zip name and rom files inside zip
  } elsif ($listname eq "ZIP" and substr($gamefile, -4) eq '.zip') {
	   $zipfile = "$gamepath" . '/' . "$gamefile";
	   #print "$zipfile\n";
       my $zip = Archive::Zip->new();
       $zip->read($zipfile);
	   my @files = $zip->memberNames();  # Lists all members in archive
       if (scalar @files >= 2) {
	        print "More than one file in archive.. exit\n";
	        print "\n";
	        exit;
	   }
	
	   $romname = $files[0];
	   for my $zfile ($zip->members) {
	        my $fh = IO::File->new_tmpfile or die "Unable to create temp file: $!\n";
            $fh->binmode;
            seek( $fh, 0, 0 );
            $crc = $zfile->crc32String();
       }

       $romcrc = $crc;
       my $zipfile = "$gamepath" . '/' . "$gamefile";
       if ($relative eq "FALSE") {
            $path = '      "path": ' . '"' . "$zipfile" . "#" . "$romname" . '",';
       } else {
            $path = '      "path": ' . '"..' . substr($zipfile,2,length($zipfile),"") . "#" . "$romname" . '",';
       }
       my $name = substr $gamefile, 0, -4;
       my $label = '      "label": "' . "$name" . '"' . ',';
       my $core_path = '      "core_path": "DETECT",';
       my $core_name = '      "core_name": "DETECT",';
       my $crc32 = '      "crc32": "' . "$romcrc" . '|crc"' . ',';
	   my $db_name = '      "db_name": "' . "$system" . '.rdb"';
       print FILE "    {\n";
       print FILE "$path\n";
       print FILE "$label\n";
       print FILE "$core_path\n";
       print FILE "$core_name\n";
       print FILE "$crc32\n";
       print FILE "$db_name\n";
       if ($element eq $endoflist){
              print FILE "    }\n";
       } else {
              print FILE "    },\n";
       }
  #check parameter rom name and rom files inside zip
  } elsif ($listname eq "ROM" and substr($gamefile, -4) eq '.zip') {
       $zipfile = "$gamepath" . '/' . "$gamefile";
       my $zip = Archive::Zip->new();
       $zip->read($zipfile);
	   my @files = $zip->memberNames();  # Lists all members in archive
       if (scalar @files >= 2) {
	        print "More than one file in archive.. exit\n";
	        print "\n";
	        exit;
	   }
	
	   $romname = $files[0];
	   for my $zfile ($zip->members) {
	        my $fh = IO::File->new_tmpfile or die "Unable to create temp file: $!\n";
            $fh->binmode;
            seek( $fh, 0, 0 );
            $crc = $zfile->crc32String();
       }
  
       $romcrc = $crc;
       if ($relative eq "FALSE") {
            $path = '      "path": ' . '"' . "$zipfile" . "#" . "$romname" . '",';
       } else {
            $path = '      "path": ' . '"..' . substr($zipfile,2,length($zipfile),"") . "#" . "$romname" . '",';
       }
       my $name = substr $romname, 0, -4;
       my $label = '      "label": "' . "$name" . '"' . ',';
       my $core_path = '      "core_path": "DETECT",';
       my $core_name = '      "core_name": "DETECT",';
       my $crc32 = '      "crc32": "' . "$romcrc" . '|crc"' . ',';
	   my $db_name = '      "db_name": "' . "$system" . '.rdb"';
       print FILE "    {\n";
       print FILE "$path\n";
       print FILE "$label\n";
       print FILE "$core_path\n";
       print FILE "$core_name\n";
       print FILE "$crc32\n";
       print FILE "$db_name\n";
       if ($element eq $endoflist){
              print FILE "    }\n";
       } else {
              print FILE "    },\n";
       }
  }  
}

#write the end of the playlist
print FILE "  ]\n";
print FILE "}\n";
close FILE;
