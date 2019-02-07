#
# Skript zum Auslesen vom SOT im DFG-Projekt
# Folgende Punkte sind zu beachten:
# 1. Es wird angenommen, dass alle Audioaufnahmen in wav-Format vorliegen
# 2. Es wird angenommen, dass alle wav-Dateien in einem Verzeichnis einem Probanden gehoeren
# 3. Diese Version gibt drei SOTs aus, basiert auf
#	- Intensitaet, Grenzwert ist durchschnittliche Intensitaet
#	- Intensitaet, Grenzwert ist durchschnittliche Intensitaet minus deren Standardabweichung
#	- Erster Pulse
#    Die Diagnosegrafik verdeutlicht dieses Vorgehen
# 4. Die SOT-Daten werden als CSV-Datei, die Diagnosegrafik als EPS-Datei mit dem Verzeichnisname (Probandenkennung)
#    im ausgewaehlten Ausgabeverzeichnis erstellt
# 5. SOT-Daten in Millisekunden (ms)
#
# Xingyu Zhu, 2013
# Entwickelt und getestet auf Praat Version 5.3.40 (x64 Windows)
#
#
# Modifications:
# - Graphic output as PNG file, external tools for generating PDF not needed anymore
# - option to point the script to a folder containing subfolders with wav files for each subject
#
# Takara Baumbach, 2019
# Entwickelt und getestet auf Praat Version 6.0.46 (x64 Windows)


# das praat-picutre-Fenster ist 12 inch x 12 inch
# bei x-groesse 2 und y-groesse 1 passen also (12/2) * (12/1) = 72 Grafiken ins Fenster
# sollte angepasst werden, falls die Anzahl der wav-Dateien im Verzeichnis stark davon abweicht
# sizex und sizey sollten Teiler von 12 sein (1 2 3 4 6 12)
sizex = 2
sizey = 1
countRow = 12 / sizey

inputDir$ = chooseDirectory$ ("Choose a directory to where the wav-files are located")

if inputDir$ <> ""
	Create Strings as directory list... dirList 'inputDir$'\*
else
	print 'Invalid directory.'
	exit
endif

select Strings dirList
noDir = Get number of strings
if noDir >= 1
	for dirIndex from 1 to noDir
		select Strings dirList
		dir$ = Get string... dirIndex
		dirname$ = inputDir$ + "\" + dir$
		@processDir: dirname$
	endfor
else
	@processDir: inputDir$
endif
select Strings dirList
Remove

procedure processDir: .dirname$
	print '.dirname$'

	#Praat picture leeren
	Erase all

	#Praat info leeren
	clearinfo

	#Header
	printline Item;SOT(Mean);SOT(Mean-sd);SOT(Pulse)

	Create Strings as file list... fileList '.dirname$'\*.wav
	select Strings fileList

	#Anzahl der wav-Dateien abfragen
	nos = Get number of strings

	for item from 1 to nos
		select Strings fileList
		filename$ = Get string... item

		Read from file... '.dirname$'\'filename$'
		sound = selected("Sound")
		name$ = selected$ ("Sound")

		#Bei Bedarf Ersetzung anwenden
		#name$ = replace$ (name$, "_", "\_", 0)

		#Position zum Zeichnen auswählen
		posx1 = sizex * ((item - 1) div countRow)
		posx2 = posx1 + sizex
		posy1 = sizey * ((item - 1) mod countRow)
		posy2 = posy1 + sizey
		Select inner viewport... posx1 posx2 posy1 posy2

		Silver
		Draw inner box
		Black

		#Filter: Rauschen entfernen
	#	Remove noise... 0.0 0.0 0.025 80 10000 40 Spectral subtraction
	#	Rename... denoised
	#	select Sound denoised

		#Pulse auslesen
		To PointProcess (periodic, cc)... 50 600
		firstPulse = Get time from index... 1
		Remove


		#Deemphase (sinnvoll?)
	#	Filter (de-emphasis)... 50.0
	#	Rename... deemphasis

		select sound

		#Oszillogram als Hintergrund zeichnen
		Silver
		Draw... 0.0 0.0 0.0 0.0 no Curve
		Black

		To Intensity... 50 0 yes
		Rename... intensity
		n = Get number of frames

		mean = Get mean... 0.0 0.0 energy
		sd = Get standard deviation... 0.0 0.0

		#Zwei moeglichen Grenzen fuer die SOT-Erkennung
		limit1 = mean
		limit2 = mean - sd
		endTime = Get end time

		#minimum und maximum auslesen fuer die y-achse
		minimum = Get minimum... 0.0 0.0 Sinc70
		maximum = Get maximum... 0.0 0.0 Sinc70

		#Intensitaetskurve
		Black
		Draw... 0.0 0.0 0.0 0.0 no

		#Line fuer die SOT nach erstem Pulse
		Red
		Draw line... 'firstPulse' minimum 'firstPulse' 'maximum'
		Black

		#Dateiname mit Schriftgroesse 10
		10
		Text... endTime Right maximum Top 'name$'

		#Linie fuer limit1, also mean
		Blue
		Draw line... 0.0 'limit1' 'endTime' 'limit1'
		Black

		#Linie fuer limit2, also mean - sd
		Green
		Draw line... 0.0 'limit2' 'endTime' 'limit2'
		Black


		#SOT nach mean
		for i to n
			intensity = Get value in frame... i
			if intensity >= limit1
			   time1 = Get time from frame... i
			   timeMS1 = time1 * 1000
			   goto end_of_for1
			endif
		endfor
		label end_of_for1

		#SOT nach mean - sd
		for i to n
			intensity = Get value in frame... i
			if intensity >= limit2
			   time2 = Get time from frame... i
			   timeMS2 = time2 * 1000
			   goto end_of_for2
			endif
		endfor
		label end_of_for2

		timeMS3 = firstPulse * 1000
		printline 'name$';'timeMS1:0';'timeMS2:0';'timeMS3:0'

		#Aufraeumen
	#	select Sound denoised
	#	Remove
	#	select Sound deemphasis
	#	Remove
		select Intensity intensity
		Remove
		select sound
		Remove

	endfor

	select Strings fileList
	Remove

	#Fuer die Speicherung von Praat Picture waehlen wir einfach das ganze Gebiet aus (12x12)
	Select inner viewport... 0 12 0 12
	Save as 600-dpi PNG file... '.dirname$'.png

	#Evtl. vorhandene CSV-Datei wird geloescht
	filedelete '.dirname$'.csv
	fappendinfo '.dirname$'.csv
endproc
