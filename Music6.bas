


'music6: music box that went to Bartons
'change filename to bsx to flash onto Parallax basic stamp

by John Ross

'potentiometer#	port#	values			wire color
'~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
potIO1	con	0	' 10k, 0.047uF		gray
potIO2	con	2	' 500k, 0.0033uF	red
potIO3	con	1	' 500k, 0.0033uF	orange
potIO4	con	3	' 10k, 0.047uf		blue
potIO5	con	4	' 10k, 0.047uF		violet
potIO6	con	5	' 500k, 0.0033uF	brown
potIO7	con	6	' 10k, 0.047uF		green
potIO8	con	7	' 25k, 0.022uF		yellow

'R to ground is pot
'C to ground
'560 Ohm to port on SX2 computer

speaker	con	12	' through 150 Ohm resistor to 4 Ohm speaker to ground
			'   The speaker supplies all of the voicing -so-
			'	31/2" full-range with good magnet + enclosure
			'	good to very highs (bells).

'stepper is on 8,9,10,11: "outC"


'variable		scale	range	function

pot1scale	con	21	'0-30	note/phrase offset in key+scale
pot2scale	con	184	'0-20	select function within gizmo
pot3scale	con	167	'0-20	select function within gizmo
pot4scale	con	120	'0-5	octave
pot5scale	con	28	'0-20	duration/rate
pot6scale	con	520	'0-5	gizmo 
pot7scale	con	68	'0-8	scale type select
pot8scale	con	59	'0-12	key


'pot7 scales;

'value	scale

'0	minor pent
'1	major pent
'2	major triad
'3	minor triad with optional 7th
'4	diminished
'5	minor
'6	major
'7	12 note octave (all)


'..................................................................

potscratch	var	word
pot1		var	byte
pot2		var	byte
pot3		var	byte
pot4		var	byte
pot5		var	byte
pot6		var	byte
pot7		var	byte
pot8		var	byte
potslast	var	byte	'checksum to detect movement of any control
pot1use		var	byte	'interpolating/integrating value of pot1

noteS	var	byte		'note in scale+key
noteSS	var	byte		'another note in scale+key

note1	var	word		'note in frequency in Hz
note2	var	word		'another note in frequency in Hz

duration var	word	'duration of "noteS" (looked-up into "note1")
			'	and "noteSS" (looked-up into "note2")
			' or of any output tones

offset	var	 byte	'offset within scale+key

modulus var	nib	'number of notes in chosen scale
			'	used local in "getnote"
			'	not used in loops through again
			'	nor in for-next loops

scratch var byte	 
scratch2 var byte
scratch3 var byte	'position within phrase: could be NIBble if 16 max
scratch4 var byte

stepperphase var nib	'count modulo3 of stepper phase rotation
			

'=========================================================================

duration = 200

low outC		'turn off all stepper drive
dirC = 15		'make as outputs

'figure-out which way to go at reset;
high potIO1
pause 30
rctime potIO1,1,potscratch
if potscratch/pot1scale>14 then sweepupatstart
pot1use = 30  'sweep down at start
sweepupatstart:

'###################################################
again:
'read pots and sliders;

'"potscratch" used local

'uncommentout (remove "'"s) the following debugs to display pots;
'recommentout when done
'VERY IMPORTANT to recommentout everything when done (debug makes pause)

rctime	potIO1,1,potscratch	'has "home" screen command for other debugs
high	potIO1
'debug home,"pot1",tab,dec potscratch, tab, dec pot1scale,tab
pot1 = (potscratch/pot1scale)max 30
'debug cr, dec pot1,tab

rctime	potIO2,1,potscratch
'debug cr,"pot2",tab,dec potscratch, tab, dec pot2scale,tab
high	potIO2
pot2 = (potscratch/pot2scale)max 20
'debug cr, dec pot2,tab

rctime	potIO3,1,potscratch
'debug cr,"pot3",tab,dec potscratch, tab, dec pot3scale,tab
high	potIO3
pot3 = (potscratch/pot3scale)max 20
'debug cr, dec pot3,tab

rctime	potIO4,1,potscratch
'debug home,"pot4",tab,dec potscratch, tab, dec pot4scale,tab
high	potIO4
pot4 = (potscratch/pot4scale)max 5
'debug cr, dec pot4,tab

rctime	potIO5,1,potscratch
'debug cr,"pot5",tab,dec potscratch, tab, dec pot5scale,tab
high	potIO5
pot5 = (potscratch/pot5scale)max 20
'debug cr, dec pot5,tab


rctime	potIO6,1,potscratch
'debug cr,"pot6",tab,dec potscratch, tab, dec pot6scale,tab
high	potIO6
pot6 = (potscratch/pot6scale)max 5
'debug cr, dec pot6,tab

rctime	potIO7,1,potscratch
'debug cr,"pot7",tab,dec potscratch, tab, dec pot7scale,tab
high	potIO7
pot7 = (potscratch/pot7scale)max 8
'debug cr, dec pot7,tab

rctime	potIO8,1,potscratch
'debug cr,"pot8",tab,dec potscratch, tab, dec pot8scale,tab
high	potIO8
pot8 = (potscratch/pot8scale)max 12
'debug cr, dec pot8,tab


'.....................................................................

'"potslast" used in loops through "again"; do not corrupt

if pot1+pot2+pot3+pot4+pot5+pot6+pot7+pot8 = potslast  then again

'.....................................................................

'"stepperphase" used in loops through "again"; donna corrupta

outc = dcd (stepperphase & 3)
'debug cr,dec dcd (stepperphase & 3)

'.....................................................................

branch pot6,[voices,voices2,slidekey,slideruns,cycles,cycles2]


'{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{

'gizmos;

'"potslast" used in loops through "again"; do not corrupt unless non-stop
'"pot1use" used in loops through "again"; do not corrupt
'"stepperphase" used in loops through "again"; donna corrupta
'"duration" used locally through "play"
'"offset" used locally through "play"
'"note1","note2","noteS", and "noteSS" used through "play"


'%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
voices2:

gosub pot1runs
potslast = pot1use+pot2+pot3+pot4+pot5+pot6+pot7+pot8

duration =(300- ((abs(pot1-pot1use) * 20 +30)max 270))+(pot5*15)
'debug cr,dec pot1, tab,dec pot1use,tab,dec duration,tab,"************",tab
offset = pot1use
goto voicesselect

voices:
potslast = pot1+pot2+pot3+pot4+pot5+pot6+pot7+pot8
duration = pot5*30+30
if pot1use=pot1 then vcontinue
if pot1use>pot1 then vup

vdown:
stepperphase = stepperphase +1
goto vcontinue

vup:
stepperphase = stepperphase-1

vcontinue:
pot1use = pot1
offset=pot1


voicesselect:
noteS = 0

gosub getnote

'debug cr,dec pot2/9
branch pot2/9,[voice1,voice2,voice3]

voice1:
freqout speaker,duration,note1,note1+5
goto again


voice2:
freqout speaker,duration/2,note1,note1*3
freqout speaker,duration/2,note1,note1+5
goto again


voice3:
noteSS = notes+4
for scratch = 0 to 2
freqout speaker,duration/5,note1
freqout speaker,duration/5,note2
next
freqout speaker,duration/5,note1,note1+5
goto again



'###########################################################

slidekey:
gosub pot1runs
potslast = pot1use+pot2+pot3+pot4+pot5+pot6+pot7+pot8

duration =(300- ((abs(pot1-pot1use) * 20 +30)max 270))+(pot5*15)
'debug cr,dec pot1, tab,dec pot1use,tab,dec duration,tab,"************",tab



offset = pot1use
lookup pot7,[12,7,5],scratch2
noteS=0			'pot1
gosub getnote
freqout speaker,duration,note1,note1+5
noteS=(pot2/2)		'pot1 + pot2
gosub getnote
freqout speaker,duration,note1,note1+5

noteS=(pot3/2)		'pot1 + pot3
gosub getnote
freqout speaker,duration,note1,note1+5
goto again

'########################################################
'sliderruns;

'note distances double when "all keys" scale selected; runup and rundown

'"scratch" used locally in loops through "play"
	'keeps track of short up/down run distances

'"scratch2" used locally in loops through "play"
	'keeps track of position in scale/key

		'this is much reduced in range everywhere to make the
		'sliders have a more immediate effect when moved.
slideruns:
if pot1use>pot1 then sdecrpot1use
if pot1use=pot1 then spot1done

sincrpot1use:
pot1use=pot1use+3
goto spot1done

sdecrpot1use:
pot1use = pot1use -3
if pot1use<32000 then spot1done
pot1use = 0	'if pot1use rolls over negative, make zero

spot1done:
potslast = pot1use+pot2+pot3+pot4+pot5+pot6+pot7+pot8

scratch2=(pot3/2) - (pot2/2)	'start at X to give downward run somewhere to go
if scratch2<20 then slideoffset
scratch2=0
'debug cr,dec pot1, tab,dec pot1use,tab,dec duration,tab,"************",tab
slideoffset
offset = pot1use/2

sliderunsup:

for scratch = 0 to pot2/3

stepperphase = stepperphase+1
outc = dcd (stepperphase & 3)

duration =400-((abs(pot1-pot1use) * 40 +30)max 200)	'done in "sliderunsdown", too
if pot2>pot3 then sliderunnext1
duration = duration*2

sliderunnext1:
lookup scratch,[5,5,5,0,1,3,5,0,2,4,8],noteSS	'runup tune
noteSS=noteSS+scratch2
noteS=scratch2
'debug home,dec noteS,tab,dec noteSS,tab

if pot7<>7 then slidernotall	'double in "all"
noteS=noteS*2
noteSS=noteSS*2

slidernotall:
gosub getnote
gosub playnotes

scratch2=scratch2+1

'debug cr,dec scratch2,tab

next

noteSS = 0
sliderunsdown:

for scratch=0 to pot3/3

stepperphase = stepperphase-1
outc = dcd (stepperphase & 3)


duration =400-((abs(pot1-pot1use) * 40 +30)max 200)
if pot3>pot2 then sliderunnext2
duration=duration*2

sliderunnext2:

if (scratch2 + pot1use)=0 then sliderunsdone


scratch2 = (scratch2-1) 

slidenotneg:
noteS=scratch2

'debug cr,tab,tab,dec scratch2

if pot7 <> 7 then slidernotall2		'double in all
noteS=noteS*2

slidernotall2:
gosub getnote
freqout speaker,duration,note1,note1+5		'with envelope
next
sliderunsdone:
goto again



'}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}

'cycles;

'"scratch" used locally through "play"
'"scratch3" used in loops through "play"
'	keeps track of position within phrase

cycles:

if pot1use>pot1 then cdecrpot1use
if pot1use=pot1 then cpot1done

cincrpot1use:
pot1use=(pot1use+(pot3/2)+1)//45
stepperphase = stepperphase+1
goto cpot1done

cdecrpot1use:
pot1use = (pot1use-(pot3/2)-1)// 45
stepperphase = stepperphase-1

cpot1done:
potslast = pot1use+pot2+pot3+pot4+pot6+pot7+pot8
noteS=0
'debug cr, dec pot3/2+1,tab,dec pot1use,tab
'debug cr,dec pot1, tab,dec pot1use,tab,dec duration,tab,"************",tab

offset = pot1use
if pot7=7 then cpot1fullrange	'double in "all"
offset = offset/2

cpot1fullrange:
'debug cr,dec offset,tab


scratch = 0
gosub pot2phrasescratchnote	'lookup count to noteSS
				'how many notes in phrase -1
scratch3=noteSS			'how many notes in phrase -1
for scratch = 1 to scratch3+1
duration =400-((abs(pot1-pot1use) * 40 +30)max 200)

gosub pot2phrasescratchnote

'debug cr,dec noteS,tab,dec noteSS,tab,dec offset,tab
'debug cr,dec pot2/2,tab

if noteSS<>77 then cyclenotrest 	'code "77" makes a pause
pause duration
goto cyclenext

cyclenotrest:

gosub getnote
gosub playnotes
cyclenext:
next

goto again

'<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

'cycles2;

'doubles some distances when "all keys" scale selected

'"scratch" used to lookup in "play"

'"scratch2" used in loops through "again", do not corrupt
'	keeps track of position within slow phrase

'"scratch3" used in loops through "play"
'	keeps track of position within fast phrase

'"scratch4" used in loops through "again", do not corrupt
'	slow phrase note value


cycles2:
pot1use = pot1
potslast = 77+pot2+pot3+pot4+pot6+pot7+pot8	'always runs

'debug cr, dec pot3/2+1,tab,dec pot1use,tab
'debug cr,dec pot1, tab,dec pot1use,tab,dec duration,tab,"************",tab

noteS= scratch4+2	'new slow note played = value from last pass
offset = (pot1use+scratch4)/2
if pot7<>7 then cgood	'new offset based on 1/2 new slow note played 
cbumpall:
offset = (pot1use+scratch4)*/384	'unless all, then 1.5X new slow note
					'and use 1.5x full range of pot1
cgood:
'debug cr,dec offset,tab

scratch = 0
gosub pot3phrasescratchnote	'lookup # of notes-1 to noteSS
				'how many notes in sub phrase -1
scratch2 = (scratch2+1)//(noteSS+1)		'advance modulo # of notes
'debug home,dec scratch2,tab		
scratch = scratch2+1			'scratch2 has slow note counter
					'+1 to skip note-1 count entry
gosub pot3phrasescratchnote			'lookup to noteSS
'debug cr,dec noteS,tab,dec noteSS,tab,dec offset,tab
'debug cr,dec pot2/2,tab
'debug cr,dec noteSS,tab
scratch4 = noteSS				'scratch4 has new new slow note
						'value but noteS= old value

scratch = 0
gosub pot2phrasescratchnote		'lookup note-1 count to noteSS
scratch3=noteSS
					'how many notes in main phrase -1
for scratch = 1 to scratch3+1

gosub pot2phrasescratchnote	'lookup to noteSS
'debug cr,dec noteS,tab,dec noteSS,tab,dec offset,tab'!!!!!!!!!!!!!!!
'debug cr,dec pot2/2,tab

if noteS>3 then cgetnote	'reverse step if noteS < 4
stepperphase = stepperphase-1
outc = dcd (stepperphase & 3)

cgetnote:
gosub getnote
duration = 500

if pot7<>7 then cycle2play	'move note1 out of the way in "all"
note1 = note1/2
cycle2play:

gosub playnotes
ccyclenext:
next

stepperphase = stepperphase +1

goto again


'<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

'subroutines;

'&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&

lookupall:			'8 octaves 
'debug home,dec potscratch,tab
lookup potscratch,[65,69,73,77,82,87,92,97,103,110,117,124,   131,139,147,154,165,175,185,195,207,220,234,248,    262,278,294,307,329,350,370,391,414,439,467,495,   521,554,588,623,658,694,737,781,829,877,928,980,    1042,1102,1163,1240,1316,1389,1476,1563,1658,1754,1856,1960,    2048,2204,2326,2480,2632,2778,2952,3126,3316,3508,3712,3920,    4168,4408,4652,4960,5264,5556,5904,6252,6632,7016,7424,7840,   8336,8816,9304,9920,10528,11112,11808,12504,13264,14032,14848,15680],potscratch
'debug dec potscratch,tab
return

playnotes:
freqout speaker,duration,note1,note2
low speaker
return

'^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
'pot1runs; integrates offset pot (pot1) to make smooth run
 
pot1runs:
if pot1use>pot1 then decrpot1use
if pot1use=pot1 then pot1done

incrpot1use:
pot1use=pot1use+1
stepperphase = stepperphase+1
return

decrpot1use:
pot1use = pot1use -1
stepperphase = stepperphase-1
pot1done:
return

'++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'phrases;

	'1st entry is number of notes in phrase - 1

'----------------------------------------------------------
pot2phrasescratchnote:
'goto pot2black

'pot2all:
'branch pot2/2, [all0,all1,all2,all3,all4,all5,all6]

'pot2white:
'branch pot2/2, [wht0,wht1,wht2,wht3]

pot2black:
branch pot2/2, [c0,c1,c2,c3,c4,c5,c6,c7,c8,c9,c10]

'..................................................

pot3phrasescratchnote:
'branch pot7, [pot3all,pot3white,pot3black]

'pot3all:
'branch pot3/2, [all0,all1,all2,all3,all4,all5,all6]

'pot3white:
'branch pot3/2, [wht0,wht1,wht2,wht3]

pot3black:
branch pot3/2, [c0,c1,c2,c3,c4,c5,c6,c7,c8,c9,c10]

'-------------------------------------------------
c0:
lookup scratch,[5,	9,10,9,5,4,2],noteSS
return
'-------------------------------------------------
c1:
lookup scratch,[7,	4,3,4,5,4,3,2,1],noteSS
return
l'-------------------------------------------------
c2:
lookup scratch,[13,	5,5,6,6,5,3,1,3,3,5,5,3,1,0],noteSS
return
'-------------------------------------------------
c3:
lookup scratch,[11,	5,2,0,5,2,1,2,4,3,2,3,4],noteSS
return
'.................................................
c4:
lookup scratch,[3,	1,2,3,2],noteSS
return
'-------------------------------------------------
c5:
lookup scratch,[5,	0,1,2,3,2,1],noteSS
return
'-------------------------------------------------
c6:
lookup scratch,[5,	0,2,1,3,2,4],noteSS
return
'-------------------------------------------------
c7:
lookup scratch,[7,	0,1,2,3,1,2,2,3],noteSS
return
'-------------------------------------------------
c8:
lookup scratch,[7,	0,0,1,1,3,3,2,2],noteSS
return

'-------------------------------------------------
c9:
lookup scratch,[7,	0,3,2,3,4,3,2,3],noteSS
return

'-------------------------------------------------
c10:
lookup scratch,[7,	0,1,2,3,5,3,2,4],noteSS
return



'__________________________________________________________________________

']]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]

getnote:

'get scale modulus;

'debug home,dec noteSS,tab,dec offset,tab,dec pot4,tab

potscratch = 0		'setup to get 0th entry from "lookupscale"
gosub lookupscale	'returns with modulus in potscratch
modulus = potscratch

'get scale note;

potscratch = ((noteS + offset)//modulus)+1 'potscratch = note# in octave 0
					   '+1 to miss modulus entry
'debug cr,dec potscratch , tab

gosub lookupscale	'returns with note# in scale @0 in potscratch

'debug dec potscratch,tab

potscratch = potscratch + ((((noteS+offset)/modulus)+pot4-2)*12)+ pot8

'debug dec potscratch,tab

'"noteS+offset" = note position in many octaves of chosen scale
'"/modulus" = number of octaves up in chosen scale that "noteS+offset" is  
'"+pot4" adds that many octaves from octave control: pot4
'"-2" makes the octave control + and -   ...rolls into 65536 at low end
'"*12" multiplies all this into an octave offset in a scale of all notes
'"+pot8" adds 0-12 to put the scale into the chosen key: pot8
'and the initial "potscratch+" adds in the chosen note in the chosen scale

gosub lookupall		'returns with note from full keyboard in "potscratch"
note1 = potscratch

'debug dec potscratch,tab
potscratch = ((noteSS + offset)//modulus)+1 'potscratch = note# in octave 0
					   '+1 to miss modulus entry

gosub lookupscale	'returns with note# in scale @0 in potscratch
potscratch = potscratch + ((((noteSS+offset)/modulus)+pot4-2)*12)+ pot8
'"noteSS+offset" = note position in many octaves of chosen scale
'"/modulus" = number of octaves up in chosen scale that "noteS+offset" is  
'"+pot4" adds that many octaves from octave control: pot4
'"-2" makes the octave control + and -
'"*12" multiplies all this into an octave offset in a scale of all notes
'"+pot8" adds 0-12 to put the scale into the chosen key: pot8
'and the initial "potscratch+" adds in the chosen note in the chosen scale

gosub lookupall		'returns with note from full keyboard in "potscratch"
note2 = potscratch

return

'...........................................

lookupscale:
branch pot7,[blkpent,whtpent,majortriad,minortriad,diminished,minor,major,all,blkpent]
'returns from scale lookup with modulus (potscratch = 0) or note in potscratch

'............................................

'scales;

blkpent:
lookup potscratch,[5,	1,3,6,8,10],potscratch
return

whtpent:
lookup potscratch,[5,	0,4,5,9,11],potscratch
return

majortriad:
lookup potscratch,[3,	0,4,7],potscratch
return

minortriad:
lookup potscratch,[4,	0,3,7,10],potscratch
return

diminished:
lookup potscratch,[4,	0,3,6,9],potscratch
return

'wholetone:
'lookup potscratch,[6,	0,2,4,6,8,10],potscratch
'return

'blues:
'lookup potscratch,[6,	0,3,5,7,9,10],potscratch
'return

minor:
lookup potscratch,[7,	0,2,3,5,7,8,11],potscratch
return

major:
lookup potscratch,[7,	0,2,4,5,7,9,11],potscratch
return

all:
lookup potscratch,[12,	0,1,2,3,4,5,6,7,8,9,10,11],potscratch
return


'__________________________________________________________________________
