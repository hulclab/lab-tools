use POSIX;
use Math::Round;
sub  trim { my $s = shift; $s =~ s/^\s+|\s+$//g; return $s };

open OUT, ">ExCAudioExtract.log";
$ffmpeg = "Y:\\Tools-Scripts-Documents-Manuals\\ffmpeg\\ffmpeg";
# $ffmpeg = "ffmpeg";
while (`"$ffmpeg" 2>&1` !~ /^ffmpeg version/) {
	print "ffmpeg not found! Please enter path to the executable.\n(e.g. c:\\Program Files\\ffmpeg\\bin)\n";
	$ffmpeg = <>;
	$ffmpeg = trim($ffmpeg)."\\ffmpeg";
}
$make_output_folder = `if not exist .\\ffmpeg_out\\NUL mkdir ffmpeg_out`;
@folders = <*>;
$output_format = "";
$format_extension = "";
$lgf_end_marker = "";
while(!$output_format) {
	print "Select output format: \n[1] MP3 (VBR)\n[2] WAV (uncompressed pcm)\n[3] only parse (see ExCAudioExtract.log)\n";
	$answer = <>;
	if($answer == 1) {
		$output_format = "-c:a libmp3lame -q 1";
		$format_extension = "mp3";
	}
	if($answer == 2) {
		$output_format = "-c:a pcm_s16le";
		$format_extension = "wav";
	}
	if($answer == 3) {
		$output_format = "NA";
		$format_extension = "";
	}
}
while(!$input_mode) {
	print "Select input mode: \n[1] video stimuli, until keypress \n[2] video stimuli, until next \n[3] composite stimuli\n";
	$answer = <>;
	if($answer == 1) {
		$lgf_start_marker = '^(\d+)\s+\d+\s+\d+\s+ContinueMessage (.*\.(avi|mpg))$';
		$lgf_end_marker = "Key pressed";
		$stimulus_xml = '<StimulusInformation GUID=".*?" Name="(.*)" Type=".*?" StimulusFile="(.*?\.(avi|mpg))".*>';
		$input_mode = "video";
	}
	if($answer == 2) {
		$lgf_start_marker = '^(\d+)\s+\d+\s+\d+\s+ContinueMessage (.*\.(avi|mpg))$';
		$lgf_end_marker = "(DoTheWork Start Movie|Experiment Execution Completed)";
		$stimulus_xml = '<StimulusInformation GUID=".*?" Name="(.*)" Type=".*?" StimulusFile="(.*?\.(avi|mpg))".*>';
		$input_mode = "video";
	}
	if($answer == 3) {
		$lgf_start_marker = '^(\d+)\s+\d+\s+\d+\s+ContinueMessage (.*\.(jpg))$';
		$lgf_end_marker = "(DoTheWork End Composite|Experiment Execution Completed)";
		$stimulus_xml = '<StimulusInformation GUID=".*?" Name="(.*)" Type=".*?" StimulusFile="(.*?\.(jpg))".*>';
		$input_mode = "composite";
	}
}
while(!$full_audio_decision) {
	print "Save full audio extraction file? [y/N]\n";
	$answer = <>;
	if($answer && $answer eq "y") {
		$full_audio_decision = 1;
	} else {
		$full_audio_decision = 2;
	}
}

# print $lgf_end_marker;
foreach (@folders) {
	next unless -d $_;
	if (/^(.+)\-\[.+\]$/) { # folder name starts with participant code followed by -[{GUID}]
		print OUT "Processing directory $_\n";
		$participant = $1;
		$stimlog = "$_/stimulus-log.xml";
		next unless -f -s $stimlog; # make sure we find a stimulus log file
		$dir = $_;
		opendir(DH, $dir);
		my @folderfiles = sort {(stat "$dir\\$a")[7] <=> (stat "$dir\\$b")[7]} readdir(DH);
		closedir(DH);
		foreach $file (@folderfiles) {
			next if($file !~ /.*\.lgf/i);
			$lgffile = $file;
		}
		$lgffile = "$_/$lgffile";
		next unless -f -s $lgffile; # make sure we find an lgf file
		foreach $file (@folderfiles) {
			next if($file !~ /.*\.mkv/i);
			$mkvfile = $file;
		}
		$mkvfile_ffmpeg = "$_\\$mkvfile";
		$mkvfile = "$_/$mkvfile";
		next unless -f -s $mkvfile; # make sure we find an mkv file
		open IN, $stimlog; # read stimulus log file to %stimlist
		%stimlist = ();
		@actions = ();
		if ($full_audio_decision == 1 && $output_format && $output_format ne 'NA') {
			push @actions, "$ffmpeg -i $mkvfile_ffmpeg -vn $output_format -y ffmpeg_out\\$participant-full-audio.$format_extension";
		}
		$sof = 1;
		$exclude_names = "Calibration|Validation|Instruction.*|Welcome.*|Blank.*|Fixation.*|Practice.*|Filler.*";
		$exclude_stimulus = "practice.*|filler.*";
		while (<IN>) {
			if ($input_mode eq "video" && /$stimulus_xml/i && $1 && $2 && $1 !=~ /$exclude_names/i && $2 !=~ /$exclude_stimulus/i) {
				$stimlist{$2} = $1;
			}
			if ($input_mode eq "composite" && /$stimulus_xml/i && $1 && $2 && $1 !=~ /$exclude_names/i && $2 !=~ /$exclude_stimulus/i) {
				$stimlist{$2} = $1;
			}
		}
		close IN;
		print OUT "Stimulus list:\n";
		print OUT "$_ $stimlist{$_}\n" for (keys %stimlist);
		if ($output_format) {
			open IN, $lgffile; # read lgf file and prepare times
			$recording_start = 0;
			$stimulus_name = "";
			$stimulus_start = 0;
			print OUT "Parse .LGF file:\n";
			while (<IN>) {
				if (/^(\d+)\s+\d+\s+\d+\s+Recording to .+mkv from.+/) {
					$recording_start = $1;
					print OUT "Recording starts @ $recording_start\n";
				}
				if (/$lgf_start_marker/i && $recording_start && $1 && $2 && $stimlist{$2} && !$stimulus_start) {
					$stimulus_start = $1 - $recording_start;
					$stimulus_start_formatted = strftime("%H:%M:%S", gmtime(floor(($stimulus_start) / 1000000)));
					$stimulus_start_formatted .= sprintf(".%.3d", round(($stimulus_start - floor(($stimulus_start) / 1000000) * 1000000) / 1000));
					$stimulus_name = $stimlist{$2};
					print OUT "Stimulus $stimulus_name starting @ $stimulus_start_formatted ($stimulus_start)\n";
				}
				if (/^(\d+)\s+\d+\s+\d+\s+.*$lgf_end_marker/ && $1 && $stimulus_name && $stimulus_start && $stimulus_start_formatted) {
					$stimulus_duration = $1 - $stimulus_start - $recording_start + 500000;
					$stimulus_duration_formatted = strftime("%H:%M:%S", gmtime(floor(($stimulus_duration) / 1000000)));
					$stimulus_duration_formatted .= sprintf(".%.3d", round(($stimulus_duration - floor(($stimulus_duration) / 1000000) * 1000000) / 1000));
					print OUT "Stimulus $stimulus_name ending after $stimulus_duration_formatted ($stimulus_duration)\n";
					push @actions, "$ffmpeg -ss $stimulus_start_formatted -i \"$mkvfile_ffmpeg\" -t $stimulus_duration_formatted -vn $output_format -y \"ffmpeg_out\\$participant-$stimulus_name.$format_extension\"";
					$stimulus_name = "";
					$stimulus_start = 0;
				}
			}
			close IN;
			if ($output_format ne 'NA') {
				print OUT "Processing audio:\n";
				print OUT $actions[$_].`$actions[$_]`."\n" for (keys @actions);
			}
		}
	}
}
close OUT;
print "All done! (press enter to quit)";
$answer = <>;
