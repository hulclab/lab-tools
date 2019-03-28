# lab-tools
Tools for experiments and analysis of recorded data, including tools for processing data recorded with _SMI ExperimentCenter_.
* [SpeechOnsetTimes](#SpeechOnsetTimes) - measure speech onset times in `.wav` files
* [ExCAudioExtract](#ExCAudioExtract) - extract `.wav` or `.mp3` files from _SMI ExperimentCenter_ recorded data folders for each subject/stimulus
* [KeypressLogMerge](#KeypressLogMerge) - extract keypress log entries and map them to the corresponding stimulus, from _SMI ExperimentCenter_ recorded data folders for each subject
* [ahk scripts](#ahk-scripts) - workaround for some experimental setups where you need keypress events or mouse click events to trigger stimulus advancement in _SMI ExperimentCenter_

---
## SpeechOnsetTimes ([praat/](tree/master/praat/))
[Praat](http://www.fon.hum.uva.nl/praat/) script file to analyze SOT from a set of `.wav` files. Most useful in conjunction with [ExCAudioExtract](#ExCAudioExtract).

#### Usage
* Run Praat (get the latest version [here](http://www.fon.hum.uva.nl/praat/), tested with version 6.0.46/win64).
* Open script ("Praat Objects" window main menu -> Praat -> Open Praat script...) and run (on the script window, main menu -> Run -> Run or Ctrl-R).
* Point to location of audio files to analyze. Selected directory should either contain only a set of `.wav` files, or subdirectories containing a set of `.wav` files each.
* Output:
  1. CSV file with measured SOT data that looks like the following:

          Item;SOT(Mean);SOT(Mean-sd);SOT(Pulse)
          C03-G01;7798;6358;7804
          C03-G02;5842;130;173
          C03-G03;7895;7239;7915
          C03-G04;5330;5058;5328
          C03-G05;5283;3059;5294
      "Item" is derived from the audio file name and should contain some form of identifier that allows you to map the data to a specific subject-stimulus pair (i.e., name your audio files accordingly), and the three following columns contain the measured time from the beginning of the file to the speech onset (measured/estimated with three methods, see below).
  2. Image file with graphs representing the wave signature of each audio file with lines signalling the measured times of the speech onset.

      ![graph examples](doc/praat_graph.png)

      The blue line represents the mean intensity level of the sound file; the green line represents the level of mean minus standard deviation intensity; the red line represents the timing of the first pulse measured by Praat's pulse detection (See below for details).

  If you point the tool to a directory with audio files, one set of output files will be generated in the parent directory of that directory, named `[directory name].csv` and `[directory name].png` respectively; if the directory contains subdirectories, the tools expects those to contain a set of audio files each, and produces a set of output files each.
* The tool estimates SOT by three methods and returns times in milliseconds from beginning of audio file. The first two values are calculated by looking for the first frame where audio intensity exceeds the mean intensity or mean intensity minus standard deviation respectively (measured over the whole file). The third value is determined by Praat's [glottal pulse detection](http://www.fon.hum.uva.nl/praat/manual/Voice.html) algorithm. Depending on the recording quality of your audio file in terms of amount of signal noise and ambient noise, any or none of these methods may produce accrate results. To check on the quality, you should always look at the generated graphs (PNG files) before choosing the value you want to use for further analysis.
* Limitations: The graphs image cannot contain more than 72 graphs. Make sure to have no more than 72 audio files in each data folder before using the script. Furthermore, big audio file sizes might lead to high memory consumtion (and Praat program crashes). Make sure to cut the audio files in reasonably sized chunks, e.g. by using the [ExCAudioExtract](#ExCAudioExtract) tool.

#### Credits
This tool was originally created by former HULC Lab member **Xingyu Zhu**.

---
## ExCAudioExtract
Tool for extracting Audio files form _SMI ExperimentCenter_ recorded data folders. Available as Perl source or Windows executable built with [pp](https://metacpan.org/pod/PAR::Packer) (see directory [dist/](tree/master/dist/)).

#### Usage
Run within an _SMI ExperimentCenter_ recorded data folder. Requires [ffmpeg](https://www.ffmpeg.org/download.html).

- If ffmpeg is not found in %path%, prompts for path to executable.
- Creates folder ffmpeg_out where all output files are stored.
- Creates file `ExCAudioExtract.log` where all detected stimuli (presentaion order), times and actions are logged.
##### Program steps:
- Prompts for output format, currently
  - [1] MP3 (VBR)
  - [2] WAV (uncompressed pcm)
  - [3] no audio (only parse)
- Prompts for input format, currently 
  - [1] video stimuli, until keypress
  - [2] video stimuli, until next
  - [3] composite stimuli
- Prompts for output of full audio stream. Enter `y` to generate an audio file from the whole .mkv file, defaults to `n`.
- For every subdirectory with name matching `{participant ID}-[{GUID}]`:
  - Extracts stimulus information from `stimulus-log.xml`, skips subdirectory if not available.
  - Extracts timing information from `.lgf` file. End times are detected either by looking for a keypress event (useful if video stimulus is automatically followed by e.g. a blank screen, where subjects may continue speaking) or end of stimulus. + 500ms
  - Ignores stimuli where the Stimulus name matches  `Calibration|Validation|Instruction.*|Welcome.*|Blank.*|Fixation.*|Practice.*|Filler.*` or file name matches `practice.*|filler.*`
  - Extracts audio stream from .mkv file and creates 
    - `{participant ID}-full-audio.(wav|mp3)` file for each subject if instructed to
    - `{participant ID}-{stimulus name}.(wav|mp3)` file for each relevant stimulus found    

#### Known issues
- If multiple .lgf files are found, uses the largest file available - make sure that is the correct file!
- If .mkv audio stream is shorter than logged stimulus time(s), produces invalid .wav files - make sure to 
  remove .wav files with size of ~1Kb before feeding the results to the SOT finder!
---
## KeypressLogMerge
Extracts keypress events from the recorded data folders' log files (`{participant ID}-protocol.txt`). Available as python source or Windows executable built with _pyinstaller_ (see directory [dist/](tree/master/dist/)).
#### Usage
The tool can be placed either inside a recorded data folder of an experiment and run, or called from command-line with the path to the recorded data folder as parameter. It scans the given folder for participant data folders (with names in SMI format like `{participant ID}-[{GUID}]`), and for each folder, scans the `stimulus-log.xml` file for stimulus IDs, then scans the `{participant ID}-protocol.txt` for keypress log entries, mapping each event to the corresponding stimulus event. The timestamp of each event will be recalculated relative to stimulus onset. The output is a CSV file with one row for each keypress event, that looks like the following:

    Subject ID;Stimulus Name;Stimulus time (ms);Key pressed
    s01;Filler1;7622.222;LeftCtrl
    s01;Filler2;7833.925;RightCtrl
    s01;Filler3;5040.534;Add
    s01;Target1;6912.452;Tab
    s01;Filler4;8002.461;A
    ...

---
## ahk scripts ([ahk/](tree/master/ahk/))
[AutoHotKey](https://www.autohotkey.com/) script file to send **space key press** after pressing other keys (**LCtrl** and **RCtrl**, or **LShift** and **RShift** ). Used to trigger stimulus advancement and record subject decision at the same time in _SMI ExperimentCenter_. To allow usage of other keys, change the Key names in the scripts (valid key names can be found [here](https://www.autohotkey.com/docs/KeyList.htm)).

In some cases, keyboard events are not correctly displayed during result analysis in _SMI BeGaze_ or during export of event data. In these cases, Use [KeypressLogMerge](#KeypressLogMerge) to analyze the resulting keypress logs of your experiment.

## Authors

* **Takara Baumbach** ([takb](https://github.com/takb))
* **Xingyu Zhu** (SpeechOnsetTime praat script)

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details
