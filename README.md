# smi-tools
Tools for experiments and recorded data with _SMI ExperimentCenter_.

## KeypressLogMerge
Extracts keypress events from the recorded data folders' log files (**_participant id_-protocol.txt**). Available as python source or Windows executable build with _pyinstaller_ (see directory _dist/_).

### Usage
The tool can be placed either inside a recorded data folder of an experiment and run, or called from command-line with the path to the recorded data folder as parameter. It scans the given folder for participant data folders (with names in SMI format like **_participant id_-\[_GUID_\]/**), and for each folder, scans the **stimulus-log.xml** file for stimulus IDs, then scans the **_participant id_-protocol.txt** for keypress log entries, mapping each event to the corresponding stimulus event. The timestamp of each event will be recalculated relative to stimulus onset. The output is a CSV file with one row for each keypress event, that looks like the following:

    Subject ID;Stimulus Name;Stimulus time (ms);Key pressed
    s01;Filler1;7622.222;LeftCtrl
    s01;Filler2;7833.925;RightCtrl
    s01;Filler3;5040.534;Add
    s01;Target1;6912.452;Tab
    s01;Filler4;8002.461;A
    ...

## ahk scripts (ahk/)
[AutoHotKey](https://www.autohotkey.com/) script file to send **space key press** after pressing other keys (**LCtrl** and **RCtrl**, or **LShift** and **RShift** ). Used to allow continuing to next stimulus and recording subject decision at the same time in SMI ExperimentCenter. To allow usage of other keys, change the Key names in the scripts (valid key names can be found [here](https://www.autohotkey.com/docs/KeyList.htm)).

Use [KeypressLogMerge](#KeypressLogMerge) to analyze the resulting keypress logs of your experiment.

## Authors

* **Takara Baumbach** ([takb](https://github.com/takb))

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details
