
Skip to content
This repository

    Pull requests
    Issues
    Gist

    @rithma

1
0

    0

rithma/brainEraser
Code
Issues 0
Pull requests 0
Projects 0
Wiki
Pulse
Graphs
Settings
brainEraser/Music5_TST.bsx
c564b5b a minute ago
@rithma rithma Create Music5_TST.bsx
691 lines (503 sloc) 16.9 KB
' {$STAMP BS2sx}
'music5: music box that went to Henze

'potentiometer#  port#  values
potIO1  CON  0  ' 10k, 0.047uF
potIO2  CON  1  ' 500k, 0.0033uF
potIO3  CON  8  ' 500k, 0.0033uF  '2 was dead in an avail part
potIO4  CON  3  ' 10k, 0.047uf
potIO5  CON  4  ' 10k, 0.047uF
potIO6  CON  5  ' 500k, 0.0033uF
potIO7  CON  6  ' 10k, 0.047uF
potIO8  CON  7  ' 25k, 0.022uF

speaker  CON  12  ' through 150 Ohm resistor to 4 Ohm speaker to ground
      '   The speaker supplies all of the voicing -so-
      '  31/2" full-range with good magnet + enclosure
      '  good to very highs (bells).

'variable    scale  range  function

pot1scale  CON  21  '0-30  note/phrase offset in key+scale
pot2scale  CON  105  '0-20  select function within gizmo
pot3scale  CON  116  '0-20  select function within gizmo
pot4scale  CON  129  '0-5  octave
pot5scale  CON  31  '0-20  duration/rate
pot6scale  CON  401  '0-5  gizmo
pot7scale  CON  75  '0-7  scale type select
pot8scale  CON  55  '0-12  key


'pot7 scales;

'value  scale

'0  minor pent
'1  major pent
'2  major triad
'3  minor triad with optional 7th
'4  diminished
'5  minor
'6  major
'7  12 note octave (all)


potscratch  VAR  Word
pot1    VAR  Byte
pot2    VAR  Byte
pot3    VAR  Byte
pot4    VAR  Byte
pot5    VAR  Byte
pot6    VAR  Byte
pot7    VAR  Byte
pot8    VAR  Byte
potslast  VAR  Byte  'checksum to detect movement of any control
pot1use    VAR  Byte  'interpolating/integrating value of pot1

noteS  VAR  Byte    'note in scale+key
noteSS  VAR  Byte    'another note in scale+key

note1  VAR  Word    'note in frequency in Hz
note2  VAR  Word    'another note in frequency in Hz

duration VAR  Word  'duration of "noteS" (looked-up into "note1")
      '  and "noteSS" (looked-up into "note2")
      ' or of any output tones

offset  VAR   Byte  'offset within scale+key

modulus VAR  Nib  'number of notes in chosen scale
      '  used local in "getnote"
      '  not used in loops through again
      '  nor in for-next loops

scratch VAR Byte
scratch2 VAR Byte
scratch3 VAR Byte  'position within phrase: could be NIBble if 16 max
scratch4 VAR Byte

duration = 200

'figure-out which way to go at reset;
HIGH potIO1
PAUSE 30
RCTIME potIO1,1,potscratch
IF potscratch/pot1scale>14 THEN sweepupatstart
pot1use = 30  'sweep down at start
sweepupatstart:

'###################################################
again:
'read pots and sliders;

'"potscratch" used local

'uncommentout (remove "'"s) the following debugs to display pots;
'recommentout when done
'VERY IMPORTANT to recommentout everything when done (debug makes pause)

RCTIME  potIO1,1,potscratch  'has "home" screen command for other debugs
HIGH  potIO1
DEBUG HOME,"pot1",TAB,DEC potscratch, TAB, DEC pot1scale,TAB
pot1 = (potscratch/pot1scale)MAX 30
DEBUG CR, DEC pot1,TAB

RCTIME  potIO2,1,potscratch
DEBUG CR,"pot2",TAB,DEC potscratch, TAB, DEC pot2scale,TAB
HIGH  potIO2
pot2 = (potscratch/pot2scale)MAX 20
DEBUG CR, DEC pot2,TAB

RCTIME  potIO3,1,potscratch
DEBUG CR,"pot3",TAB,DEC potscratch, TAB, DEC pot3scale,TAB
HIGH  potIO3
pot3 = (potscratch/pot3scale)MAX 20
debug CR, DEC pot3,TAB

RCTIME  potIO4,1,potscratch
debug CR,"pot4",TAB,DEC potscratch, TAB, DEC pot4scale,TAB
HIGH  potIO4
pot4 = (potscratch/pot4scale)MAX 5
debug CR, DEC pot4,TAB

RCTIME  potIO5,1,potscratch
debug CR,"pot5",TAB,DEC potscratch, TAB, DEC pot5scale,TAB
HIGH  potIO5
pot5 = (potscratch/pot5scale)MAX 20
debug CR, DEC pot5,TAB


RCTIME  potIO6,1,potscratch
debug CR,"pot6",TAB,DEC potscratch, TAB, DEC pot6scale,TAB
HIGH  potIO6
pot6 = (potscratch/pot6scale)MAX 5
debug CR, DEC pot6,TAB

RCTIME  potIO7,1,potscratch
debug CR,"pot7",TAB,DEC potscratch, TAB, DEC pot7scale,TAB
HIGH  potIO7
pot7 = (potscratch/pot7scale)MAX 8
debug CR, DEC pot7,TAB

RCTIME  potIO8,1,potscratch
debug CR,"pot8",TAB,DEC potscratch, TAB, DEC pot8scale,TAB
HIGH  potIO8
pot8 = (potscratch/pot8scale)MAX 12
debug CR, DEC pot8,TAB


'.....................................................................

'"potslast" used in loops through "again"; do not corrupt

IF pot1+pot2+pot3+pot4+pot5+pot6+pot7+pot8 = potslast  THEN again

BRANCH pot6,[voices,voices2,slidekey,slideruns,cycles,cycles2]


'{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{

'gizmos;

'"potslast" used in loops through "again"; do not corrupt unless non-stop
'"pot1use" used in loops through "again"; do not corrupt
'"duration" used locally through "play"
'"offset" used locally through "play"
'"note1","note2","noteS", and "noteSS" used through "play"


'%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
voices2:

GOSUB pot1runs
potslast = pot1use+pot2+pot3+pot4+pot5+pot6+pot7+pot8

duration =(300- ((ABS(pot1-pot1use) * 20 +30)MAX 270))+(pot5*15)
'debug cr,dec pot1, tab,dec pot1use,tab,dec duration,tab,"************",tab
offset = pot1use
GOTO voicesselect

voices:
potslast = pot1+pot2+pot3+pot4+pot5+pot6+pot7+pot8
duration = pot5*30+30

offset=pot1

voicesselect:
noteS = 0

GOSUB getnote

'debug cr,dec pot2/9
BRANCH pot2/9,[voice1,voice2,voice3]

voice1:
FREQOUT speaker,duration,note1,note1+5
GOTO again


voice2:
FREQOUT speaker,duration/2,note1,note1*3
FREQOUT speaker,duration/2,note1,note1+5
GOTO again


voice3:
noteSS = notes+4
FOR scratch = 0 TO 2
FREQOUT speaker,duration/5,note1
FREQOUT speaker,duration/5,note2
NEXT
FREQOUT speaker,duration/5,note1,note1+5
GOTO again



'###########################################################

slidekey:
GOSUB pot1runs
potslast = pot1use+pot2+pot3+pot4+pot5+pot6+pot7+pot8

duration =(300- ((ABS(pot1-pot1use) * 20 +30)MAX 270))+(pot5*15)
'debug cr,dec pot1, tab,dec pot1use,tab,dec duration,tab,"************",tab



offset = pot1use
lookup pot7,[12,7,5],scratch2
noteS=0      'pot1
gosub getnote
freqout speaker,duration,note1,note1+5
noteS=(pot2/2)    'pot1 + pot2
gosub getnote
freqout speaker,duration,note1,note1+5

noteS=(pot3/2)    'pot1 + pot3
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
pot1use = 0  'if pot1use rolls over negative, make zero

spot1done:
potslast = pot1use+pot2+pot3+pot4+pot5+pot6+pot7+pot8

scratch2=(pot3/2) - (pot2/2)  'start at X to give downward run somewhere to go
if scratch2<20 then slideoffset
scratch2=0
'debug cr,dec pot1, tab,dec pot1use,tab,dec duration,tab,"************",tab
slideoffset
offset = pot1use/2

sliderunsup:

for scratch = 0 to pot2/3
duration =400-((abs(pot1-pot1use) * 40 +30)max 200)  'done in "sliderunsdown", too
if pot2>pot3 then sliderunnext1
duration = duration*2

sliderunnext1:
lookup scratch,[5,5,4,3,5,6,2,0,2,7,5,3,2,5,0],noteSS  'runup tune
noteSS=noteSS+scratch2
noteS=scratch2
'debug home,dec noteS,tab,dec noteSS,tab

if pot7<>7 then slidernotall  'double in "all"
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

duration =400-((abs(pot1-pot1use) * 40 +30)max 200)
if pot3>pot2 then sliderunnext2
duration=duration*2

sliderunnext2:

if (scratch2 + pot1use)=0 then sliderunsdone


scratch2 = (scratch2-1)

slidenotneg:
noteS=scratch2

'debug cr,tab,tab,dec scratch2

if pot7 <> 7 then slidernotall2    'double in all
noteS=noteS*2

slidernotall2:
gosub getnote
freqout speaker,duration,note1,note1+5    'with envelope
next
sliderunsdone:
goto again



'}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}

'cycles;

'"scratch" used locally through "play"
'"scratch3" used in loops through "play"
'  keeps track of position within phrase

cycles:

if pot1use>pot1 then cdecrpot1use
if pot1use=pot1 then cpot1done

cincrpot1use:
pot1use=(pot1use+(pot3/2)+1)//45
goto cpot1done

cdecrpot1use:
pot1use = (pot1use-(pot3/2)-1)// 45

cpot1done:
potslast = pot1use+pot2+pot3+pot4+pot6+pot7+pot8
noteS=0
'debug cr, dec pot3/2+1,tab,dec pot1use,tab
'debug cr,dec pot1, tab,dec pot1use,tab,dec duration,tab,"************",tab

offset = pot1use
if pot7=7 then cpot1fullrange  'double in "all"
offset = offset/2

cpot1fullrange:
'debug cr,dec offset,tab


scratch = 0
gosub pot2phrasescratchnote  'lookup count to noteSS
        'how many notes in phrase -1
scratch3=noteSS      'how many notes in phrase -1
for scratch = 1 to scratch3+1
duration =400-((abs(pot1-pot1use) * 40 +30)max 200)

gosub pot2phrasescratchnote

'debug cr,dec noteS,tab,dec noteSS,tab,dec offset,tab
'debug cr,dec pot2/2,tab

if noteSS<>77 then cyclenotrest   'code "77" makes a pause
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
'  keeps track of position within slow phrase

'"scratch3" used in loops through "play"
'  keeps track of position within fast phrase

'"scratch4" used in loops through "again", do not corrupt
'  slow phrase note value


cycles2:
pot1use = pot1
potslast = 77+pot2+pot3+pot4+pot6+pot7+pot8  'always runs

'debug cr, dec pot3/2+1,tab,dec pot1use,tab
'debug cr,dec pot1, tab,dec pot1use,tab,dec duration,tab,"************",tab

noteS= scratch4+2  'new slow note played = value from last pass
offset = (pot1use+scratch4)/2
if pot7<>7 then cgood  'new offset based on 1/2 new slow note played
cbumpall:
offset = (pot1use+scratch4)*/384  'unless all, then 1.5X new slow note
          'and use 1.5x full range of pot1
cgood:
'debug cr,dec offset,tab

scratch = 0
gosub pot3phrasescratchnote  'lookup # of notes-1 to noteSS
        'how many notes in sub phrase -1
scratch2 = (scratch2+1)//(noteSS+1)    'advance modulo # of notes
'debug home,dec scratch2,tab
scratch = scratch2+1      'scratch2 has slow note counter
          '+1 to skip note-1 count entry
gosub pot3phrasescratchnote      'lookup to noteSS
'debug cr,dec noteS,tab,dec noteSS,tab,dec offset,tab
'debug cr,dec pot2/2,tab
'debug cr,dec noteSS,tab
scratch4 = noteSS        'scratch4 has new new slow note
            'value but noteS= old value

scratch = 0
gosub pot2phrasescratchnote    'lookup note-1 count to noteSS
scratch3=noteSS
          'how many notes in main phrase -1
for scratch = 1 to scratch3+1

gosub pot2phrasescratchnote  'lookup to noteSS
'debug cr,dec noteS,tab,dec noteSS,tab,dec offset,tab
'debug cr,dec pot2/2,tab
gosub getnote
duration = 500

if pot7<>7 then cycle2play  'move note1 out of the way in "all"
note1 = note1/2
cycle2play:

gosub playnotes
ccyclenext:
next

goto again


'<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

'subroutines;

'&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&

lookupall:      '8 octaves
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
return

decrpot1use:
pot1use = pot1use -1
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
lookup scratch,[5,  9,10,9,5,4,2],noteSS
return
'-------------------------------------------------
c1:
lookup scratch,[7,  4,3,4,5,4,3,2,1],noteSS
return
l'-------------------------------------------------
c2:
lookup scratch,[13,  5,5,6,6,5,3,1,3,3,5,5,3,1,0],noteSS
return
'-------------------------------------------------
c3:
lookup scratch,[11,  5,2,0,5,2,1,2,4,3,2,3,4],noteSS
return
'.................................................
c4:
lookup scratch,[3,  1,2,3,2],noteSS
return
'-------------------------------------------------
c5:
lookup scratch,[5,  0,1,2,3,2,1],noteSS
return
'-------------------------------------------------
c6:
lookup scratch,[5,  0,2,1,3,2,4],noteSS
return
'-------------------------------------------------
c7:
lookup scratch,[7,  0,1,2,3,1,2,2,3],noteSS
return
'-------------------------------------------------
c8:
lookup scratch,[7,  0,0,1,1,3,3,2,2],noteSS
return

'-------------------------------------------------
c9:
lookup scratch,[7,  0,3,2,3,4,3,2,3],noteSS
return

'-------------------------------------------------
c10:
lookup scratch,[7,  0,1,2,3,5,3,2,4],noteSS
return



'__________________________________________________________________________

']]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]

getnote:

'get scale modulus;

'debug home,dec noteSS,tab,dec offset,tab,dec pot4,tab

potscratch = 0    'setup to get 0th entry from "lookupscale"
gosub lookupscale  'returns with modulus in potscratch
modulus = potscratch

'get scale note;

potscratch = ((noteS + offset)//modulus)+1 'potscratch = note# in octave 0
             '+1 to miss modulus entry
'debug cr,dec potscratch , tab

gosub lookupscale  'returns with note# in scale @0 in potscratch

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

gosub lookupall    'returns with note from full keyboard in "potscratch"
note1 = potscratch

'debug dec potscratch,tab
potscratch = ((noteSS + offset)//modulus)+1 'potscratch = note# in octave 0
             '+1 to miss modulus entry

gosub lookupscale  'returns with note# in scale @0 in potscratch
potscratch = potscratch + ((((noteSS+offset)/modulus)+pot4-2)*12)+ pot8
'"noteSS+offset" = note position in many octaves of chosen scale
'"/modulus" = number of octaves up in chosen scale that "noteS+offset" is
'"+pot4" adds that many octaves from octave control: pot4
'"-2" makes the octave control + and -
'"*12" multiplies all this into an octave offset in a scale of all notes
'"+pot8" adds 0-12 to put the scale into the chosen key: pot8
'and the initial "potscratch+" adds in the chosen note in the chosen scale

gosub lookupall    'returns with note from full keyboard in "potscratch"
note2 = potscratch

return

'...........................................

lookupscale:
branch pot7,[blkpent,whtpent,majortriad,minortriad,diminished,minor,major,all,blkpent]
'returns from scale lookup with modulus (potscratch = 0) or note in potscratch

'............................................

'scales;

blkpent:
lookup potscratch,[5,  1,3,6,8,10],potscratch
return

whtpent:
lookup potscratch,[5,  0,4,5,9,11],potscratch
return

majortriad:
lookup potscratch,[3,  0,4,7],potscratch
return

minortriad:
lookup potscratch,[4,  0,3,7,10],potscratch
return

diminished:
lookup potscratch,[4,  0,3,6,9],potscratch
return

'wholetone:
'lookup potscratch,[6,  0,2,4,6,8,10],potscratch
'return

'blues:
'lookup potscratch,[6,  0,3,5,7,9,10],potscratch
'return

minor:
lookup potscratch,[7,  0,2,3,5,7,8,11],potscratch
return

major:
lookup potscratch,[7,  0,2,4,5,7,9,11],potscratch
return

all:
lookup potscratch,[12,  0,1,2,3,4,5,6,7,8,9,10,11],potscratch
return


'__________________________________________________________________________

    Contact GitHub API Training Shop Blog About 

    © 2017 GitHub, Inc. Terms Privacy Security Status Help 

