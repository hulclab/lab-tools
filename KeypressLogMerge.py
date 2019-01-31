# HULC Lab SMI recorded data keypress log merger
# Licensed under GPL3: https://opensource.org/licenses/GPL-3.0
# https://github.com/hulclab/smi-tools

import glob
import re
import csv
import argparse
import os

parser = argparse.ArgumentParser(description='Process SMI recorded data and extracs keypress from logs.')
parser.add_argument('source', help='path to recorded data folder', nargs="?", default=".")
args = parser.parse_args()

stimulus_re = re.compile("<StimulusInformation GUID=\"(.+)\" Name=\"(.*?)\".*/>")
stimulus_data = {}
for source_file in glob.glob(args.source + "/*/stimulus-log.xml"):
    participant_id = re.match(r"(.*)-\[.*\].*", os.path.basename(os.path.normpath(os.path.dirname(source_file)))).group(1)
    if participant_id not in stimulus_data:
        stimulus_data[participant_id] = {}
    try:
        for l in [line.strip() for line in open(source_file)]:
            match = stimulus_re.match(l)
            if match:
                stimulus_data[participant_id][match.group(1)] = match.group(2)
    except FileNotFoundError:
        print("Could not open file: " + source_file)
        continue
print("Recorded data for %s participants found." % len(stimulus_data.keys()),  flush=True)

if (len(stimulus_data.keys())):
    print("Processing logs...", end="", flush=True)
    stimulus_re = re.compile(r"(\d+)\tET_REM ExC:StimulusId (.*)")
    keypress_re = re.compile(r"(\d+)\tET_REM UE-keypress (.*)")
    result = []
    for source_file in glob.glob(args.source + "/*/*-protocol.txt"):
        participant_id = re.match(r"(.*)-\[.*\].*", os.path.basename(os.path.normpath(os.path.dirname(source_file)))).group(1)
        try:
            current_stimulus = ""
            current_stimulus_start = 0
            for l in [line.strip() for line in open(source_file)]:
                match = stimulus_re.match(l)
                if match:
                    current_stimulus = match.group(2)
                    current_stimulus_start = int(match.group(1))
                match = keypress_re.match(l)
                if match and current_stimulus:
                    result.append((participant_id, stimulus_data[participant_id][current_stimulus], (int(match.group(1)) - int(current_stimulus_start)) / 1000, match.group(2)))
        except FileNotFoundError:
            print("Could not open file: " + source_file)
            continue
        print(".", end="", flush=True)

    print(" done.\nWriting results to keypress_log.csv", flush=True)
    with open("keypress_log.csv", 'w') as targetfile:
        try:
            target = csv.writer(targetfile, delimiter=";", lineterminator="\n")
            target.writerow(["Subject ID", "Stimulus Name", "Stimulus time (ms)", "Key pressed"])
            for row in result:
                target.writerow(row)
        except csv.Error as e:
            print('CSVError: {}'.format(e))
print("All done.", flush=True)
